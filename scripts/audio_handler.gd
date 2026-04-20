extends AudioStreamPlayer

@onready var sound_group = $"../Sounds"
var hit_sound : AudioStream = preload("res://sounds/hit.wav")
var miss_sound : AudioStream = preload("res://sounds/miss.wav")

const BPM : float = 222.0
var beat_length : float = (60.0 / BPM)

var start_pitch : float = 1.0

var is_finished : bool = false

func _ready() -> void:
	finished.connect(on_finished)
	volume_db = -25.0
	start_pitch = pitch_scale
	play(0.0)

func _process(_delta: float) -> void:
	pass
	
func sec_to_beat(sec : float) -> float:
	return sec / beat_length
	
func get_pos() -> float:
	if stream_paused:
		return get_playback_position()
		
	return get_playback_position() + AudioServer.get_time_since_last_mix() * pitch_scale
	
func get_cur_beat() -> float:
	return sec_to_beat(get_pos())

func on_finished() -> void:
	is_finished = true

func oneshot(sound_stream) -> void:
	var audio = AudioStreamPlayer.new()
	audio.volume_db = -25;
	audio.stream = sound_stream;
	audio.finished.connect(oneshot_finished.bind(audio))
	sound_group.add_child(audio)
	audio.play()
	
func oneshot_finished(sound_stream) -> void:
	sound_stream.queue_free()
