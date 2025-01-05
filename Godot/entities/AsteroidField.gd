extends Node3D

@export var asteroid_scale: float = 10
@export var asteroid_prefabs: Array[PackedScene] = []
@export var asteroid_data: AsteroidData

signal selection_changed(selection: Node3D)

var previous_selection: Node3D = null
var selected_asteroid: Node3D = null

func _ready():
	self.place_asteroids()

func get_actions_hint():
	return ["generate_asteroids"]

func _process(_delta):
	check_selection()

func _unhandled_input(e):
	if e is InputEventMouseButton and not e.is_pressed():
		
		# This is a bit of a hack atm.
		# This function is called before the asteroid input even callback 
		# unfortunately, I don't know how to wait until after it. 
		# This means that checking to see if the selection has been cleared 
		# requires a _process old != new as far as I can tell.
		selected_asteroid = null

func check_selection():
	if selected_asteroid != previous_selection:
		selection_changed.emit(selected_asteroid)
	previous_selection = selected_asteroid

func place_asteroids():
	
	if self.asteroid_prefabs.size() == 0:
		push_error("No asteroid prefabs given!")
		return
	
	if self.asteroid_data == null:
		push_error("No asteroid data given!")
		return
	
	for node in self.get_children():
		self.remove_child(node)
		node.queue_free()
	
	var input_handler = func(
		_camera, e: InputEvent, _pos, _normal, _shape_idx,
		src_asteroid: Node3D
	):
		if e is InputEventMouseButton:
			if not e.is_pressed():
				selected_asteroid = src_asteroid
	
	for i in range(asteroid_data.count):
		
		var prefab = self.asteroid_prefabs[0]
		var instance: RigidBody3D = prefab.instantiate()
		instance.position = self.asteroid_data.positions[i] * self.asteroid_scale
		
		var size = self.asteroid_data.sizes[i] * self.asteroid_scale
		var instance_scale = Vector3.ONE * size
		instance.find_child("MeshInstance3D").scale = instance_scale
		instance.find_child("CollisionShape3D").scale = instance_scale
		instance.mass = 0.005 * pow(size, 3)
		instance.inertia = Vector3.ONE * instance.mass * pow(size, 2)

		instance.rotation.x = randf()*2*PI
		instance.rotation.y = randf()*2*PI
		instance.rotation.z = randf()*2*PI

		self.add_child(instance)
		instance.input_event.connect(input_handler.bind(instance))

	print("Placed %d asteroids." % self.asteroid_data.count)
