extends AudioStreamPlayer

const BPM : float = 222.0

var beat_length : float = (60.0 / BPM)

func _ready() -> void:
	self.volume_db = -15.0
	self.play(2.5)

func _process(delta: float) -> void:
	pass
	
func sec_to_beat(sec : float) -> float:
	return sec / beat_length
	
func get_cur_beat() -> float:
	return sec_to_beat(self.get_playback_position())
