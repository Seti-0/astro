extends RigidBody3D
class_name Ship

enum InputAxis {
	X, Y, Z,
	MAIN,
	PITCH, YAW, ROLL
}

################
# Note to Self #
################

# There is some numerical instability with the angular dampening method.
# _integrate_forces might be a good place to fix it, if I ever get around to it.

############
# End Note #
############

# X/Y/Z/etc refer to the godot coordinate system, which is right handed
# and -Z forward. That system makes lots of sense from a graphics programming
# POV, but less so outside of that, so it should never be visible to the user.

var main_plume: Node3D
var desired_torque = Vector3(0, 0, 0)
var stop_requested: bool = false

var axis_input_values = []

func _ready():
	
	main_plume = find_child("Main Plume")
	
	for input_kind in InputAxis.values():
		axis_input_values.append(0)

func set_main_plume_active(val: bool):
	main_plume.active = val

func DEBUG_request_stop():
	stop_requested = true

func _physics_process(delta):
	main_plume.active = axis_input_values[InputAxis.MAIN] != 0
	apply_input(delta)

func _integrate_forces(state):
	if stop_requested:
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		stop_requested = false

func add_input(axis: InputAxis, val: float):
	axis_input_values[axis] = clamp(axis_input_values[axis] + val, -1, 1)

func set_input(axis: InputAxis, val: float):
	axis_input_values[axis] = clamp(val, -1, 1)

func get_input(axis: InputAxis) -> float:
	return axis_input_values[axis]

func apply_input(delta):
	
	# This function should be called from _physics_process,
	# since it affects the physics properties of the RigidBody
	
	################
	# Linear Speed #
	################
	
	# This bit is really easy because I've opted against linear dampening for
	# now. That might change in time, depending on how the controls feel.

	var forwards = self.transform.basis.z
	var right = self.transform.basis.x
	var up = self.transform.basis.y
	
	const speed = 2
	const main_speed = 10
	
	var x_input = axis_input_values[InputAxis.X]
	var y_input = axis_input_values[InputAxis.Y]
	var z_input = axis_input_values[InputAxis.Z]
	var main_input = axis_input_values[InputAxis.MAIN]
	
	var final_force = \
		forwards * (z_input * speed - main_input * main_speed) +\
		right * x_input * speed +\
		up * y_input * speed
	
	# The only thing to be careful about is that the apply_central_force works
	# in global coordinates, hence the basis of forwards/right/up below.
	
	self.apply_central_force(final_force)
	
	####################
	# Rotational Speed #
	####################
	
	# This section is complicated (and very inefficient).
	# The goal is to have rotational inertia, such that a player accelerate
	# the spin of the ship to very high speeds (purely for immersion, there is
	# no practical use to this). 
	
	# However, auto-inertial-dampening is also needed, since without it ship
	# control quickly becomes a nightmare. Getting inertial rotation and 
	# and dampening to play well together was an exercise in trial and error
	# that has strayed outside of what I fully understand, inertia-wise.
	
	const rotation_speed = 5
	
	# WARNING: if this is too high relative to delta, numeric explosions 
	# can happen. I'm not sure how to fix this instability.
	const rotation_power = rotation_speed * 1
	
	var roll_input = axis_input_values[InputAxis.ROLL]
	var yaw_input = axis_input_values[InputAxis.YAW]
	var pitch_input = axis_input_values[InputAxis.PITCH]

	# This calculation of existing torque is the main thing I'm not sure of, 
	# and it affects everything else. It does seem to work though.

	var existing_torque = self.get_inverse_inertia_tensor().inverse() * self.angular_velocity
	
	# I'm also not entirely sure that torques can be treated linearly, which I
	# do lots below. I think it follows from the equation tau = Ia, since 
	# that's just a matrix multiplying a vector in this case. So angular 
	# velocity is equal to a matrix (the inverse inertial tensor) multiplied
	# by the torque vector. That torque vector can be split into multiple
	# terms added together, each transformed by the matrix individually, 
	# without affecting the final angular momentum.
	
	var abs_input = abs(roll_input) + abs(yaw_input) + abs(pitch_input)
	
	# This is the main switch. If there is input, then set the target momentum
	# to be in the direction of the input, allowing it to grow unchecked. This
	# means that momentum perpendicular to the input direction is damped.
	
	if abs_input > 0:
		
		var input_torque = (
			forwards * roll_input +
			up * yaw_input +
			right * pitch_input	
		) * rotation_speed
		var input_direction = input_torque.normalized()
		var input_magnitude = input_torque.length()
		
		var existing_magnitude = existing_torque.dot(input_direction)
		var desired_magnitude = existing_magnitude + input_magnitude

		desired_torque = input_direction * desired_magnitude
		
	# If there is no input, then damp all motion.
	
	else:
		desired_torque = Vector3.ZERO
	
	# Acceleration and damping are limited by rotation power.
	# Note the "min()" in the applied torque. If the remaining delta is less
	# then the rotation power, then reducing the impulse power accordingly 
	# allows 
	
	var torque_delta = desired_torque - existing_torque
	self.apply_torque(torque_delta.normalized() * min(rotation_power, torque_delta.length()/delta))
