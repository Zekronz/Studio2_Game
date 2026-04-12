extends Node

#TODO: Judgement for each column? Too noisy?
#TODO: 1 mill score? Or higher for more satisfaction?
#TODO: How much info to display in middle of playfield vs. the side?
#TODO: Temporal feedback, as in how strict timings affect satisfaction

const SCROLL_SPEED : float = 12.0

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
			
			if not note.missed_start:
				handle_note_miss_start(note)
				
			if not note.missed_end and note.is_hold:
				handle_note_miss_end(note)
			
			if note_past_despawn_pos(note):
				if (not note.is_hold and note.missed_start) or (note.is_hold and note.missed_end):
					destroy_note(note)
					continue
			
			if column_pressed & (1 << note.column):
				continue
			
			if not note.missed_start:
				if note.holding:
					handle_note_judgement_end(note)
				elif not note.pressed:
					handle_note_judgement_start(note)

func load_map():
	map_loaded = false
	
	for column in note_group.get_children():
		column.queue_free()
	
	#var map = MapParser.load_map("res://maps/Testify/void (Mournfinale) feat. Hoshikuma Minami - Testify (Kyousuke-) [Prologue].osu")
	#var map = MapParser.load_map("res://maps/Can You Hear Me/BEN - Can You Hear Me (Garalulu) [A World Between The Worlds].osu")
	var map = MapParser.load_map("res://maps/Finixe/Silentroom - Finixe (shuniki) [YARANAIKA!!].osu")	

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
			
			if note_pos > playfield.FIELD_SPAWN_POS and Judge.time_ahead(time_delta, Judge.BAD, audio_handler.pitch_scale):
				break
				
			col_list.pop_front()
			
			var miss_start = false
			var miss_end = false
			
			if Judge.time_behind(time_delta, Judge.BAD, audio_handler.pitch_scale):
				miss_start = true
				
			var is_hold = (obj["time_length"] > 0)
			if is_hold:
				var end_time = obj["start_time"] + obj["time_length"]
				var end_delta = end_time - audio_handler.get_playback_position()
				if Judge.time_behind(end_delta, Judge.BAD, audio_handler.pitch_scale):
					miss_end = true
					
			if miss_start:
				add_hit(Judge.MISS, false)
				
			if miss_end:
				add_hit(Judge.MISS, false)
			
			if not miss_start or (not miss_end and is_hold):
				spawn_note_at(obj["column"], obj["start_time"], obj["time_length"])
	
	ui.spawned_notes = 0
	for column in note_group.get_children():
		ui.spawned_notes += column.get_child_count()

func get_note_pos(time : float) -> float:
	return (time - audio_handler.get_playback_position()) * (SCROLL_SPEED / audio_handler.pitch_scale) + playfield.RECEPTOR_OFFSET

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
		hold_length = (time_length * SCROLL_SPEED / audio_handler.pitch_scale)
	
	var note = note_scene.instantiate();
	note.position = (note_pos * Vector3.BACK)
	note.init(column_ind, start_time, time_length, is_hold, hold_length)
	note_group.get_child(column_ind).add_child(note)

func destroy_note(note) -> void:
	note.queue_free()
	note.active = false

func handle_note_miss_start(note) -> void:
	assert(note.active)
	assert(not note.missed_start)
	
	var start_delta = note.time - audio_handler.get_playback_position()
	
	var miss_start = Judge.time_behind(start_delta, Judge.BAD, audio_handler.pitch_scale)
	if miss_start and note.is_hold and note.pressed:
		miss_start = false
	
	if miss_start:
		note.set_pressed()
		note.set_missed_start()
		add_hit(Judge.MISS)
		
func handle_note_miss_end(note) -> void:
	assert(note.active)
	assert(note.is_hold)
	assert(not note.missed_end)
	
	var end_delta = (note.time + note.length) - audio_handler.get_playback_position()
	var miss_end = Judge.time_behind(end_delta, Judge.BAD, audio_handler.pitch_scale)
	
	if miss_end:
		note.set_holding(false)
		note.set_missed_end()
		add_hit(Judge.MISS)

func handle_note_judgement_start(note) -> void:
	assert(note.active)
	assert(not note.missed_start)
	assert(not note.pressed)
	
	var start_delta = note.time - audio_handler.get_playback_position()

	if InputHandler.is_column_pressed(note.column) and Judge.time_to_judgement(abs(start_delta), audio_handler.pitch_scale) != Judge.MISS:
		column_pressed |= (1 << note.column)
		note.set_pressed()
		
		if not note.is_hold:
			destroy_note(note)
		else:
			note.set_holding(true)
		
		note_hit(start_delta)

func handle_note_judgement_end(note) -> void:
	assert(note.active)
	assert(note.pressed)
	assert(note.is_hold)
	assert(note.holding)
	assert(not note.missed_start)
	assert(not note.missed_end)
	
	if not InputHandler.is_column_down(note.column):
		column_pressed |= (1 << note.column)
		note.set_holding(false)
		
		var end_delta = (note.time + note.length) - audio_handler.get_playback_position()
		var judge = Judge.time_to_judgement(abs(end_delta), audio_handler.pitch_scale)
		
		if judge == Judge.MISS:
			note.set_missed_end()
		else:
			destroy_note(note)
		
		add_hit(judge)

func note_hit(time_delta : float) -> void:
	var judge = Judge.time_to_judgement(abs(time_delta), audio_handler.pitch_scale)
	assert(judge != Judge.MISS)
	add_hit(judge)
	
func add_hit(judge, show_ui : bool = true) -> void:
	total_hits += 1
	hit_score += Judge.SCORE[judge]
	accuracy = float(hit_score) / float(Judge.SCORE[Judge.PERFECT] * total_hits)
	ui.set_accuracy(accuracy)
	if show_ui:
		ui.set_judge(judge)
