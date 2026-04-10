extends Node

var key_codes = [
	[KEY_SPACE],
	[KEY_D, KEY_K],
	[KEY_D, KEY_SPACE, KEY_K],
	[KEY_S, KEY_D, KEY_K, KEY_L],
	[KEY_S, KEY_D, KEY_SPACE, KEY_K, KEY_L],
	[KEY_A, KEY_S, KEY_D, KEY_K, KEY_L, KEY_SEMICOLON],
	[KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_K, KEY_L, KEY_SEMICOLON],
]

@onready var playfield : Node3D = $"../Playfield";

func _process(delta: float) -> void:
	assert(len(key_codes) >= playfield.key_count)
	
	var key_press : int = 0
	var key_ind : int = 0
	for key in key_codes[playfield.key_count - 1]:
		if Input.is_key_pressed(key):
			key_press |= (1 << key_ind)
		key_ind += 1
		
	playfield.set_key_press(key_press)
