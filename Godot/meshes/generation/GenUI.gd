extends Control

signal prop_changed(src: Object, prop_name: String, val)

var has_generator: bool
var generator_node: MeshInstance3D
var generator_resource: MeshGenUtil
var rotate_subject: bool

@export var vertex_count_label: Label

func _ready():
	find_generator(get_tree().root)
	self.update_vertex_count()

func _process(delta):
	if self.has_generator and self.rotate_subject:
		self.generator_node.rotate_y(delta * PI * 0.25)

func _on_button_pressed():
	PropertyEditor.add_editor(self, self.generator_node)

func find_generator(node: Node):

	if node is MeshInstance3D:
		if "generator" in node and node.generator is MeshGenUtil:
			connect_to_generator(node)
			return
	
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		find_generator(child)

func connect_to_generator(node: MeshInstance3D):
	self.generator_node = node
	self.generator_resource = node.generator
	self.has_generator = true
	self.generator_resource.connect("commit", func():
		self.update_vertex_count()
	)

func update_vertex_count():
	if has_generator:
		var count = self.generator_resource.vertex_count
		self.vertex_count_label.text = "Vertex count: %d" % count

#############################################
# Bottom Left UI: Mesh Density and Rotation #
#############################################

func get_rotation_slider01(val: int):
	# This formula depends on the min/max/value settings 
	# of the slider. In this case, for a 0-100 slider, 0.5
	# is mapped to 0.
	return ((val + 50) % 100) / 100.

func _on_scale_slider_value_changed(value):
	if has_generator:
		generator_resource.gen_scale = value / 100.
		generator_node.update()

func _on_x_slider_value_changed(value):
	if has_generator:
		generator_node.rotation.x = get_rotation_slider01(value) * 2 * PI

func _on_y_slider_value_changed(value):
	if has_generator:
		generator_node.rotation.y = get_rotation_slider01(value) * 2 * PI
	
func _on_z_slider_value_changed(value):
	if has_generator:
		generator_node.rotation.z = get_rotation_slider01(value) * 2 * PI

func _on_rotate_check_toggled(_button_pressed):
	self.rotate_subject = !self.rotate_subject
