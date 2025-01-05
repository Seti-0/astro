extends MeshInstance3D

@export var generator: MeshGenUtil = MeshGenUtil.new()
@export var shape_noise: Noise = FastNoiseLite.new()
@export var color_noise: Noise = FastNoiseLite.new()

@export var noise_magnitude: float = 0:
	set(val):
		noise_magnitude = val
		self.update()

@export var base_magnitude: float = 0.5:
	set(val):
		base_magnitude = val
		self.update()

func get_actions_hint():
	return ["update", "save", "save_tex"]

func _ready():
	self.mesh = self.generator.mesh
	self.update()
	self.generator.changed.connect(update)
	self.shape_noise.changed.connect(update)
	self.color_noise.changed.connect(update)
	
	var material := StandardMaterial3D.new()
	generator.material = material
	material.albedo_color = Color.FOREST_GREEN

func update():
	
	var gen = self.generator 
	
	gen.begin_surface()
	
	# Ico sphere texture generation isn't supported at the moment,
	# though the mesh generation is.
	# I'd like to complete support for this at some point just as an excercise, 
	# though I think the cube sphere is more practical in general.
	# if use_ico:
	#	gen.add_ico_sphere()
	# else:
	# 	gen.add_cube_sphere()
	
	gen.add_cube_sphere()
	gen.commit_surface()

	gen.begin_mesh_edit()
	
	# Push in/out vertices randomly.
	var mesh_tool: MeshDataTool = gen.mesh_data_tool
	for i in range(mesh_tool.get_vertex_count()):
		
		var vertex = mesh_tool.get_vertex(i)
		
		var noise = self.shape_noise.get_noise_3dv(vertex * 10)
		var clamped_noise = clamp(abs(noise), 0, 1)
		var mag = base_magnitude + noise_magnitude*clamped_noise
		
		if abs(vertex.dot(Vector3.UP)) > 0.9:
			mag += 0.015
		
		mesh_tool.set_vertex(i, vertex * mag)
	
	gen.commit_mesh_edit()

func save():
	ResourceSaver.save(self.mesh, "res://meshes/generation/out.tres")

func save_tex():
	var tex = self.generator.material.albedo_texture
	ResourceSaver.save(tex, "res://meshes/generation/gen-1.tres")
