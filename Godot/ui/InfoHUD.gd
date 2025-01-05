extends Label
class_name InfoLabel

@export var fader: Fader

func _ready():
	self.modulate.a = 0

func show_message(msg_text: String):
	self.text = msg_text
	fader.fade_inout()

func _process(_delta):
	self.modulate.a = fader.get_alpha()
