extends Resource
class_name ComponentDisplay

@export var theme: MyTheme = MyTheme.new()

@export var center_size: float = 10
@export var arrow_len: float = 90
@export var arrow_width: float = 6
@export var arrowhead_len: float = 14
@export var arrowhead_width: float = 14
@export var size_threshold: float = 4

@export var x_value: float
@export var y_value: float

func draw(instance: CanvasItem, pos: Vector2):

	var x_len = abs(clamp(x_value, -1., 1.) * arrow_len)
	var y_len = abs(clamp(y_value, -1., 1.) * arrow_len)
	
	if x_len < 2: x_len = 0
	if y_len < 2: y_len = 0
	
	var size_x = min(1, x_len/size_threshold)
	var size_y = min(1, y_len/size_threshold)

	# Center cube
	var center_x = pos.x + -center_size/2
	var center_y = pos.y + -center_size/2
	var center_w = center_size
	var center_h = center_size
	instance.draw_rect(Rect2(center_x, center_y, center_w, center_h), Color.WHITE)
	
	# Arrow shaft: X
	var x_color = theme.axis_red
	var x_arrow_x = center_x + (center_w if x_value > 0 else -x_len)
	var x_arrow_y = pos.y - size_x*arrow_width/2
	var x_arrow_w = x_len
	var x_arrow_h = size_x*arrow_width
	instance.draw_rect(Rect2(x_arrow_x, x_arrow_y, x_arrow_w, x_arrow_h), x_color)
	
	# Arrow shaft: Y
	var y_color = theme.axis_green
	var y_arrow_x = pos.x + -size_y*arrow_width/2
	var y_arrow_y = center_x + (center_w if y_value < 0 else -y_len)
	var y_arrow_w = size_y*arrow_width
	var y_arrow_h = y_len
	instance.draw_rect(Rect2(y_arrow_x, y_arrow_y, y_arrow_w, y_arrow_h), y_color)
	
	# Arrow tip: X
	var x_end = x_arrow_x + (0 if x_value < 0 else x_arrow_w)
	var x_sign = sign(x_value)
	instance.draw_colored_polygon([
		Vector2(x_end, -size_x*arrowhead_width/2),
		Vector2(x_end, size_x*arrowhead_width/2),
		Vector2(x_end + x_sign*size_x*arrowhead_len, 0)
	], x_color)

	# Arrow tip: Y
	var y_end = y_arrow_y + (0 if y_value > 0 else y_arrow_h)
	var y_sign = -sign(y_value)
	instance.draw_colored_polygon([
		Vector2(-size_y*arrowhead_width/2, y_end),
		Vector2(size_y*arrowhead_width/2, y_end),
		Vector2(0, y_end + y_sign*size_y*arrowhead_len)
	], y_color)
