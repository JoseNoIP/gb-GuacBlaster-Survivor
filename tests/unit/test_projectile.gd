extends GutTest
## Unit tests for Projectile setup, pierce logic, and movement direction.

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

func test_setup_sets_pierce_zero_by_default() -> void:
	_proj.setup(10.0, Vector2.UP)
	assert_eq(_proj.get_pierce_remaining(), 0)

func test_setup_sets_pierce_count() -> void:
	_proj.setup(10.0, Vector2.UP, Constants.SUPER_GUAC_PENETRATION)
	assert_eq(_proj.get_pierce_remaining(), Constants.SUPER_GUAC_PENETRATION)

# --- Pierce consumption ---

func test_consume_pierce_frees_when_zero() -> void:
	_proj.setup(10.0, Vector2.UP, 0)
	# queue_free is called; after yield the node should be freed
	assert_false(_proj.is_queued_for_deletion(), "not freed before consume")
	_proj._consume_pierce()
	assert_true(_proj.is_queued_for_deletion(), "freed after pierce=0")

func test_consume_pierce_decrements_when_positive() -> void:
	_proj.setup(10.0, Vector2.UP, 2)
	_proj._consume_pierce()
	assert_eq(_proj.get_pierce_remaining(), 1)
	assert_false(_proj.is_queued_for_deletion(), "should NOT be freed yet")

func test_consume_pierce_frees_after_exhaustion() -> void:
	_proj.setup(10.0, Vector2.UP, 1)
	_proj._consume_pierce()  # pierce goes to 0, NOT freed (0 means still alive)
	_proj._consume_pierce()  # now pierce <= 0, freed
	assert_true(_proj.is_queued_for_deletion())

# --- Screen exit ---

func test_screen_exited_marks_for_deletion() -> void:
	_proj._on_screen_exited()
	assert_true(_proj.is_queued_for_deletion())
