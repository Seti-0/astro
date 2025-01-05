extends Node3D

func unpack(items):
	var result = []
	unpack_to_target(items, result)
	return result

func unpack_to_target(source, target):
	for item in source:
		if item is Array:
			unpack_to_target(item, target)
		else:
			target.append(item)

func _ready():
	print(unpack([[[1, 2], 3], 4]))
