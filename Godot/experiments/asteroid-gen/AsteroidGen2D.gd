extends Node2D

@export var noise: Noise = FastNoiseLite.new()
@export var colors: GradientTexture1D = GradientTexture1D.new()

@export_range(0, 100, 1) var arrow_scale: float = 1:
	set(val):
		arrow_scale = val
		self.queue_redraw()

@export_range(0, 1, 0.01) var time: float = 0:
	set(val):
		time = val
		self.queue_redraw()

@export var time_steps: int = 20:
	set(val):
		time_steps = val
		self.on_change_sim_params(true)

@export var grid_width: int = 20:
	set(val):
		grid_width = val
		self.on_change_sim_params(true)

@export var grid_height: int = 20:
	set(val):
		grid_height = val
		self.on_change_sim_params(true)

@export var base_radius: float = 1:
	set(val):
		base_radius = val
		self.queue_redraw()

@export var base_spacing: float = 1:
	set(val):
		base_radius = val
		self.queue_redraw()

var data: Array = []
var vel_field: Array = []

func _ready():
	
	var editor = PropertyEditor.add_editor(self.get_parent(), self)
	editor.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	
	self.create_grid()
	self.simulate()
	self.queue_redraw()
	
	self.noise.connect("changed", self.on_change_sim_params.bind(false))

func _draw():
	if data == null or data.size() == 0:
		return
	
	var time_index = int(self.time * self.time_steps)
	time_index = clamp(time_index, 0, data.size() - 1)
	var grid: FloatGrid = self.data[time_index]
	var vel: Vec2Grid = self.vel_field[time_index]
	
	var grid_scale: float = 10
	for i in range(grid.w):
		for j in range(grid.h):
			var value = grid.get_val(i, j)
			var radius: float = value * base_radius * grid_scale
			var x := i * base_spacing * grid_scale * 2.1
			var y := j * base_spacing * grid_scale * 2.1
			var color = colors.gradient.sample(value)
			self.draw_arc(
				Vector2(x, y), radius, 0, 2*PI, 
				100, color, radius + 1, true
			)
	
	for i in range(grid.w):
		for j in range(grid.h):
			var x := i * base_spacing * grid_scale * 2.1
			var y := j * base_spacing * grid_scale * 2.1
			var a = Vector2(x, y)
			var b = a + vel.get_val(i, j) * arrow_scale
			self.draw_arrow(a, b, Color.YELLOW)

func draw_arrow(a: Vector2, b: Vector2, color: Color):
	
	var ab = b - a
	var arrow_len = ab.length()
	if arrow_len < 5:
		return
	
	#push_warning("%s --> %s" % [str(a), str(b)])
	
	var dir_ab = ab / arrow_len
	var n = dir_ab.rotated(PI/2)
	
	var arrow_size = min(100, arrow_len)
	var arrow_width = arrow_size * 0.08
	var arrow_head_width = arrow_size * 0.2
	var arrow_head_len = arrow_size * 0.3
	var shaft_len = arrow_len - arrow_head_len
	
	var points = PackedVector2Array([
		a - (arrow_width/2)*n,
		a - (arrow_width/2)*n + dir_ab * shaft_len,
		a - (arrow_head_width/2)*n + dir_ab * shaft_len,
		b,
		a + (arrow_head_width/2)*n + dir_ab * shaft_len,
		a + (arrow_width/2)*n + dir_ab * shaft_len,
		a + (arrow_width/2)*n
	])
	
	self.draw_colored_polygon(points, color)

func on_change_sim_params(regen_grid: bool):
	if regen_grid:
		self.create_grid()
	self.simulate()
	self.queue_redraw()

func create_grid():
	self.data.clear()
	for i in range(time_steps):
		var grid = FloatGrid.new(self.grid_width, self.grid_height)
		self.data.append(grid)
	self.vel_field.clear()
	for i in range(time_steps):
		var grid = Vec2Grid.new(self.grid_width, self.grid_height)
		self.vel_field.append(grid)

