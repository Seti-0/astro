extends Control

@export var player: PlayerShip
@export var vel_display: VelocityDisplay
@export var spd_display: Label

var selection: RigidBody3D

func _process(_delta):
	update_displays()

func _on_asteroid_field_selection_changed(new_val):
	selection = new_val

func update_displays():
	
	###################
	# Collecting Data #
	###################
	
	var relative_vel = Vector3.ZERO
	var vel_x = 0
	var vel_y = 0
	
	var has_target_distance = false
	var target_distance: float
	
	var has_intercept = false
	var intercept_closest_distance: float
	var intercept_time: float
	
	if player != null:
		
		var player_ship = player.ship
		
		######################
		# Relative X/Y speed #
		######################
		
		relative_vel = player_ship.linear_velocity
		if selection != null:
			relative_vel -= selection.linear_velocity
			
		# This c should be proportional to the strafing thruster power
		# of the ship.
		const c = 15
		var x_thrust_axis = player_ship.transform.basis.x
		var y_thrust_axis = player_ship.transform.basis.y
		vel_x = relative_vel.dot(x_thrust_axis) / c
		vel_y = relative_vel.dot(y_thrust_axis) / c
		
		#################################
		# Time/distance to closest pass #
		#################################
		
		if selection != null:
			var k = selection.global_position - player_ship.global_position
			var m = selection.linear_velocity - player_ship.linear_velocity
			var m_len2 = m.length_squared()
			if m_len2 > MyMath.EPSILON_LINEAR_SPEED:
				var t = -k.dot(m) / m_len2
				var closest_point = player_ship.global_position + t*player_ship.linear_velocity
				intercept_closest_distance = (
					selection.global_position + t*selection.linear_velocity - closest_point
				).length()
				intercept_time = t
				has_intercept = true
		
		######################
		# Distance to target #
		######################
		
		if selection != null:
			target_distance = (selection.global_position - player_ship.global_position).length()
			has_target_distance = true
	
	###################
	# Displaying Data #
	###################
	
	if vel_display != null:
		self.vel_display.display.x_value = vel_x
		self.vel_display.display.y_value = vel_y
		self.vel_display.queue_redraw()
	
	if spd_display != null:
		spd_display.text = "%0.1f m/s" % relative_vel.length()
		
		if has_target_distance:
			spd_display.text += "\n%0.1f m" % target_distance
		
		if has_intercept and intercept_time >= 0:
			spd_display.text += "\n%0.1f m in %0.0f s" % [intercept_closest_distance, intercept_time]
