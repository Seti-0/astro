extends Resource
class_name Fader

@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.4
@export var fade_inout_duration: float = 2.5

enum State {
	INVISIBLE,  # The initial hidden state.
	FADE_OUT,   # Fades out, then stays invisible.
	FADE_IN,    # Fades in, then stays visible.
	FADE_INOUT  # Fades in, then after a while fades out, then stays invisible.
}

var last_update: int
var state := State.INVISIBLE

func fade_in():
	if state != State.FADE_IN:
		state = State.FADE_IN
		last_update = Time.get_ticks_msec()

func fade_out():
	if state != State.FADE_OUT and state != State.INVISIBLE:
		state = State.FADE_OUT
		last_update = Time.get_ticks_msec()

func fade_inout():
	state = State.FADE_INOUT
	last_update = Time.get_ticks_msec()

func lerp01(x):
	return lerp(0, 1, clamp(x, 0, 1))

func lerp10(x):
	return lerp(1, 0, clamp(x, 0, 1))

func get_alpha():
	var t := (Time.get_ticks_msec() - last_update) / 1000.
	match state:
		State.FADE_IN: return lerp01(t/fade_in_duration)
		State.FADE_OUT: return lerp10(t/fade_out_duration)
		State.FADE_INOUT:
			var fade_in_a = lerp01(t/fade_in_duration)
			var fade_out_a = lerp01((fade_inout_duration - t)/fade_out_duration)
			return min(fade_in_a, fade_out_a)
		_: return 0
