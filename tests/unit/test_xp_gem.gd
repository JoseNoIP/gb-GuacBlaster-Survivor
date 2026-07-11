extends GutTest
## Tests for XPGem: collection, signals, magnet activation.

const XPGemGd := preload("res://src/features/gems/XPGem.gd")

var _gem: XPGem

func before_each() -> void:
	XPGem.magnet_active = false
	_gem = XPGemGd.new()
	add_child_autofree(_gem)

func test_default_xp_value() -> void:
	assert_eq(_gem.xp_value, 5)

func test_collect_emits_gem_collected() -> void:
	watch_signals(EventBus)
	_gem.collect()
	assert_signal_emitted(EventBus, "gem_collected")

func test_collect_emits_correct_xp_value() -> void:
	_gem.xp_value = 20
	watch_signals(EventBus)
	_gem.collect()
	assert_signal_emitted_with_parameters(EventBus, "gem_collected", [20])

func test_collect_only_triggers_once() -> void:
	_gem.collect()
	watch_signals(EventBus)
	_gem.collect()
	assert_signal_not_emitted(EventBus, "gem_collected")

func test_magnet_not_active_by_default() -> void:
	assert_false(XPGem.magnet_active)

func test_salsa_magnet_activates_magnet() -> void:
	EventBus.powerup_selected.emit(&"salsa_magnet")
	assert_true(XPGem.magnet_active)

func test_other_powerup_does_not_activate_magnet() -> void:
	EventBus.powerup_selected.emit(&"rapid_fire")
	assert_false(XPGem.magnet_active)
