extends Area2D


signal camera_zone_enter(position, scale)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_CameraZone_body_entered(body):
	emit_signal("camera_zone_enter", position, scale)
