extends Camera2D


func _ready():
	pass # Replace with function body.



func _on_CameraZone_camera_zone_enter(position, scale):
	limit_left = position.x - scale.x/2 * 64;
	limit_right = position.x + scale.x/2 * 64;
	print(position.x)
	print(scale.x)
