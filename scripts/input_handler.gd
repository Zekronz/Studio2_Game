extends Node

const MAX_SUPPORTED_KEY_COUNT : int = 7
var key_count : int = 4

const KEY_CODES : Array = [
	[KEY_SPACE],
	[KEY_D, KEY_K],
	[KEY_D, KEY_SPACE, KEY_K],
	[KEY_S, KEY_D, KEY_K, KEY_L],
	[KEY_S, KEY_D, KEY_SPACE, KEY_K, KEY_L],
	[KEY_A, KEY_S, KEY_D, KEY_K, KEY_L, KEY_SEMICOLON],
	[KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_K, KEY_L, KEY_QUOTELEFT],
]

var key_down : int = 0
var key_pressed : int = 0

func _process(_delta: float) -> void:
	key_pressed = 0
	
	for i in key_count:
		var key_code = KEY_CODES[key_count - 1][i]
		
		if Input.is_key_pressed(key_code) and not (key_down & (1 << i)):
			key_down |= (1 << i)
			key_pressed |= (1 << i)
			
		elif not Input.is_key_pressed(key_code) and (key_down & (1 << i)):
			key_down &= ~(1 << i);
	
func is_column_down(column_ind : int) -> bool:
	assert(column_ind >= 0 && column_ind < MAX_SUPPORTED_KEY_COUNT)
	return (key_down & (1 << column_ind))

func is_column_pressed(column_ind : int) -> bool:
	assert(column_ind >= 0 && column_ind < MAX_SUPPORTED_KEY_COUNT)
	return (key_pressed & (1 << column_ind))
