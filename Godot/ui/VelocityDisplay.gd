extends Node2D
class_name VelocityDisplay

@export var display: ComponentDisplay

func _ready():
	self.queue_redraw()

func _draw():
	display.draw(self, Vector2.ZERO)
