extends Node3D

@export var domain_w: int = 40
@export var domain_h: int = 10
@export var domain_l: int = 100
@export var time_steps: int = 5
@export var dx: float = 1
@export var asteroid_scale: float = 1

@export var mesh: Mesh = SphereMesh.new()

func _ready():
	var data = self.generate_data()
	self.place_asteroid_instances(data)
	ResourceSaver.save(data, "res://experiments/asteroid-gen/data.tres")

func generate_data() -> AsteroidData:
	
	var grids = []
	for t in range(time_steps):
		print("Initializing: " + str(t))
		var values = FloatGrid3.new(domain_w, domain_h, domain_l)
		grids.append(values)
	
	var initial_grid: FloatGrid3 = grids[0]
	var grid_size = initial_grid.size
	for i in range(grid_size.x):
		for j in range(grid_size.y):
			for k in range(grid_size.z):
				var pos = Vector3i(i, j, k)
				var depth = float(pos.x) / domain_w
				# This is to add a fade to the edges of the area
				var density = 1 - abs(pow((2*depth - 1), 2))
				initial_grid.set_val(pos, randf()*density)
	
	for n in range(1, time_steps):
		var x = grids[n]
		var x_prev = grids[n-1]
		print("Performing iteration %d" % n)
		
		for i in range(grid_size.x):
			for j in range(grid_size.y):
				for k in range(grid_size.z):
					var pos = Vector3i(i, j, k)
				
					var here = pos
					var up = pos + Vector3i.UP
					var down = pos + Vector3i.DOWN
					var left = pos + Vector3i.LEFT
					var right = pos + Vector3i.RIGHT
					var forwards = pos + Vector3i.FORWARD
					var back = pos + Vector3i.BACK
					
					var here_val = x_prev.get_or_default(here, 0)
					var up_val = x_prev.get_or_default(up, 0)
					var down_val = x_prev.get_or_default(down, 0)
					var left_val = x_prev.get_or_default(left, 0)
					var right_val = x_prev.get_or_default(right, 0)
					var forwards_val = x_prev.get_or_default(forwards, 0)
					var back_val = x_prev.get_or_default(back, 0)
					
					var c = here_val + up_val + down_val + left_val + right_val \
						+ forwards_val + back_val
					if c < MyMath.EPSILON_WORLD_COORDS:
						continue
					
					var target = here
					if randf() < up_val/c:
						target = up
					elif randf() < down_val/c:
						target = down
					elif randf() < left_val/c:
						target = left
					elif randf() < right_val/c:
						target = right
					elif randf() < forwards_val/c:
						target = forwards
					elif randf() < back_val/c:
						target = back
					
					# Move the current value to the target cell.
					var current_val = x_prev.get_val(here)
					x.add_val(here, -current_val)
					x.add_val(target, current_val)
	
	var final_grid = grids[grids.size() - 1]
	var data = AsteroidData.new()
	data.count = 0
	for i in range(final_grid.size.x):
		for j in range(final_grid.size.y):
			for k in range(final_grid.size.z):
				
				var pos = Vector3i(i, j, k)
				var value = final_grid.get_val(pos)
				if value < 0.4:
					continue
				
				var rand_offset = 2*(Vector3(randf(), randf(), randf()) - Vector3.ONE*0.5)
				var asteroid_pos = pos * dx * 1.1 + rand_offset
				asteroid_pos.x += 0.4*asteroid_pos.y + 0.005*pow(asteroid_pos.z, 2)
				var asteroid_size = asteroid_scale * value
				
				data.positions.append(asteroid_pos)
				data.sizes.append(asteroid_size)
				data.count += 1
	
	print("Placed %d asteroids." % data.count)
	return data

func clear_asteroid_instances():
	for node in self.get_children():
		self.remove_child(node)
		node.queue_free()

func place_asteroid_instances(data: AsteroidData):
	self.clear_asteroid_instances()
	for i in range(data.count):
		var instance = MeshInstance3D.new()
		instance.mesh = self.mesh
		instance.position = data.positions[i]
		instance.scale = Vector3.ONE * data.sizes[i]
		self.add_child(instance)
	
class FloatGrid3:
	
	var data: PackedFloat32Array
	var size: Vector3i
	var stride: Vector3i
	
	func _init(grid_w: int, grid_h: int, grid_l: int):
		self.data = PackedFloat32Array()
		self.data.resize(grid_w*grid_h*grid_l)
		self.size = Vector3i(grid_w, grid_h, grid_l)
		self.stride = Vector3i(grid_h*grid_l, grid_l, 1)

	func check_bounds(pos: Vector3i):
		var valid = true
		var size = self.size
		if pos.x < 0 or pos.y < 0 or pos.z < 0:
			push_error("Negative index: %s" % str(pos))
			valid = false
		elif pos.x > size.x or pos.y > size.y or pos.z > size.z:
			var template = "Index %s is out of bounds for grid of size %s"
			push_error(template % [str(pos), str(self.size)])
			valid = false
		return valid
	
	func check_bounds_silent(pos: Vector3i):
		return pos.x >= 0 and pos.y >= 0 and pos.z >= 0\
			and pos.x < size.x and pos.y < size.y and pos.z < size.z

	func get_index(pos: Vector3i):
		return pos.x * self.stride.x +\
			pos.y * self.stride.y +\
			pos.z * self.stride.z

	func get_val(pos: Vector3i) -> float:
		if check_bounds(pos):
			return self.data[self.get_index(pos)]
		else:
			return 0
	
	func get_or_default(pos: Vector3i, default: float) -> float:
		if check_bounds_silent(pos):
			return self.data[self.get_index(pos)]
		else:
			return default
	
	func set_val(pos: Vector3i, val: float):
		if check_bounds(pos):
			self.data[self.get_index(pos)] = val
	
	func add_val(pos: Vector3i, val: float):
		if check_bounds(pos):
			self.data[self.get_index(pos)] += val

# This is horrendous but unfortunately not out of character
# for gdscript I think.
# I did try make a custom generator, but it crashed with an obscure error.
# Also, there is an open issue on github r.e. custom iterators being
# even slower than the array approach.
# https://github.com/godotengine/godot/issues/42053
static func iter_grid(size: Vector3i) -> Array[Vector3i]:
	var array: Array[Vector3i]
	for i in range(size.x):
		for j in range(size.y):
			for k in range(size.z):
				array.append(Vector3i(i, j, k))
	return array

######################
# This doesn't work! #
######################
# I don't know why. It just gives an obscure error:
# "There was an error calling "_iter_next" on iterator
# object of type <RefCounted#...>"
#
#class Grid3Iterator:
#
#	var current: Vector3i
#	var end: Vector3i
#	
#	func _init(iter_end: Vector3i):
#		current = Vector3i.ZERO
#		end = iter_end
#	
#	func should_continue():
#		return current.x < end.x
#	
#	func _iter_init(_arg):
#		current = Vector3i.ZERO
#		return end.x > 0 and end.y > 0 and end.z > 0
#
#	func _init_next(_arg):
#		
#		if current.x >= end.x:
#			return false
#		
#		current.z += 1
#		if current.z < end.z:
#			return true
#		
#		current.z = 0
#		current.y += 1
#		if current.y < end.y:
#			return true
#		
#		current.y = 0
#		current.x += 1
#		if current.x < end.x:
#			return true
#		
#		current.x = end.x
#		return false
#	
#	func _iter_get(_arg):
#		return current
