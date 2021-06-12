class_name Actor
extends KinematicBody2D

# Both the Player and Enemy inherit this scene as they have shared behaviours
# such as speed and are affected by gravity.


export var speed = Vector2(300.0, 700.0)
onready var default_gravity = ProjectSettings.get("physics/2d/default_gravity")
onready var gravity = default_gravity

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO

# _physics_process is called after the inherited _physics_process function.
# This allows the Player and Enemy scenes to be affected by gravity.
func _physics_process(delta):
	apply_gravity(delta)

func apply_gravity(delta):
	_velocity.y += gravity * delta
