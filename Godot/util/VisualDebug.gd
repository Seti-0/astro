extends MeshInstance3D
class_name VisualDebugInstance

var current_draw_color: Color

class VisualLine:

	var start: Vector3
	var end: Vector3
	var color: Color
	var size: float

	func with_color(val: Color) -> VisualLine:
		self.color = val
		return self
	
	func with_size(val: float) -> VisualLine:
		self.size = val
		return self
	
	func draw(instance: VisualDebugInstance):
		instance.draw_arrow(
			self.start, self.end, self.size, self.color
		)

class VisualVector:

	var location: Vector3
	var value: Vector3
	var offset: float
	var color: Color
	var size: float

	func with_color(val: Color) -> VisualVector:
		self.color = val
		return self
	
	func with_size(val: float) -> VisualVector:
		self.size = val
		return self
	
	func with_offset(val: float) -> VisualVector:
		self.offset = val
		return self
	
	func draw(instance: VisualDebugInstance):
		var val_dir = self.value.normalized()
		var start = self.location + self.offset * val_dir
		var end = self.location + (self.offset + self.value.length()) * val_dir 
		instance.draw_arrow(start, end, self.size, self.color)

var base_offset: float
var base_size: float
var entries = []

func set_offset(val: float):
	self.base_offset = val

func set_size(val: float):
	self.base_size = val

func add_line(start: Vector3, end: Vector3, color: Color) -> VisualLine:
	
	if MyMath.vec3_eq(start, end, MyMath.EPSILON_WORLD_COORDS):
		return VisualLine.new()
	
	var entry = VisualLine.new()
	entry.size = self.base_size
	entry.color = color
	entry.start = start
	entry.end = end
	entries.append(entry)
	return entry

func add_vector(pos: Vector3, val: Vector3, color: Color) -> VisualVector:
	
	if MyMath.vec3_eq(val, Vector3.ZERO, 0.001):
		return VisualVector.new()
		
	var entry = VisualVector.new()
	entry.location = pos
	entry.value = val
	entry.size = self.base_size
	entry.color = color
	entry.offset = self.base_offset
	entries.append(entry)
	return entry

func _ready():
	self.mesh = ImmediateMesh.new()
	self.material_override = StandardMaterial3D.new()
	self.material_override.vertex_color_use_as_albedo = true

func _process(_delta):
	
	if not (self.mesh is ImmediateMesh):
		push_error("Warning: mesh not set to ImmediateMesh")
		return
	
	if self.entries.size() == 0:
		return
	
	self.mesh.clear_surfaces()
	self.mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for entry in entries:
		entry.draw(self)
	
	self.mesh.surface_end()
	self.entries.clear()


func draw_arrow(p0: Vector3, p1: Vector3, size: float, color: Color):
	
	self.current_draw_color = color
	
	var arrow_length = (p1 - p0).length()
	var arrow_radius = 1 * size
	var arrow_head_radius = 2 * size
	var arrow_head_length = 4 * size

	var p01 = (p1 - p0).normalized()
	
	var origin = p0
	var forwards: Vector3
	var radial_a: Vector3
	if MyMath.vec3_eq(p01, Vector3.FORWARD, 0.01):
		forwards = Vector3.FORWARD
		radial_a = Vector3.UP
	elif MyMath.vec3_eq(p01, -Vector3.FORWARD, 0.01):
		forwards = -Vector3.FORWARD
		radial_a = -Vector3.UP
	else:
		forwards = p01
		var arrow_rotation = Quaternion(Vector3.FORWARD, forwards)
		radial_a = arrow_rotation * Vector3.UP	
	var radial_b = radial_a.rotated(forwards, 2*PI/3)
	var radial_c = radial_a.rotated(forwards, -2*PI/3)

	# Arrow base
	var base_a = origin + radial_a * arrow_radius
	var base_b = origin + radial_b * arrow_radius
	var base_c = origin + radial_c * arrow_radius 
	self.add_flat(base_a, base_b, base_c)

	# Arrow shaft sides
	var shaft_head_a = base_a + forwards*arrow_length
	var shaft_head_b = base_b + forwards*arrow_length
	var shaft_head_c = base_c + forwards*arrow_length
	# Quad opposite radial_c
	self.add_flat(shaft_head_a, base_b, base_a)
	self.add_flat(shaft_head_a, shaft_head_b, base_b)
	# Quad opposite radial_a
	self.add_flat(shaft_head_b, base_c, base_b)
	self.add_flat(shaft_head_b, shaft_head_c, base_c)
	# Quad opposite radial_b
	self.add_flat(shaft_head_c, base_a, base_c)
	self.add_flat(shaft_head_c, shaft_head_a, base_a)
	
	# Arrowhead
	var head_base_a = origin + radial_a*arrow_head_radius + forwards*arrow_length
	var head_base_b = origin + radial_b*arrow_head_radius + forwards*arrow_length
	var head_base_c = origin + radial_c*arrow_head_radius + forwards*arrow_length
	var head_point = origin + forwards * (arrow_head_length + arrow_length)
	# Base
	self.add_flat(head_base_a, head_base_b, head_base_c)
	# Sides
	self.add_flat(head_base_a, head_point, head_base_b)
	self.add_flat(head_base_b, head_point, head_base_c)
	self.add_flat(head_base_c, head_point, head_base_a)

func add_flat(a: Vector3, b: Vector3, c: Vector3):
	var normal = (c - a).cross(b - a).normalized()
	self.mesh.surface_set_color(current_draw_color)
	self.mesh.surface_set_normal(normal)
	self.mesh.surface_add_vertex(a)
	self.mesh.surface_set_color(current_draw_color)
	self.mesh.surface_set_normal(normal)
	self.mesh.surface_add_vertex(b)
	self.mesh.surface_set_color(current_draw_color)
	self.mesh.surface_set_normal(normal)
	self.mesh.surface_add_vertex(c)
