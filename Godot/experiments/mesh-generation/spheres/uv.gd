@tool
extends SphereTestItem

func on_mesh_update():
	
	const R = 1
	var uv = PackedVector2Array()
	var vertices = PackedVector3Array()
	
	# First, append the poles.
	
	const north_vertex = Vector3(0, R, 0)
	const north_uv = Vector2(0, 0)
	const south_vertex = Vector3(0, -R, 0)
	const south_uv = Vector2(0, 0)
	
	# Next, everything else.
	# alpha is the latitude, beta is the longitude.
	# Note that alpha goes accross PI*[1/N, (N-1)/N], it doesn't include the polls
	# that have already been added.
	# beta goes from 0 to 2*PI*(N-1)/N, there are no overlapping points.
	
	var N = int(max(5, gen_scale*20))
	
	for i in range(1, N):
		var alpha = (float(i)/N) * PI
		for j in range(0, N):
			var beta = (float(j)/N) * 2 * PI
			
			var u = cos(alpha) * cos(beta)
			var v = cos(alpha) * sin(beta)
			uv.append(Vector2(u, v))
		
			var x = R * sin(alpha) * cos(beta)
			var y = R * cos(alpha)
			var z = R * sin(alpha) * sin(beta)
			vertices.append(Vector3(x, y, z))
	
	var RED = Color(1., 0., 0.)
	var BLUE = Color(1., 0., 0.)
	var color = RED
	
	var add_face = func(
		vertex_a, uv_a,
		vertex_b, uv_b,
		vertex_c, uv_c
	):
		surface_tool.set_color(color)
		var normal = ((vertex_a + vertex_b + vertex_c) / 3).normalized()
		surface_tool.set_normal(normal)
		surface_tool.set_uv(uv_a)
		surface_tool.add_vertex(vertex_a)
		surface_tool.set_normal(normal)
		surface_tool.set_uv(uv_b)
		surface_tool.add_vertex(vertex_b)
		surface_tool.set_normal(normal)
		surface_tool.set_uv(uv_c)
		surface_tool.add_vertex(vertex_c)
		
	var add_face_i = func(index_a, index_b, index_c):
		add_face.call(
			vertices[index_a], uv[index_a],
			vertices[index_b], uv[index_b],
			vertices[index_c], uv[index_c]
		)
		
		
	
	for i in range(N):
		var index_b = i
		var index_c = (i + 1) % N
		add_face.call(
			north_vertex, north_uv,
			vertices[index_b], uv[index_b],
			vertices[index_c], uv[index_c]
		)
	
	for i in range(0, N-2):
		for j in range(N):
			color = RED.lerp(BLUE, float(i)/N)
			add_face_i.call(
				i*N + j,
				(i+1)*N + j,
				(i+1)*N + ((j+1) % N)
			)
			add_face_i.call(
				i*N + j,
				(i+1)*N + ((j+1) % N),
				i*N + ((j+1) % N)
			)
	
	for i in range(N):
		var index_a = (N-2)*N + ((i+1) % N)
		var index_b = (N-2)*N + i
		add_face.call(
			vertices[index_a], uv[index_a],
			vertices[index_b], uv[index_b],
			south_vertex, south_uv
		)
