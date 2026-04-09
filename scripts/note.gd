extends Node3D

const NOTE_WIDTH : float = 0.8
const NOTE_HEIGHT : float = 0.07
const NOTE_BASE_LENGTH : float = 0.4

const HOLD_WIDTH : float = 0.7
const HOLD_HEIGHT : float = NOTE_HEIGHT - 0.06

var time : float = 0
var length : float = 0
var is_hold : bool = false

var main : Node3D
var hold : Node3D

func init(n_time : float, n_length : float, n_is_hold : bool, hold_length) -> void:
	main = $Main
	hold = $Hold
	
	time = n_time
	length = n_length
	is_hold = n_is_hold
	
	main.scale = Vector3(NOTE_WIDTH, NOTE_HEIGHT, NOTE_BASE_LENGTH)
	
	if is_hold:
		hold.visible = true
		hold.scale = Vector3(HOLD_WIDTH, HOLD_HEIGHT, hold_length)
	
func get_end_point() -> float:
	if not is_hold:
		return position.z + NOTE_BASE_LENGTH
		
	return position.z + hold.scale.z
