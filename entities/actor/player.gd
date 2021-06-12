extends Actor

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const COYOTE_TIME = 0.1
const WALL_IMPULSE = 3000
const WALL_FRICTION = 0.1

onready var FLOOR_DETECT_DISTANCE = $PlatformDetector.cast_to.y

onready var platform_detector = $PlatformDetector
onready var animation_player = $AnimationPlayer
onready var sprite = $SpriteContainer/Sprite
onready var bounce_detector = $BounceDetector
onready var left_wall_cast = $LeftWallCast
onready var right_wall_cast = $RightWallCast

var queue_jump = false
var is_jumping = false
var just_wall_jumped 
var airborne: float = 0.0

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

func _wall_touched():
	if left_wall_cast.is_colliding():
		return Wall.LEFT
	elif right_wall_cast.is_colliding(): 
		return Wall.RIGHT
	else:
		return Wall.NONE

func _is_touching_wall():
	var wall_touched = _wall_touched()
	return wall_touched == Wall.RIGHT || wall_touched == Wall.LEFT
	
func _physics_process(_delta):
	var input_direction: float = get_direction()
	var wall_jumped_off = Wall.NONE
	gravity = default_gravity

	if is_on_floor():
		airborne = 0
		is_jumping = false
	else:
		airborne += _delta
	
	if bounce_detector.is_colliding() and Input.is_action_just_pressed("jump"):
		queue_jump = true
	
	if can_jump():
		if Input.is_action_pressed("jump"):
			if _wall_touched() != Wall.NONE && Input.is_action_just_pressed("jump):
				wall_jumped_off = _wall_touched()
			_velocity.y = -speed.y
			
			is_jumping = true
			queue_jump = false
			Input.action_press("jump")

	var is_jump_interrupted = is_jumping and Input.is_action_just_released("jump") and _velocity.y < 0.0
	_velocity = calculate_move_velocity(_velocity, input_direction, speed, is_jump_interrupted, wall_jumped_off)
	print(_velocity)
	
	# Slightly raise the slime when jumping so that it can jump on rising platform
	if _velocity.y < 0:
		position.y -= 0.5
		
	# Add friction when sliding down a wall
	if _is_touching_wall() && _velocity.y > 0:
		print("APPLY FRICTION")
		gravity *= WALL_FRICTION

	var snap_vector = Vector2.ZERO
	if not (Input.is_action_just_pressed("jump") or queue_jump):
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not platform_detector.is_colliding(), 4, 0.9, false
	)

	# When the character’s direction changes, we want to to scale the Sprite accordingly to flip it.
	# This will make Robi face left or right depending on the direction you move.
	if input_direction != 0:
		if input_direction > 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true

	var animation = get_new_animation()
	if animation != animation_player.current_animation:
		animation_player.play(animation)


func can_jump():
	return is_on_floor() or (airborne < COYOTE_TIME and not is_jumping) or _is_touching_wall()

func calculate_move_velocity(
		linear_velocity: Vector2,
		direction,
		speed,
		is_jump_interrupted,
		wall_jumped_off
	) -> Vector2:
	var velocity = linear_velocity
	if wall_jumped_off != Wall.NONE:
		velocity.x = wall_jumped_off * -WALL_IMPULSE
	else: 
		velocity.x = speed.x * direction
	if is_jump_interrupted:
		# Decrease the Y velocity by multiplying it, but don't set it to 0
		# as to not be too abrupt.
		velocity.y *= 0.6
	return velocity


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
