extends Resource
class_name MeshGenUtil

signal commit()

@export var material: Material = StandardMaterial3D.new():
	set(val):
		material = val
		self.emit_changed()

@export var smooth: bool = false:
	set(val):
		smooth = val
		self.emit_changed()

@export_range(0, 1, 0.01) var gen_scale: float = 1:
	set(val):
		gen_scale = val
		self.emit_changed()

var surface_tool := SurfaceTool.new()
var mesh_data_tool := MeshDataTool.new()
var mesh := ArrayMesh.new()

var generating_texture: bool = false
var texture_size: Vector2i
var texture_shapes: Array[PackedVector2Array] = []
var texture_colors: Array[PackedColorArray] = []
var texture_clear_color = Color.TRANSPARENT
var texture_color_map: Callable

var vertex_count = 0
var face_count = 0

func begin_surface():
	self.mesh.clear_surfaces()
	self.surface_tool.clear()
	self.surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	vertex_count = 0

func commit_surface():
	if self.material != null:
		self.surface_tool.set_material(self.material)
	self.surface_tool.commit(self.mesh)
	self.surface_tool.clear()
	self.commit.emit()

func begin_mesh_edit():
	self.mesh_data_tool.create_from_surface(mesh, 0)

func commit_mesh_edit():
	self.mesh.clear_surfaces()
	self.mesh_data_tool.commit_to_surface(mesh)
	vertex_count = self.mesh_data_tool.get_vertex_count()
	face_count = self.mesh_data_tool.get_face_count()
	self.commit.emit()

func begin_texture_gen(size: Vector2i, map: Callable):
	
	self.generating_texture = true
	self.texture_size = size
	self.texture_shapes.clear()
	self.texture_colors.clear()
	self.texture_color_map = map

func commit_texture():
	
	# For 2d rendering in a viewport, we first need to create
	# a viewport, and then a canvas to attach to the viewport. The
	# canvas acts as a parent for a canvas_item, which can draw
	# shapes which will appear in the viewport.
	
	# First, set up a new viewport.
	var view_size = self.texture_size
	var view_rid = RenderingServer.viewport_create()
	RenderingServer.viewport_set_active(view_rid, true)
	RenderingServer.viewport_set_size(view_rid, view_size.x, view_size.y)
	RenderingServer.viewport_set_update_mode(
		view_rid, RenderingServer.VIEWPORT_UPDATE_ONCE
	)
	RenderingServer.viewport_set_transparent_background(view_rid, true)
	
	# Create a canvas and attach it to the viewport.
	var canvas_rid = RenderingServer.canvas_create()
	var transform = Transform2D(0, Vector2(1, 1), 0, Vector2.ZERO)
	RenderingServer.viewport_attach_canvas(view_rid, canvas_rid)
	RenderingServer.viewport_set_canvas_transform(view_rid, canvas_rid, transform)
	
	# Create the canvas item, and draw things with it.
	var item_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(item_rid, canvas_rid)
	RenderingServer.canvas_item_add_rect(
		item_rid, Rect2(Vector2.ZERO, view_size), self.texture_clear_color
	)
	for i in range(texture_shapes.size()):
		RenderingServer.canvas_item_add_polygon(
			item_rid, texture_shapes[i], texture_colors[i]
		)
	
	# Wait for the scheduled render to occur.
	await RenderingServer.frame_post_draw
	
	# Extract the image from the viewport, add it to the material.
	var view_image_rid = RenderingServer.viewport_get_texture(view_rid)
	var view_image = RenderingServer.texture_2d_get(view_image_rid)
	
	# Fill in empty pixels that have neighbours, to avoid 
	# visual artefacts due to edge pixels interpolating.
	# This is a bit hacky and doesn't solve the issue of 
	# neighbouring pixels from different faces. I'm not sure 
	# how to go about that other than to make neighbouring
	# faces have similar colors.
	var image_copy = Image.new()
	image_copy.copy_from(view_image)
	for i in range(view_size.x):
		for j in range(view_size.y):
			var here = view_image.get_pixel(i, j)
			if here != Color(0, 0, 0, 0):
				if i > 0:
					var there = view_image.get_pixel(i-1, j)
					if there == Color(0, 0, 0, 0):
						image_copy.set_pixel(i-1, j, here)
				if j > 0:
					var there = view_image.get_pixel(i, j-1)
					if there == Color(0, 0, 0, 0):
						image_copy.set_pixel(i, j-1, here)
				if i < view_size.x - 1:
					var there = view_image.get_pixel(i+1, j)
					if there == Color(0, 0, 0, 0):
						image_copy.set_pixel(i+1, j, here)
				if j < view_size.y - 1:
					var there = view_image.get_pixel(i, j+1)
					if there == Color(0, 0, 0, 0):
						image_copy.set_pixel(i, j+1, here)
				
	var image_tex = ImageTexture.create_from_image(image_copy)
	self.material.albedo_texture = image_tex
	
	# Clear used texture generation info.
	self.generating_texture = false
	self.texture_size = Vector2.ZERO
	self.texture_shapes.clear()
	self.texture_colors.clear()

