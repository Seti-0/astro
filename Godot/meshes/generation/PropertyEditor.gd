extends PanelContainer
class_name PropertyEditor

#################################
# TODO: Add Color Picker Editor #
#################################
# This easier said then done - either a new window needs to be made (with
# dragging and the close button, and preferably DRY) or a popup menu &
# button is needed. 

static func add_editor(parent: Node, target: Object) -> PropertyEditor:
	# This can be made a preload, but not without separating this method
	# into a different class from this one I think. Else there is a cyclical
	# resource inclusion - compiling this method requires preparing a scene
	# which requires compiling this scripts which requires compiling this
	# method, and so on.
	var scene = load("res://meshes/generation/PropertyEditor.tscn")
	var instance: PropertyEditor = scene.instantiate()
	parent.add_child.call_deferred(instance)
	instance.set_target(target)
	return instance

@export var properties_container: Control
@export var centered_view: Control
@export var center_separator: Control
@export var title_label: Label
@export var scroll_container: ScrollContainer

var target_obj: Object

func _ready():
	if self.target_obj == null:
		self.set_target(Ship.new())

func _on_close_button_pressed():
	self.queue_free()

#######################
# Draggable Behaviour #
#######################

var dragging: bool = false
var drag_candidate: bool = false
var drag_offset: Vector2

func _input(event):
	
	if self.drag_candidate:
		self.dragging = true
		self.drag_candidate = false
		self.drag_offset = self.get_local_mouse_position()
	
	if self.dragging:
		if event is InputEventMouseMotion:
			self.global_position = event.position - self.drag_offset
		elif event is InputEventMouseButton and not event.is_pressed():
			self.global_position = event.position - self.drag_offset
			self.dragging = false

func _on_drag_panel_gui_input(event):
	
	if event.is_echo():
		return

	if event is InputEventMouseButton and event.is_pressed():
		if not self.dragging:
			self.drag_candidate = true

####################
# Property Editing #
####################

var ignore_properties = [
	"editor_description",
	"resource_name",
	"resource_path",
	"resource_local_to_scene"
]

var ignore_groups = [
	"Resource"
]

var current_group_name: String

func set_target(obj: Object):
	self.target_obj = obj
	self.refresh_property_editors()

func refresh_property_editors():
	
	if target_obj == null:
		push_error("Null target object set for property editor.")
		PropertyEditor.clear_nodes(properties_container)
		PropertyEditor.clear_nodes(centered_view)
		title_label.text = "(Target is null)"
		return
	
	if properties_container == null:
		return
	
	title_label.text = type_str(target_obj)
	
	var obj = self.target_obj
	PropertyEditor.clear_nodes(self.centered_view)
	if obj is Noise:
		var noise_tex = NoiseTexture2D.new()
		noise_tex.noise = obj
		noise_tex.width = 200
		noise_tex.height = 200
		var tex_view = TextureRect.new()
		tex_view.texture = noise_tex
		tex_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		self.centered_view.add_child(tex_view)
		self.centered_view.show()
		self.center_separator.show()
	else:
		self.centered_view.hide()
		self.center_separator.hide()
	
	PropertyEditor.clear_nodes(self.properties_container)
	
	if target_obj.has_method("get_actions_hint"):
		var actions = target_obj.get_actions_hint()
		self.add_group_title("Custom Actions")
		for method in target_obj.get_method_list():
			if method["name"] in actions:
				self.add_action(method)
				self.add_separator()
	
	var target_props = self.target_obj.get_property_list()
	for group in sort_property_list(target_props):
		
		var group_name: String = group["name"]
		var group_props: Array = group["props"]
		
		if group_props.size() == 0:
			continue
		
		if group_name not in self.ignore_groups:
			self.add_group_title(group_name)
		
		for prop in group_props:
			var editor_added: bool = self.add_property_editor(prop)
			if editor_added:
				self.add_separator()
	
	self.scroll_container.custom_minimum_size = Vector2(300, 230)

