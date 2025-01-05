extends Node
class_name PlayerShip

@export var ship: Ship
@export var info_label: InfoLabel = null

class Binding:
	var name: StringName
	var axis: Ship.InputAxis
	var value: float
	var state = false
	func _init(
		binding_name: StringName, 
		binding_axis: Ship.InputAxis, 
		binding_value: float
	):
		self.name = StringName(binding_name)
		self.axis = binding_axis
		self.value = binding_value

var bindings = [
	Binding.new("Up", Ship.InputAxis.Y, 1),
	Binding.new("Down", Ship.InputAxis.Y, -1),
	Binding.new("Left", Ship.InputAxis.X, -1),
	Binding.new("Right", Ship.InputAxis.X, 1),
	Binding.new("Forwards (Maneuver)", Ship.InputAxis.Z, -1),
	Binding.new("Forwards (Main)", Ship.InputAxis.MAIN, 1),
	Binding.new("Reverse", Ship.InputAxis.Z, 1),
	Binding.new("Pitch Up", Ship.InputAxis.PITCH, 1),
	Binding.new("Pitch Down", Ship.InputAxis.PITCH, -1),
	Binding.new("Yaw Left", Ship.InputAxis.YAW, 1),
	Binding.new("Yaw Right", Ship.InputAxis.YAW, -1),
	Binding.new("Roll Left", Ship.InputAxis.ROLL, 1),
	Binding.new("Roll Right", Ship.InputAxis.ROLL, -1)
]

func _unhandled_input(event):
	
	if event.is_echo():
		return

	for binding in bindings:
		
		if event.is_action_pressed(binding.name, false, true):
			if not binding.state:
				binding.state = true
				ship.add_input(binding.axis, binding.value)
		
		if event.is_action_released(binding.name):
			if binding.state:
				binding.state = false
				ship.add_input(binding.axis, -binding.value)
				
	if Input.is_action_just_pressed("Debug Stop"):
		ship.DEBUG_request_stop()
		if info_label != null:
			info_label.show_message("DEBUG STOP")