func blend_neighbour(
	image: Image, 
	i: int, j: int, offset_i: int, offset_j: int
) -> int:
	var ni = i + offset_i
	var nj = j + offset_j
	var w = image.get_width()
	var h = image.get_height()
	if ni < 0 or nj < 0 or ni >= w or nj >= h:
		return 0
	var ncolor = image.get_pixel(ni, nj)
	if ncolor == self.texture_clear_color:
		return 0
	var color = image.get_pixel(i, j)
	image.set_pixel(i, j, color + ncolor)
	return 1

func add_cube_sphere():
	
	# 8 vertices, 6 faces.
	#
	#    8 ------ 7
	#    |\       |\     
	#    | 5 ------ 6 
	#    | |      | |    --> z+
	#    4 |----- 3 |
	#     \|       \|
	#      1 ------ 2
	
	var v1 = Vector3(-1, -1, -1)
	var v2 = Vector3(-1, -1,  1)
	var v3 = Vector3( 1, -1,  1)
	var v4 = Vector3( 1, -1, -1)
	var v5 = Vector3(-1,  1, -1)
	var v6 = Vector3(-1,  1,  1)
	var v7 = Vector3( 1,  1,  1)
	var v8 = Vector3( 1,  1, -1)

	var uv_scale = Vector2(0.25, 1./3)
	var uv_1 = Vector2(0, 1) * uv_scale
	var uv_2 = Vector2(1, 0) * uv_scale
	var uv_3 = Vector2(1, 1) * uv_scale
	var uv_4 = Vector2(1, 2) * uv_scale
	var uv_5 = Vector2(2, 1) * uv_scale
	var uv_6 = Vector2(3, 1) * uv_scale

	self.add_cube_sphere_face(v1, v2, v6, v5, uv_1)
	self.add_cube_sphere_face(v1, v4, v3, v2, uv_2)
	self.add_cube_sphere_face(v2, v3, v7, v6, uv_3)
	self.add_cube_sphere_face(v6, v7, v8, v5, uv_4)
	self.add_cube_sphere_face(v3, v4, v8, v7, uv_5)
	self.add_cube_sphere_face(v4, v1, v5, v8, uv_6)

func add_cube_sphere_face(
	a: Vector3, b: Vector3, 
	_c: Vector3, d: Vector3,
	uv: Vector2
):

	var n_subdivisions = int(self.gen_scale * 10)
	var n_segments = n_subdivisions + 1

	# d -- c
	# |    |
	# a -- b
	var eb = (b - a) / n_segments
	var ed = (d - a) / n_segments
	var eu = Vector2(0.25, 0) / n_segments
	var ev = Vector2(0, 1./3) / n_segments
	for i in range(n_segments):
		for j in range(n_segments):
			var ai = a + eb*i + ed*j
			var bi = ai + eb
			var ci = ai + eb + ed
			var di = ai + ed
			var ai_uv = uv + eu*i + ev*j
			var bi_uv = ai_uv + eu
			var ci_uv = ai_uv + eu + ev
			var di_uv = ai_uv + ev
			self.add_mesh_sphere_face(
				bi, ai, di,
				bi_uv, ai_uv, di_uv
			)
			self.add_mesh_sphere_face(
				bi, di, ci,
				bi_uv, di_uv, ci_uv
			)

