extends Node

const SCROLL_SPEED : float = 20.0
var key_count : int = 0

const NOTE_WIDTH : float = 0.96
const NOTE_HEIGHT : float = 0.2
const NOTE_BASE_LENGTH : float = 0.5

const COLUMN_WIDTH : float = 1
var column_start : float = 0.0
#const COLUMN_START : float = -(float(NUM_LANES) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(NUM_LANES % 1 == 0))

@onready var audio_handler : Node = $AudioStreamPlayer
@onready var note_group : Node3D = $Notes;
var note_scene : Resource = preload("res://scenes/note.tscn")

func _ready() -> void:
	assert(note_group != null)
	
	var map = MapParser.load_map("res://maps/Testify/void (Mournfinale) feat. Hoshikuma Minami - Testify (Kyousuke-) [Fatalism].osu")
	
	key_count = map["key_count"]
	column_start = -(float(key_count) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(key_count % 1 == 0))
	
	for obj in map["hit_objects"]:
		spawn_note_at(obj["column"], obj["start_time"], obj["end_time"])

func _process(delta : float) -> void:
	for note in note_group.get_children():
		var note_pos = get_note_pos(note.time, audio_handler.get_playback_position())
		note.position = Vector3(note.position.x, note.position.y, note_pos)

func get_note_pos(time : float, offset : float = 0.0) -> float:
	return (time - offset) * SCROLL_SPEED

func spawn_note_at(lane : int, start_time : float, end_time : float = -1) -> void:
	assert(lane >= 0 && lane < key_count)
	
	var col_pos = column_start + (float(lane) * COLUMN_WIDTH)
	var note_pos = get_note_pos(start_time, audio_handler.get_playback_position())
	var note_length = NOTE_BASE_LENGTH
	
	var is_hold = false
	var time_length = 0.0
	
	if end_time > 0.0:
		is_hold = true
		
		time_length = end_time - start_time
		assert(time_length > 0.0)
		
		note_length = (time_length * SCROLL_SPEED) / NOTE_BASE_LENGTH
	
	var note = note_scene.instantiate();
	note.time = start_time
	note.length = time_length
	note.is_hold = is_hold
	note.position = (col_pos * Vector3.LEFT) + (note_pos * Vector3.BACK)
	note.scale = Vector3(NOTE_WIDTH, NOTE_HEIGHT, note_length)
	note_group.add_child(note)