func simulate():
	
	var w = self.grid_width
	var h = self.grid_height
	var initial_grid: FloatGrid = self.data[0]
	
	var max_noise = 1
	for i in range(w):
		for j in range(h):
			var noise_val = abs(noise.get_noise_2d(i, j))
			if noise_val > max_noise:
				max_noise = noise_val
			initial_grid.set_val(i, j, noise_val)
	
	if max_noise > 1:
		for i in range(w):
			for j in range(h):
				var normalized = initial_grid.get_val(i, j)/max_noise
				initial_grid.set_val(i, j, normalized)
	
	for n in range(1, time_steps):
		var x: FloatGrid = self.data[n]
		var x_prev: FloatGrid = self.data[n-1]
		var v: Vec2Grid = self.vel_field[n]

		# Start out with a grid that is identical to
		# the previous one.
		for i in range(w):
			for j in range(h):
				x.set_val(i, j, x_prev.get_val(i, j))
		
		# Move values towards the nearest greatest value.
		# (Kinda like a one-way gravitational attraction)
		for i in range(w):
			for j in range(h):
				
				var here = x_prev.get_or_default(i, j, 0)
				var up = x_prev.get_or_default(i, j+1, 0)
				var down = x_prev.get_or_default(i, j-1, 0)
				var left = x_prev.get_or_default(i-1, j, 0)
				var right = x_prev.get_or_default(i+1, j, 0)
				
				var c = here + up + down + left + right
				if c < MyMath.EPSILON_WORLD_COORDS:
					continue
				
				var pull: Vector2 = Vector2.ZERO
				pull += Vector2.UP * up/c
				pull += Vector2.DOWN * down/c
				pull += Vector2.LEFT * left/c
				pull += Vector2.RIGHT * right/c
				v.set_val(i, j, pull)
				
				var target := Vector2i(i, j)
				if randf() < up/c:
					target = Vector2i(i, j+1)
				elif randf() < down/c:
					target = Vector2i(i, j-1)
				elif randf() < left/c:
					target = Vector2i(i-1, j)
				elif randf() < right/c:
					target = Vector2i(i+1, j)
				
				# Move the current value to the target cell.
				var current_val = x_prev.get_val(i, j)
				x.add_val(i, j, -current_val)
				x.add_val(target.x, target.y, current_val)

################################
# Utility: Grid Data Structure #
################################

class FloatGrid:
	
	var w: int
	var h: int
	var data := PackedFloat32Array()
	
	func _init(grid_w: int, grid_h: int):
		self.w = grid_w
		self.h = grid_h
		self.data.resize(grid_w*grid_h)
	
	func fill(val: float):
		self.data.fill(val)
	
	func index_valid(i: int, j: int):
		var valid = true
		
		if i < 0:
			push_error("Recieved negative index i: %d." % i)
			valid = false
		elif i >= self.w:
			const template = "Index %d is too large for grid with width %d."
			push_error(template % [i, self.w])
		
		if j < 0:
			push_error("Recieved negative index j: %d" % j)
		elif j >= self.h:
			const template = "Index %d is too large for grid with width %d."
			push_error(template % [j, self.h])
		
		return valid
	
	func set_val(i: int, j: int, val: float):
		if not index_valid(i, j):
			return
		self.data[i * self.h + j] = val
	
	func get_val(i: int, j: int) -> float:
		if not index_valid(i, j):
			return 0
		return self.data[i * self.h + j]

	func get_or_default(i: int, j: int, default: float) -> float:
		if i < 0 or i >= self.w or j < 0 or j >= self.h:
			return default
		return self.data[i * self.h + j]
	
	func add_val(i: int, j: int, val: float):
		if not index_valid(i, j):
			return
		self.data[i * self.h + j] += val
	
	func mul_val(i: int, j: int, val: float):
		if not index_valid(i, j):
			return
		self.data[i * self.h + j] *= val

class Vec2Grid:
	
	var w: int
	var h: int
	var data := PackedVector2Array()
	
	func _init(grid_w: int, grid_h: int):
		self.w = grid_w
		self.h = grid_h
		self.data.resize(grid_w*grid_h)
	
	func fill(val: Vector2):
		self.data.fill(val)
	
	func index_valid(i: int, j: int):
		var valid = true
		
		if i < 0:
			push_error("Recieved negative index i: %d." % i)
			valid = false
		elif i >= self.w:
			const template = "Index %d is too large for grid with width %d."
			push_error(template % [i, self.w])
		
		if j < 0:
			push_error("Recieved negative index j: %d" % j)
		elif j >= self.h:
			const template = "Index %d is too large for grid with width %d."
			push_error(template % [j, self.h])
		
		return valid
	
	func set_val(i: int, j: int, val: Vector2):
		if not index_valid(i, j):
			return
		self.data[i * self.h + j] = val
	
	func get_val(i: int, j: int) -> Vector2:
		if not index_valid(i, j):
			return Vector2.ZERO
		return self.data[i * self.h + j]

	func get_or_default(i: int, j: int, default: Vector2) -> Vector2:
		if i < 0 or i >= self.w or j < 0 or j >= self.h:
			return default
		return self.data[i * self.h + j]
	
	func add_val(i: int, j: int, val: Vector2):
		if not index_valid(i, j):
			return
		self.data[i * self.h + j] += val
	
	func mul_val(i: int, j: int, val: Vector2):
		if not index_valid(i, j):
			return
		self.data[i * self.h + j] *= val