func sort_property_list(property_list: Array) -> Array:
	
	# First, group by source type.
	# This is given as the "category" in the property list.
	
	var categories = Array()
	var category_props = Array()
	categories.append({
		"name": "(Misc)",
		"props": category_props
	})
	
	for prop in property_list:
		if prop["usage"] & PROPERTY_USAGE_CATEGORY != 0:
			category_props = Array()
			categories.append({
				"name": prop["name"],
				"props": category_props
			})
		else:
			category_props.append(prop)
	
	# The categories in descending order with the furthest ancestor first,
	# the opposite of that is needed here.
	categories.reverse()
	
	# Now that the category order is reversed, expand out groups.
	
	var groups = Array()
	var group_props: Array
	
	for category in categories:
		var cat_name =  category["name"]
		var cat_props = category["props"]
		group_props = Array()
		groups.append({
			"name": cat_name,
			"props": group_props
		})
		for prop in cat_props:
			if prop["usage"] & PROPERTY_USAGE_GROUP != 0:
				group_props = Array()
				groups.append({
					"name": prop["name"],
					"props": group_props
				})
			elif prop["usage"] & PROPERTY_USAGE_EDITOR != 0:
				if prop["name"] not in ignore_properties:
					group_props.append(prop)
	
	return groups

static func clear_nodes(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func add_separator():
	var separator = Panel.new()
	separator.custom_minimum_size = Vector2(0, 1)
	self.properties_container.add_child(separator)

func add_group_title(title: String):

	var style = StyleBoxFlat.new()
	style.bg_color = Color("2a2a2a")
	style.content_margin_left = 10
	style.content_margin_right = 40
	style.emit_changed()
	
	var label = Label.new()
	label.add_theme_stylebox_override("normal", style)
	self.properties_container.add_child(label)
	label.custom_minimum_size.x = 280
	label.text = title

func add_property_editor(prop) -> bool:
	
	var prop_name = prop["name"]		
	var val = self.target_obj[prop_name]
	
	if val is Object:
		self.add_obj_editor(prop)
	elif val is NodePath:
		return false
	elif val == null:
		return false
	elif val is bool:
		self.add_boolean_editor(prop)
	elif val is int or val is float:
		if prop["hint"] & PROPERTY_HINT_ENUM != 0:
			self.add_int_enum_editor(prop)
		else:
			self.add_numeric_editor(prop)
	elif val is Vector3:
		self.add_vec3_editor(prop)
	else:
		const template = "I don't know how to create an editor" +\
			" for '%s' (%s) (property %s on obj %s)"
		print(template % [val, type_str(val), prop_name, self.target_obj])
		return false
	
	return true

func add_action(method):
	var method_name = method["name"]
	var action_button = Button.new()
	action_button.text = method_name + "()"
	action_button.connect("pressed", func():
		self.target_obj.call(method_name)
	)
	var container = HBoxContainer.new()
	container.add_child(action_button)
	self.properties_container.add_child(container)

func add_obj_editor(prop):
	var prop_name = prop["name"]
	var val = self.target_obj[prop_name]
	var open_editor = Button.new()
	open_editor.text = "Edit"
	open_editor.connect("pressed", func(): 
		PropertyEditor.add_editor(self.get_parent(), val)
	)
	self.add_named_editor(open_editor, prop_name)

func add_boolean_editor(prop):
	var prop_name = prop["name"]
	var val: bool = self.target_obj[prop_name]
	var editor = OptionButton.new()
	editor.add_item("false")
	editor.add_item("true")
	if val:
		editor.select(1)
	else:
		editor.select(0)
	editor.connect("item_selected", func(val: int):
		if val == 1:
			self.on_set_prop(prop_name, true)
		else:
			self.on_set_prop(prop_name, false)
			
		# Currently this deletes all editors and rebuilds them from
		# scratch, which is obviously not great, hence my just triggering
		# it after an enum/bool change. At some point I might want to make the
		# refresh incremental, and do this after every change of any property.
		# The reason for this is that changing a value can reveal or hide 
		# groups, or cause other values to be recomputed.
		refresh_property_editors()
	)
	self.add_named_editor(editor, prop_name)

func add_int_enum_editor(prop):
	var prop_name = prop["name"]
	var val = self.target_obj[prop_name]
	var enum_values = prop["hint_string"].split(",")
	var editor = OptionButton.new()
	for enum_val in enum_values:
		editor.add_item(enum_val)
	editor.select(clamp(val, 0, enum_values.size() - 1))
	editor.connect("item_selected", func(val: int):
		on_set_prop(prop_name, val)
		refresh_property_editors()
	)
	self.add_named_editor(editor, prop_name)

func add_numeric_editor(prop):
	var prop_name = prop["name"]
	var val = self.target_obj[prop_name]
	var is_integral = val is int
	if prop["hint"] & PROPERTY_HINT_RANGE != 0:
		var hint_tokens = (prop["hint_string"] as String).split_floats(",")
		var slider = HSlider.new()
		slider.min_value = hint_tokens[0]
		slider.max_value = hint_tokens[1]
		slider.step = 1. if is_integral else 0.001
		slider.value = val
		if hint_tokens.size() > 2:
			slider.step = hint_tokens[2]
		var spinner = SpinBox.new()
		spinner.min_value = slider.min_value
		spinner.max_value = slider.max_value
		spinner.step = slider.step
		spinner.value = val
		var combo = VBoxContainer.new()
		combo.add_child(spinner)
		combo.add_child(slider)
		var label = self.add_named_editor(combo, prop_name)
		var on_change = func(new_val: float):
			on_set_prop(prop_name, new_val)
			slider.value = new_val
			spinner.value = new_val
		slider.connect("value_changed", on_change)
		spinner.connect("value_changed", on_change)
		label.update_minimum_size()
		slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = max(60, 250 - label.get_combined_minimum_size().x)
	else:
		var spinner = SpinBox.new()
		spinner.min_value = -10000
		spinner.max_value = 10000
		spinner.step = 1. if is_integral else 0.001
		spinner.value = val
		add_named_editor(spinner, prop_name)
		spinner.connect("value_changed", func(new_val: float):
			on_set_prop(prop_name, new_val)
		)

func add_vec3_editor(prop):
	var prop_name = prop["name"]
	var val = self.target_obj[prop_name]
	var name_label = Label.new()
	name_label.text = editor_name(prop_name)
	var x_label = Label.new()
	var y_label = Label.new()
	var z_label = Label.new()
	x_label.text = "x"
	y_label.text = "y"
	z_label.text = "z"
	var x_editor = SpinBox.new()
	var y_editor = SpinBox.new()
	var z_editor = SpinBox.new()
	x_editor.value = val.x
	y_editor.value = val.y
	z_editor.value = val.z
	x_editor.connect("value_changed", func(new_x: float):
		on_set_prop(prop_name, Vector3(new_x, val.y, val.z))
	)
	y_editor.connect("value_changed", func(new_y: float):
		on_set_prop(prop_name, Vector3(val.x, new_y, val.z))
	)
	z_editor.connect("value_changed", func(new_z: float):
		on_set_prop(prop_name, Vector3(val.x, val.y, new_z))
	)
	var editor_row = HBoxContainer.new()
	editor_row.add_child(x_label)
	editor_row.add_child(x_editor)
	editor_row.add_child(y_label)
	editor_row.add_child(y_editor)
	editor_row.add_child(z_label)
	editor_row.add_child(z_editor)
	properties_container.add_child(name_label)
	properties_container.add_child(editor_row)

func on_set_prop(prop_name: String, val):
	print("Setting %s to %s on %s" % [prop_name, str(val), str(self.target_obj)])
	self.target_obj[prop_name] = val

func add_named_editor(editor: Control, prop_name: String) -> Label:
	var label := Label.new()
	label.text = editor_name(prop_name) + ": "
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	var named_editor = HBoxContainer.new()
	named_editor.add_child(label)
	named_editor.add_child(editor)
	self.properties_container.add_child(named_editor)
	return label

func editor_name(prop_name: String) -> String:
	var result = prop_name.capitalize()
	var group = current_group_name
	if result.begins_with(group):
		result = result.substr(group.length())
	return result

func type_str(val):
	
	if typeof(val) == TYPE_OBJECT:
		var cls_name = val.get_class()
		var script = val.get_script()
		if script != null:
			return self.get_script_name(script) + " (" + cls_name + ")"		
		return cls_name
	
	# I'm not listing all types here, I'll add more
	# if I need to later.
	match(typeof(val)):
		# Basics
		TYPE_NIL: return "nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "string"
		# Vectors
		TYPE_VECTOR2: return "vec2"
		TYPE_VECTOR3: return "vec3"
		TYPE_VECTOR4: return "vec4"
		# Misc
		TYPE_COLOR: return "color"
	
	return str(typeof(val))

func get_script_name(script: Script):
	return get_filename(script.resource_path)

func get_filename(path: String):
	var start: int = 0
	var end: int = 0
	var found_end := false
	for i in range(path.length()):
		if path[i] == "/":
			start = i + 1
			found_end = false
		elif path[i] == ".":
			end = i
			found_end = true
	if not found_end:
		end = path.length()
	return path.substr(start, end - start)
