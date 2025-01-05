@tool
extends SphereTestItem

@export var smooth = false:
	set(val):
		smooth = val
		update_mesh()

var ico_vertices = PackedVector3Array()

func get_uv(vertex: Vector3):
	var u = atan2(vertex.y, vertex.x) / (2.*PI)
	var v = 0.5 + asin(vertex.z)/PI
	return Vector2(u, v)

func add_ico_face(a: Vector3, b: Vector3, c: Vector3):
	ico_vertices.append(a)
	ico_vertices.append(b)
	ico_vertices.append(c)

func add_mesh_face(a: Vector3, b: Vector3, c: Vector3):
	a = a.normalized()
	b = b.normalized()
	c = c.normalized()
	
	var normal_a: Vector3
	var normal_b: Vector3
	var normal_c: Vector3
	if not smooth:
		var face_normal = ((a + b + c) / 3).normalized()
		normal_a = face_normal
		normal_b = face_normal
		normal_c = face_normal
	else:
		normal_a = a
		normal_b = b
		normal_c = c
	
	add_vertex(a, get_uv(a), normal_a)
	add_vertex(b, get_uv(b), normal_b)
	add_vertex(c, get_uv(c), normal_c)

func subdivide_face_and_add(a: Vector3, b: Vector3, c: Vector3):
	var N = int(gen_scale * 5)
	var eb = (b - a) / (N + 1)
	var ec = (c - a) / (N + 1)
	for i in range(N + 1):
		var ac = a + i*ec
		for j in range(N + 1 - i):
			var sub_a = ac + j*eb
			var sub_b = ac + (j + 1)*eb
			var sub_c = ac + j*eb + ec
			add_mesh_face(sub_a, sub_b, sub_c)
			if j < N - i:
				sub_a = ac + j*eb + ec
				sub_b = ac + (j + 1)*eb
				sub_c = ac + (j + 1)*eb + ec
				add_mesh_face(sub_a, sub_b, sub_c)

func on_mesh_update():
	
	ico_vertices.clear()
	
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
	subdivide_face_and_add(v1 , v2 , v10)
	subdivide_face_and_add(v2 , v7 , v10)
	subdivide_face_and_add(v7 , v11, v10)
	subdivide_face_and_add(v11, v8 , v10)
	subdivide_face_and_add(v8 , v1 , v10)
	
	# Around vertex 12, on the opposite side.
	subdivide_face_and_add(v3 , v6 , v12)
	subdivide_face_and_add(v6 , v9 , v12) 
	subdivide_face_and_add(v9 , v5 , v12)
	subdivide_face_and_add(v5 , v4 , v12)
	subdivide_face_and_add(v4 , v3 , v12)
	
	# The middle between the above two segments.
	subdivide_face_and_add(v9 , v2 , v1 )
	subdivide_face_and_add(v2 , v9 , v6 )
	subdivide_face_and_add(v6 , v7 , v2 )
	subdivide_face_and_add(v7 , v6 , v3 )
	subdivide_face_and_add(v3 , v11, v7 )
	subdivide_face_and_add(v11, v3 , v4 )
	subdivide_face_and_add(v4 , v8 , v11)
	subdivide_face_and_add(v8 , v4 , v5 )
	subdivide_face_and_add(v5 , v1 , v8 )
	subdivide_face_and_add(v1,  v5 , v9 )
