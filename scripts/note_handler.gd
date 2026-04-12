extends Node

#TODO: Judgement for each column? Too noisy?
#TODO: 1 mill score? Or higher for more satisfaction?
#TODO: How much info to display in middle of playfield vs. the side?
#TODO: Temporal feedback, as in how strict timings affect satisfaction

const SCROLL_SPEED : float = 18.0

@onready var audio_handler : Node = $AudioStreamPlayer
@onready var ui : Control = $UI
@onready var playfield : Node3D = $Playfield
@onready var note_group : Node3D = $Notes;

var map_loaded : bool = false
var note_scene : Resource = preload("res://scenes/note.tscn")
var hit_objects : Array;
var column_pressed : int = 0
var total_hits : int = 0
var hit_score : int = 0
var accuracy : float = 0

func _ready() -> void:
	assert(note_group != null)
	load_map()

func _process(delta : float) -> void:
	if not map_loaded:
		return
		
	check_note_spawns()
	
	#Update note positions and handle judgements.
	column_pressed = 0
	
	for column_ind in range(playfield.num_columns):
		var column = note_group.get_child(column_ind)
		
		for note in column.get_children():
			if not note.active:
				continue
				
			var note_pos = get_note_pos(note.time)
			note.position = Vector3(note.position.x, note.position.y, note_pos)
			
			if note_past_despawn_pos(note) and note.missed:
				note.active = false
				note.queue_free()
				#TODO: Check if held
				continue
			
			if note.pressed:
				if note.is_hold:
					handle_note_judgement_end(note)
				continue
			else:
				handle_note_judgement_start(note)

func load_map():
	map_loaded = false
	
	for column in note_group.get_children():
		column.queue_free()
	
	var map = MapParser.load_map("res://maps/Testify/void (Mournfinale) feat. Hoshikuma Minami - Testify (Kyousuke-) [Prologue].osu")
	#var map = MapParser.load_map("res://maps/Can You Hear Me/BEN - Can You Hear Me (Garalulu) [A World Between The Worlds].osu")
	#var map = MapParser.load_map("res://maps/Finixe/Silentroom - Finixe (shuniki) [YARANAIKA!!].osu")	

	InputHandler.key_count = map["key_count"]
	playfield.set_num_columns(map["key_count"])
		
	for column_ind in range(playfield.num_columns):
		var column = Node3D.new()
		column.name = str(column_ind)
		column.position = playfield.get_column_center(column_ind) * Vector3.LEFT
		note_group.add_child(column)
	
	hit_objects = map["hit_objects"]
	
	total_hits = 0
	hit_score = 0
	accuracy = 0.0
	
	check_note_spawns()
	map_loaded = true

func check_note_spawns() -> void:
	for column_ind in range(playfield.num_columns):
		var col_list = hit_objects[column_ind]
		
		while len(col_list) > 0:
			var obj = col_list[0]
			
			var time_delta = obj["start_time"] - audio_handler.get_playback_position()
			var note_pos = get_note_pos(obj["start_time"])
			
			if note_pos > playfield.FIELD_SPAWN_POS and time_delta > Judge.SEC[Judge.BAD]:
				break
				
			col_list.pop_front()
			
			var miss_start = false
			var miss_end = false
			
			if time_delta < -Judge.SEC[Judge.BAD]:
				miss_start = true
				
			var is_hold = (obj["time_length"] > 0)
			if is_hold:
				var end_time = obj["start_time"] + obj["time_length"]
				if (end_time - audio_handler.get_playback_position()) < -Judge.SEC[Judge.BAD]:
					miss_end = true
					
			if miss_start:
				add_hit(Judge.MISS)
				
			if miss_end:
				add_hit(Judge.MISS)
			
			if not miss_start or (not miss_end and is_hold):
				spawn_note_at(obj["column"], obj["start_time"], obj["time_length"])
	
	ui.spawned_notes = 0
	for column in note_group.get_children():
		ui.spawned_notes += column.get_child_count()

func get_note_pos(time : float) -> float:
	return (time - audio_handler.get_playback_position()) * SCROLL_SPEED + playfield.RECEPTOR_OFFSET

func get_note_end_point(start_time : float, time_length : float = -1) -> float:
	if time_length <= 0.0:
		return get_note_pos(start_time) + NoteInfo.NOTE_BASE_LENGTH
	return get_note_pos(start_time + time_length)
	
func note_past_despawn_pos(note) -> bool:
	return get_note_end_point(note.time, note.length) <= playfield.FIELD_DESPAWN_POS

func spawn_note_at(column_ind : int, start_time : float, time_length : float = -1) -> void:
	assert(column_ind >= 0 && column_ind < playfield.num_columns)
	
	var note_pos = get_note_pos(start_time)
	var hold_length = 0.0
	
	var is_hold = false
	
	if time_length > 0.0:
		is_hold = true
		hold_length = (time_length * SCROLL_SPEED)
	
	var note = note_scene.instantiate();
	note.position = (note_pos * Vector3.BACK)
	note.init(column_ind, start_time, time_length, is_hold, hold_length)
	note_group.get_child(column_ind).add_child(note)

func handle_note_judgement_start(note) -> void:
	assert(note.active)
	assert(not note.pressed)
	
	#TODO
	var start_delta = note.time - audio_handler.get_playback_position()
		
	var miss_start = (start_delta < -Judge.SEC[Judge.BAD])
	#var miss_end = (note.is_hold and end_delta < -Judge.SEC[Judge.BAD])
	
	#Miss
	if miss_start:
		note.set_pressed()
		note.set_missed()
		ui.set_judge(Judge.MISS)
		add_hit(Judge.MISS)
		return

	if column_pressed & (1 << note.column):
		return

	if InputHandler.is_column_pressed(note.column) and abs(start_delta) <= Judge.SEC[Judge.BAD]:
		column_pressed |= (1 << note.column)
		note.set_pressed()
		
		if not note.is_hold:
			note.queue_free()
		else:
			note.set_holding(true)
		
		note_hit(start_delta)

func handle_note_judgement_end(note) -> void:
	assert(note.active)
	assert(note.pressed)
	assert(note.is_hold)
	
	var end_delta = (note.time + note.length) - audio_handler.get_playback_position()
	#if end_delta < -Judge.SEC[Judge.BAD]:
		

func note_hit(time_delta : float) -> void:
	var judge = Judge.time_to_judgement(abs(time_delta))
	assert(judge != Judge.MISS)
	ui.set_judge(judge)
	add_hit(judge)
	
func add_hit(judge) -> void:
	total_hits += 1
	hit_score += Judge.SCORE[judge]
	accuracy = float(hit_score) / float(Judge.SCORE[Judge.PERFECT] * total_hits)
	ui.set_accuracy(accuracy)