func add_ico_sphere():
	
	# I start by making an icosahedron, following the tutorial found here:
	# https://www.danielsieger.com/blog/2021/01/03/generating-platonic-solids.html
	
	# Phi is the golden ratio.
	const phi = (1. + sqrt(5)) * 0.5
	const a = 1.
	const b = 1./phi
	
	# YZ rectangle
	var v1 = Vector3( 0,  a,  b ) 
	var v2 = Vector3( 0,  a, -b )
	var v3 = Vector3( 0, -a, -b )
	var v4 = Vector3( 0, -a,  b )
	
	# XZ rectangle
	var v5 = Vector3(-b,  0,  a )
	var v6 = Vector3(-b,  0, -a )
	var v7 = Vector3( b,  0, -a )
	var v8 = Vector3( b,  0,  a )
	
	# XY rectangle
	var v9  = Vector3(-a,  b,  0 ) 
	var v10 = Vector3( a,  b,  0 )
	var v11 = Vector3( a, -b,  0 )
	var v12 = Vector3(-a, -b,  0 )
	
	# Around vertex 10 
	self.subdivide_ico_face_and_add(v1 , v2 , v10)
	self.subdivide_ico_face_and_add(v2 , v7 , v10)
	self.subdivide_ico_face_and_add(v7 , v11, v10)
	self.subdivide_ico_face_and_add(v11, v8 , v10)
	self.subdivide_ico_face_and_add(v8 , v1 , v10)
	
	# Around vertex 12, on the opposite side.
	self.subdivide_ico_face_and_add(v3 , v6 , v12)
	self.subdivide_ico_face_and_add(v6 , v9 , v12) 
	self.subdivide_ico_face_and_add(v9 , v5 , v12)
	self.subdivide_ico_face_and_add(v5 , v4 , v12)
	self.subdivide_ico_face_and_add(v4 , v3 , v12)
	
	# The middle between the above two segments.
	self.subdivide_ico_face_and_add(v9 , v2 , v1 )
	self.subdivide_ico_face_and_add(v2 , v9 , v6 )
	self.subdivide_ico_face_and_add(v6 , v7 , v2 )
	self.subdivide_ico_face_and_add(v7 , v6 , v3 )
	self.subdivide_ico_face_and_add(v3 , v11, v7 )
	self.subdivide_ico_face_and_add(v11, v3 , v4 )
	self.subdivide_ico_face_and_add(v4 , v8 , v11)
	self.subdivide_ico_face_and_add(v8 , v4 , v5 )
	self.subdivide_ico_face_and_add(v5 , v1 , v8 )
	self.subdivide_ico_face_and_add(v1,  v5 , v9 )

func subdivide_ico_face_and_add(a: Vector3, b: Vector3, c: Vector3):
	
	var N = int(self.gen_scale * 10)
	var eb = (b - a) / (N + 1)
	var ec = (c - a) / (N + 1)
	for i in range(N + 1):
		var ac = a + i*ec
		for j in range(N + 1 - i):
			var sub_a = ac + j*eb
			var sub_b = ac + (j + 1)*eb
			var sub_c = ac + j*eb + ec
			self.add_mesh_sphere_face(sub_a, sub_b, sub_c)
			if j < N - i:
				sub_a = ac + j*eb + ec
				sub_b = ac + (j + 1)*eb
				sub_c = ac + (j + 1)*eb + ec
				self.add_mesh_sphere_face(sub_a, sub_b, sub_c)

func add_mesh_sphere_face(
	a: Vector3, b: Vector3, c: Vector3,
	uv_a: Vector2 = Vector2.ZERO, 
	uv_b: Vector2 = Vector2.ZERO,
	uv_c: Vector2 = Vector2.ZERO
):
	a = a.normalized()
	b = b.normalized()
	c = c.normalized()
	# If a point is on the unit sphere, then it's
	# normal is just the point itself.
	self.add_mesh_face(
		a, b, c, a, b, c,
		uv_a, uv_b, uv_c
	)

func add_mesh_face(
	a: Vector3, b: Vector3, c: Vector3,
	normal_a: Vector3, normal_b: Vector3, normal_c: Vector3,
	uv_a: Vector2, uv_b: Vector2, uv_c: Vector2
):
	
	if not smooth:
		# If the surface is intended to be shaded flat, though
		# it's the normal of the face that is needed, not
		# the normal of each vertex individually.
		var face_normal = ((a + b + c) / 3).normalized()
		normal_a = face_normal
		normal_b = face_normal
		normal_c = face_normal
	
	# Vertex Data
	self.add_mesh_vertex(a, normal_a, uv_a)
	self.add_mesh_vertex(b, normal_b, uv_b)
	self.add_mesh_vertex(c, normal_c, uv_c)
	
	if not self.generating_texture:
		return
	
	# Texture
	var tex_size = Vector2(self.texture_size)
	var shape = PackedVector2Array()
	shape.resize(3)
	shape[0] = uv_a * tex_size
	shape[1] = uv_b * tex_size
	shape[2] = uv_c * tex_size
	self.texture_shapes.append(shape)
	var colors = PackedColorArray()
	colors.resize(3)
	colors[0] = self.texture_color_map.call(a, normal_a)
	colors[1] = self.texture_color_map.call(b, normal_b)
	colors[2] = self.texture_color_map.call(c, normal_c)
	self.texture_colors.append(colors)

func add_mesh_vertex(vertex: Vector3, normal: Vector3, uv: Vector2):
	surface_tool.set_uv(uv)
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(vertex)
	self.vertex_count += 1
