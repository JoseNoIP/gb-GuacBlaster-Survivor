extends GutTest
## Unit tests for Projectile setup, burst flag, and movement direction.

var _proj: Projectile

func before_each() -> void:
	_proj = Projectile.new()
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	_proj.add_child(shape)
	add_child_autofree(_proj)

# --- Setup ---

func test_default_damage_is_base_constant() -> void:
	assert_eq(_proj.get_damage(), Constants.PLAYER_BASE_DAMAGE)

func test_setup_sets_damage() -> void:
	_proj.setup(25.0, Vector2.UP)
	assert_eq(_proj.get_damage(), 25.0)

func test_setup_burst_is_false_by_default() -> void:
	_proj.setup(10.0, Vector2.UP)
	assert_false(_proj.get_burst())

func test_setup_sets_burst_true() -> void:
	_proj.setup(10.0, Vector2.UP, true)
	assert_true(_proj.get_burst())

func test_setup_burst_false_explicit() -> void:
	_proj.setup(10.0, Vector2.UP, false)
	assert_false(_proj.get_burst())

# --- Screen exit ---

func test_screen_exited_marks_for_deletion() -> void:
	_proj._on_screen_exited()
	assert_true(_proj.is_queued_for_deletion())
