extends Node
class_name MyMath

const EPSILON_LINEAR_SPEED = 0.001
const EPSILON_WORLD_COORDS = 0.001

static func vec3_eq(a: Vector3, b: Vector3, eps: float):
	return abs(a.x - b.x) < eps and\
		abs(a.y - b.y) < eps and\
		abs(a.z - b.z) < eps
