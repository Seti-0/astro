extends Camera3D

@export_range(0.1, 5) var speed: float = 1
@export_range(0.1, 5) var rotation_speed: float = 1
@export_range(0.1, 5) var zoom_speed: float = 1
@export_range(0.1, 5) var base_zoom: float = 2

# This does not work at the moment!!
@export_range(0, 2*PI) var tilt: float = 0

var focus: Vector3 = Vector3(4, 10, -3)
var zoom_level: float = 2
var yaw: float = PI

func _process(delta):
	
	var translation = Vector3.ZERO
	var yaw_input = 0
	var zoom_input = 0
	
	if Input.is_action_pressed("Test Up"):
		translation -= transform.basis.z
	if Input.is_action_pressed("Test Down"):
		translation += transform.basis.z
	if Input.is_action_pressed("Test Left"):
		translation -= transform.basis.x
	if Input.is_action_pressed("Test Right"):
		translation += transform.basis.x
	if Input.is_action_pressed("Test Rotate Right"):
		yaw_input -= 1
	if Input.is_action_pressed("Test Rotate Left"):
		yaw_input += 1
	if Input.is_action_pressed("Test Zoom In"):
		zoom_input -= 1
	if Input.is_action_pressed("Test Zoom Out"):
		zoom_input += 1
	
	focus += translation * speed * delta
	yaw += yaw_input * rotation_speed * delta
	zoom_level += zoom_input * zoom_speed * delta
	
	self.rotation = Vector3(0, yaw, 0)
	self.position = focus + self.transform.basis.z * zoom_level
	
