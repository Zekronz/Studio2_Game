extends Node

const SCROLL_SPEED : float = 15.0

@onready var audio_handler : Node = $AudioStreamPlayer
@onready var playfield : Node3D = $Playfield
@onready var note_group : Node3D = $Notes;
var note_scene : Resource = preload("res://scenes/note.tscn")

func _ready() -> void:
	assert(note_group != null)
	
	#var map = MapParser.load_map("res://maps/Testify/void (Mournfinale) feat. Hoshikuma Minami - Testify (Kyousuke-) [Fatalism].osu")
	var map = MapParser.load_map("res://maps/Finixe/Silentroom - Finixe (shuniki) [ShuChan!!].osu")
	
	playfield.set_key_count(map["key_count"])
	
	for obj in map["hit_objects"]:
		spawn_note_at(obj["column"], obj["start_time"], obj["end_time"])
		
	#spawn_note_at(0, 0)

func _process(delta : float) -> void:
	for note in note_group.get_children():
		var note_pos = get_note_pos(note.time, audio_handler.get_playback_position())
		note.position = Vector3(note.position.x, note.position.y, note_pos)

func get_note_pos(time : float, offset : float = 0.0) -> float:
	return (time - offset) * SCROLL_SPEED + playfield.RECEPTOR_OFFSET

func spawn_note_at(column : int, start_time : float, end_time : float = -1) -> void:
	assert(column >= 0 && column < playfield.key_count)
	
	var note_pos = get_note_pos(start_time, audio_handler.get_playback_position())
	var hold_length = 0.0
	
	var is_hold = false
	var time_length = 0.0
	
	if end_time > 0.0:
		is_hold = true
		
		time_length = end_time - start_time
		assert(time_length > 0.0)
		
		hold_length = (time_length * SCROLL_SPEED)
	
	var note = note_scene.instantiate();
	note.position = (playfield.get_column_center(column) * Vector3.LEFT) + (note_pos * Vector3.BACK)
	note.init(start_time, time_length, is_hold, hold_length)
	note_group.add_child(note)
