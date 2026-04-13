extends AudioStreamPlayer

const BPM : float = 222.0
var beat_length : float = (60.0 / BPM)

var is_finished : bool = false

func _ready() -> void:
	finished.connect(on_finished)
	volume_db = -25.0
	play(0)

func _process(delta: float) -> void:
	pass
	
func sec_to_beat(sec : float) -> float:
	return sec / beat_length
	
func get_pos() -> float:
	return get_playback_position() + AudioServer.get_time_since_last_mix()
	
func get_cur_beat() -> float:
	return sec_to_beat(get_pos())

func on_finished() -> void:
	is_finished = true
