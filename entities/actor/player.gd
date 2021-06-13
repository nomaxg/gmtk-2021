extends Actor

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const COYOTE_TIME = 0.1
const MIN_WALL_STICK_TIME = 0.1
const WALL_IMPULSE = 3000
const MAX_SLIDE_VELOCITY = 100

export(Vector2) var wall_climb
export(Vector2) var wall_pop
export(Vector2) var wall_leap

onready var platform_detector: RayCast2D = $PlatformDetector
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var sprite: Sprite = $SpriteContainer/Sprite
onready var bounce_detector: RayCast2D = $BounceDetector
onready var left_wall_cast: RayCast2D = $LeftWallCast
onready var right_wall_cast: RayCast2D = $RightWallCast

onready var FLOOR_DETECT_DISTANCE = platform_detector.cast_to.y

var jump_queued = false
var is_jumping = false
var wall_sliding = false
var just_wall_jumped = false
var airborne: float = 0.0
var wall_stick_time: float = 0.0

enum Wall {
	NONE = 0
	RIGHT = 1,
	LEFT = -1,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func wall_touched() -> int:			
	if left_wall_cast.is_colliding():
		return Wall.LEFT
	elif right_wall_cast.is_colliding():
		return Wall.RIGHT
	else:
		return Wall.NONE


func _physics_process(_delta):
	var input_direction: float = get_direction()
	update_hoizontal_velocity(input_direction)
	do_wall_slide(_delta)
	do_jump(_delta)
#
#
	var snap_vector = Vector2.ZERO
	if not (Input.is_action_just_pressed("jump") or jump_queued):
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not platform_detector.is_colliding(), 4, 0.9, false
	)
#
	if input_direction != 0:
		if input_direction > 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
#
	var animation = get_new_animation()
	if animation != animation_player.current_animation:
		animation_player.play(animation)


func do_jump(delta):
	if Input.is_action_just_pressed("jump"):
		handle_jump_pressed()
	elif Input.is_action_just_released("jump"):
		handle_jump_released()

	if not is_on_floor():
		airborne += delta
		return

	airborne = 0
	is_jumping = false
	if jump_queued:
		is_jumping = true
		jump_queued = false
		if _velocity.y < 0:
			position.y -= 1
		_velocity.y = -speed.y


func is_moving_into_wall() -> bool:
	return wall_touched() and sign(get_direction()) == wall_touched()


func get_walljump_type() -> Vector2:
	if is_moving_into_wall():
		return wall_climb
	#elif is_zero_approx(get_direction()):
	#	return wall_pop
	else:
		return wall_leap


func do_wall_slide(delta: float):
	wall_sliding = wall_touched() and !is_on_floor()
	if wall_sliding:
		_velocity.y = min(_velocity.y, MAX_SLIDE_VELOCITY)

		if wall_stick_time < MIN_WALL_STICK_TIME:
			_velocity.x = 0

			if !is_moving_into_wall():
				wall_stick_time += delta
			else:
				wall_stick_time = 0
		else:
			wall_stick_time = 0


func handle_jump_pressed():
	if wall_sliding:
		_velocity = -Vector2(wall_touched(), 1) * get_walljump_type()
		is_jumping = true
	elif can_jump():
		jump_queued = true


func handle_jump_released():
	if is_jumping and _velocity.y < 0:
		_velocity.y = _velocity.y * .6


func can_jump():
	return is_on_floor() or (airborne < COYOTE_TIME and not is_jumping)

#func calculate_move_velocity(
#		linear_velocity: Vector2,
#		direction,
#		speed,
#		is_jump_interrupted,
#		wall_jumped_off
#	) -> Vector2:
#	var velocity = linear_velocity
#	if wall_jumped_off != Wall.NONE:
#		velocity.x = wall_jumped_off * -WALL_IMPULSE
#	else:
#		velocity.x = speed.x * direction
#	if is_jump_interrupted:
#		# Decrease the Y velocity by multiplying it, but don't set it to 0
#		# as to not be too abrupt.
#		velocity.y *= 0.6
#	return velocity

func update_hoizontal_velocity(direction):
	_velocity.x = direction * speed.x


func get_direction() -> float:
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
#	return Vector2(
#		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
#		-1 if is_on_floor() and Input.is_action_just_pressed("jump") else 0
#	)

func get_new_animation() -> String:
	var animation_new = ""
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			animation_new = "walk"
		else:
			animation_new = "idle"
	else:
		if _velocity.y > 0:
			animation_new = "falling"
		else:
			animation_new = "jumping"
	return animation_new
