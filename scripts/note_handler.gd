extends Node

const SCROLL_SPEED : float = 5.0
const NUM_LANES : int = 4

const NOTE_WIDTH : float = 1.0
const COL_START : float = -(float(NUM_LANES) / 2.0 * NOTE_WIDTH) + ((NOTE_WIDTH / 2.0) * float(NUM_LANES % 1 == 0))

@onready var audio_handler : Node = $AudioStreamPlayer
@onready var note_group : Node3D = $Notes;
var note_scene : Resource = preload("res://scenes/note.tscn")

func _ready() -> void:
	assert(note_group != null)

func _process(delta : float) -> void:
	for note in note_group.get_children():
		var beat_pos = get_note_pos(note.beat, audio_handler.get_playback_position())
		note.position = Vector3(note.position.x, note.position.y, beat_pos)

func get_note_pos(beat : float, playback_pos : float = 0.0) -> float:
	return (beat - audio_handler.sec_to_beat(playback_pos)) * SCROLL_SPEED

func spawn_note_at(lane : int, beat : float) -> void:
	assert(lane >= 0 && lane < NUM_LANES)
	
	var col_pos = COL_START + (float(lane) * NOTE_WIDTH)
	var beat_pos = get_note_pos(beat, audio_handler.get_playback_position())
	
	var note = note_scene.instantiate();
	note.beat = beat
	note.position = (col_pos * Vector3.LEFT) + (beat_pos * Vector3.BACK)
	note_group.add_child(note)
