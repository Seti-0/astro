extends Camera3D
class_name PlayerCamera

enum CameraMode {
	LINEAR_VEL,
	LOCAL,
}

@export var rotation_limit := PI

@export var local_rotation_duration := 0.2
@export var local_translation_duration := 0.2
@export var lvel_rotation_duration := 1.
@export var lvel_translation_duration := 0.2

@export var local_seat_distance := 3.5
@export var camera_distance := 10.
@export var player: PlayerShip = null
@export var camera_mode: CameraMode
@export var follow_selection: bool

@export var info_label: InfoLabel = null

var seat_distance: float
var target_dir: Vector3
var target_up_dir: Vector3
var previous_linear_v: Vector3

var selection: Node3D = null
var selection_up_dir: Vector3
var just_selected: bool = false
var previous_selection_angle: float

var DEBUG_previous_target_dir: Vector3 = Vector3.ZERO

func my_lerp(a: float, b: float, weight: float) -> float:
	return a + (b - a) * weight

func update_selection_up_dir():
	
	if selection == null:
		print("Clearing selection up dir.")
		selection_up_dir = Vector3.UP
		return
	
	var player_ship = player.ship
	
	var selection_dir = (selection.global_position - player_ship.global_position).normalized()
	var forward_dir = -player_ship.basis.z
	
	var local_selection_rotation = Quaternion(-forward_dir, -selection_dir)
	selection_up_dir = local_selection_rotation * player_ship.transform.basis.y

	print("Setting selection up dir to " + str(selection_up_dir))

func update_location(delta: float, instant: bool):
	
	var player_ship = player.ship
	
	if follow_selection and selection != null:
		
		# The up-direction for this view isn't stateless, it's updated
		# when the selection is updated. When updated every frame,
		# it goes a bit crazy when the ship is facing the camera.
		# It might be possible to update the view more often.
		
		target_up_dir = selection_up_dir
		target_dir = (selection.global_position - player_ship.global_position).normalized()
		seat_distance = local_seat_distance
		
		if player_ship.global_position != DEBUG_previous_target_dir:
			#print("Setting selection target dir using global position: " + str(player_ship.global_position))
			DEBUG_previous_target_dir = player_ship.global_position
	
	elif camera_mode == CameraMode.LOCAL:
		target_dir = -player_ship.basis.z
		target_up_dir = player_ship.basis.y
		seat_distance = local_seat_distance
	
	elif camera_mode == CameraMode.LINEAR_VEL:
		var delta_v: float = (player_ship.linear_velocity - previous_linear_v).length() / delta
		previous_linear_v = player_ship.linear_velocity
		if player_ship.linear_velocity.length() > 0.1:
			target_dir = player_ship.linear_velocity.normalized()
			if delta_v > 0.1:
				target_up_dir = player_ship.basis.y
		seat_distance = 0
	
	var target_rotation = Transform3D.IDENTITY\
		.translated(-target_dir*camera_distance)\
		.looking_at(Vector3.ZERO, target_up_dir)\
		.basis.get_rotation_quaternion()
	
	var rot_str = delta * 5
	var pos_str = delta * 5
	
	if instant:
		rot_str = 1
		pos_str = 1
	
	var angspd_threshold = 3*PI
	var angspd = player_ship.angular_velocity.length()
	var correction = clamp(0.1 * (angspd - angspd_threshold), 0., 1.)
	rot_str = my_lerp(rot_str, 1., correction)
	pos_str = my_lerp(pos_str, 1., correction)
	
	var current_rotation = self.transform.basis.get_rotation_quaternion()
	var slerped_rotation = current_rotation.slerp(target_rotation, rot_str)
	
	# This is a limit on angular rotation. It works, but doesn't look good at all,
	# it's just a bandaid. At some point it might be worth trying to graph things
	# and figure out why there are rapid changes in angle for selection sometimes.
	#var rotation_delta = slerped_rotation.get_euler() - current_rotation.get_euler()
	#var rotation_factor = rotation_delta.length()/(delta*rotation_limit)
	#if rotation_factor > 1:
	#	rot_str /= rotation_factor
	#	slerped_rotation = current_rotation.slerp(target_rotation, rot_str)
	
	self.rotation = slerped_rotation.get_euler()
	self.position = player_ship.global_position +\
		self.transform.basis.z * camera_distance +\
		self.transform.basis.y * seat_distance

func _ready():
	var player_ship = player.ship
	if player_ship == null:
		push_error("Player camera has no subject to follow!")
		self.set_process(false)
		return
	
	target_dir = -player_ship.transform.basis.z
	target_up_dir  = player_ship.transform.basis.y
	update_location(0., true)

func _physics_process(delta):
	
	if Input.is_action_just_pressed("Change Camera Mode"):
		if not follow_selection:
			self.camera_mode = CameraMode.LOCAL
			self.follow_selection = true
			self.info_label.show_message("Camera Mode: FOLLOW SELECTION")
		else:
			camera_mode = CameraMode.LOCAL
			self.follow_selection = false
			self.info_label. show_message("Camera Mode: FORWARDS")
	
	update_location(delta, false)


func _on_asteroid_field_selection_changed(new_val):
	if new_val != selection:
		just_selected = true
		selection = new_val
		update_selection_up_dir()
