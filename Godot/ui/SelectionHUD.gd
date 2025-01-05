extends Node2D

@export var theme: MyTheme = MyTheme.new()

@export var radius: float = 100
@export var width: float = 2
@export var cutoff: float = 0.7
@export var point_count: int = 25
@export var border: float = 2
@export var arc_border: float = 0.025
@export var show_border: bool = false

@export var fader: Fader
@export var player: PlayerShip

@export var component_display: ComponentDisplay

var selection: Node3D
var selection_size: float
var previous_radius: float

func _draw():
	var arc_width = max(1.5, width * radius * 0.02)
	
	# Left arc
	var left_start = cutoff*PI
	var left_end = (2 - cutoff)*PI
	if show_border:
		draw_arc(
			Vector2.ZERO, radius, left_start - arc_border, left_end + arc_border, 
			point_count, Color.BLACK, arc_width + border, true
		)
	draw_arc(
		Vector2.ZERO, radius, left_start, left_end, 
		point_count, theme.selection_reticle, arc_width, true
	)
	
	# Right arc
	var right_start = (1 + cutoff)*PI
	var right_end = (3 - cutoff)*PI
	if show_border:
		draw_arc(
			Vector2.ZERO, radius, right_start - arc_border, right_end + arc_border, 
			point_count, Color.BLACK, arc_width + border, true
		)
	draw_arc(
		Vector2.ZERO, radius, right_start, right_end, 
		point_count, theme.selection_reticle, arc_width, true
	)
		
	# Center dot
	# Alas, these aren't anti-aliased, and look awful as a result.
	#draw_circle(Vector2.ZERO, center_width + 2, Color.BLACK)
	#draw_circle(Vector2.ZERO, center_width, color)
	
	# I'm not going with this at the moment.
	#if selection != null:
	#	var camera = get_viewport().get_camera_3d()
	#	var vel = player.linear_velocity - selection.linear_velocity
	#	const c = 15
	#	component_display.x_value = vel.dot(camera.transform.basis.x)/c
	#	component_display.y_value = vel.dot(camera.transform.basis.y)/c
	#
	#component_display.draw(self, Vector2.ZERO)

func get_screen_size(camera: Camera3D, size: float, world_pos: Vector3):
	return (
			camera.unproject_position(world_pos) -
			camera.unproject_position(world_pos + camera.transform.basis.x * size)
		).length()

func _process(_delta):
	var camera: Camera3D = get_viewport().get_camera_3d()
	if self.selection != null:
		if camera.is_position_in_frustum(self.selection.global_position):
			self.position = camera.unproject_position(self.selection.global_position)
			self.radius = get_screen_size(camera, self.selection_size, self.selection.global_position)/2
			if self.radius != self.previous_radius:
				self.queue_redraw()
				self.previous_radius = self.radius
			self.modulate.a = self.fader.get_alpha()
		else:
			self.modulate.a = 0
	else:
		self.modulate.a = self.fader.get_alpha()
		
func _on_asteroid_field_selection_changed(new_selection: Node3D):
	if new_selection == null:
		fader.fade_out()
		selection = null
	else:
		fader.fade_in()
		selection = new_selection
		# This seems inefficient...
		var collision_shape = selection.find_child("CollisionShape3D")
		selection_size = collision_shape\
			.shape.get_debug_mesh().get_aabb()\
			.get_longest_axis_size() * collision_shape.scale.length()
