@tool
extends MeshInstance3D
class_name SphereTestItem

var surface_tool = SurfaceTool.new()
var vertex_count: int = 0

@export var gen_material: Material:
	set(val):
		gen_material = val
		update_mesh()

@export_range(0., 5.) var gen_scale: float:
	set(val):
		gen_scale = val
		update_mesh()

@export var update = false:
	set(_val):
		update_mesh()
		
@export var save = false:
	set(_val):
		save_mesh()

func _ready():

	self.mesh = ArrayMesh.new()
	update_mesh()
	
	if Engine.is_editor_hint():
		return
	
	#############
	# Selection #
	#############
	
	var collision_sphere = SphereShape3D.new()
	collision_sphere.radius = 1
	
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	collision.shape = collision_sphere
	area.add_child(collision)
	add_child(area)
	
	var input_handler = func(
		_camera: Node, event: InputEvent,
		_position: Vector3, _normal: Vector3, _shape_idx: int
	):
		if event is InputEventMouseButton:
			get_parent().set_selection(self)
	
	area.input_event.connect(input_handler)

func update_mesh():
	if not (mesh is ArrayMesh):
		return
	
	self.mesh.clear_surfaces()
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	vertex_count = 0
	
	on_mesh_update()
	
	if gen_material != null:
		surface_tool.set_material(gen_material)
	surface_tool.commit(self.mesh)
	surface_tool.clear()

func on_mesh_update():
	pass

func save_mesh():
	
	var path: String = "res://experiments/mesh-generation/" + self.name + "_mesh.tres"
	print("Saved mesh to '" + path + "'")
	print("Vertex count: " + str(vertex_count))
	ResourceSaver.save(self.mesh, path)

func add_vertex(vertex: Vector3, uv: Vector2, normal: Vector3):
	surface_tool.set_uv(uv)
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertex)
	vertex_count += 1
