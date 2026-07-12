extends GutTest
## Unit tests for HUD — hearts, XP bar, score, level label, and power-up strip.

const HUDGd := preload("res://src/features/ui/HUD.gd")

var _hud: HUD

func before_each() -> void:
	_hud = HUD.new()
	add_child_autofree(_hud)

# --- Active power-up strip ---

func test_strip_shows_pill_on_stack_added() -> void:
	EventBus.powerup_stack_changed.emit(&"rapid_fire", 1)
	assert_true(_hud._strip_pills.has(&"rapid_fire"))

func test_strip_pill_text_shows_abbrev_and_count() -> void:
	EventBus.powerup_stack_changed.emit(&"triple_shot", 2)
	var pill: Label = _hud._strip_pills.get(&"triple_shot") as Label
	assert_eq(pill.text, "TS×2")

func test_strip_removes_pill_when_count_zero() -> void:
	EventBus.powerup_stack_changed.emit(&"rapid_fire", 1)
	EventBus.powerup_stack_changed.emit(&"rapid_fire", 0)
	assert_false(_hud._strip_pills.has(&"rapid_fire"))

func test_strip_clears_on_game_started() -> void:
	EventBus.powerup_stack_changed.emit(&"rapid_fire", 1)
	EventBus.game_started.emit()
	assert_true(_hud._strip_pills.is_empty())

# --- XP bar ---

func test_xp_bar_value_updates_on_xp_collected() -> void:
	EventBus.xp_collected.emit(5, 30, 100)
	assert_eq(_hud._xp_bar.value, 30.0)

func test_xp_bar_max_updates_on_xp_collected() -> void:
	EventBus.xp_collected.emit(5, 30, 150)
	assert_eq(_hud._xp_bar.max_value, 150.0)

func test_xp_bar_resets_on_level_up() -> void:
	EventBus.xp_collected.emit(5, 50, 100)
	EventBus.player_level_up.emit(1)
	assert_eq(_hud._xp_bar.value, 0.0)

# --- Score ---

func test_score_accumulates_xp_amounts() -> void:
	EventBus.xp_collected.emit(5, 5, 100)
	EventBus.xp_collected.emit(20, 25, 100)
	assert_eq(_hud._score_label.text, "25")

func test_score_resets_on_game_started() -> void:
	EventBus.xp_collected.emit(50, 50, 100)
	EventBus.game_started.emit()
	assert_eq(_hud._score_label.text, "0")

# --- Level label ---

func test_level_label_updates_on_level_up() -> void:
	EventBus.player_level_up.emit(3)
	assert_eq(_hud._level_label.text, "Lvl 3")

# --- Boss HP bar ---

func test_boss_hp_bar_hidden_initially() -> void:
	assert_false(_hud._boss_hp_bar.visible)

func test_boss_hp_bar_shows_on_health_changed() -> void:
	EventBus.boss_health_changed.emit(80, 100)
	assert_true(_hud._boss_hp_bar.visible)

func test_boss_hp_bar_value_updated() -> void:
	EventBus.boss_health_changed.emit(60, 100)
	assert_eq(_hud._boss_hp_bar.value, 60.0)

func test_boss_hp_bar_max_updated() -> void:
	EventBus.boss_health_changed.emit(50, 150)
	assert_eq(_hud._boss_hp_bar.max_value, 150.0)

func test_boss_hp_bar_hides_on_boss_defeated() -> void:
	EventBus.boss_health_changed.emit(50, 100)
	EventBus.boss_defeated.emit(1)
	assert_false(_hud._boss_hp_bar.visible)

func test_boss_hp_bar_hides_on_game_started() -> void:
	EventBus.boss_health_changed.emit(50, 100)
	EventBus.game_started.emit()
	assert_false(_hud._boss_hp_bar.visible)
