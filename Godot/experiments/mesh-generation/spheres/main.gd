extends Node3D
	
@export var material: Material = null

var selected: Node3D = null

func _ready():
	if self.material != null:
		for item in find_children("*", "MeshInstance3D"):
			if "update_mesh" in item:
				item.gen_material = material
				item.gen_scale = 0.5
				item.update_mesh()

func set_selection(node: Node3D):
	var label = find_child("title") as Label
	label.text = "Selected: " + str(node.name)
	selected = node

func _on_rotatex_value_changed(value):
	if selected != null:
		selected.rotation.x = 2 * PI * float(value)/100


func _on_rotatey_value_changed(value):
	if selected != null:
		selected.rotation.y = 2 * PI * float(value)/100


func _on_scale_value_changed(value):
	if selected != null:
		selected.gen_scale = float(value)/100
		selected.update_mesh()

func _on_lighting_value_changed(value):
	find_child("DirectionalLight3D").light_energy = 0. + value/50.
