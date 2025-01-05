extends Node3D

@export var info_display: InfoLabel

func _unhandled_input(event: InputEvent):
	if event.is_action_released("Pause"):
		var tree = get_tree()
		tree.paused = !tree.paused
		if tree.paused:
			info_display.show_message("Game paused")
		else:
			info_display.show_message("Game unpaused")
