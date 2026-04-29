extends Node

#TODO: Judgement for each column? Too noisy?
#TODO: 1 mill score? Or higher for more satisfaction?
#TODO: How much info to display in middle of playfield vs. th  side?
#TODO: Temporal feedback, as in how strict timings affect satisfaction
#TODO: Song info ui display?
#TODO: Movement: Striped hold notes, bar line, background?
#TODO: Note about custom camera effect based on beats. Exploring camera movements and non-linear note movement.
#TODO: Judgements above vs. below notes. Above harder to read, but only colors matter
#TODO: Show early vs late judgements.
#TODO: Combo sound is abnoxious?

#V2:
#Key press highlight 	[X]
#Note highlight			[X]
#Hold cutoff			[X]
#Per column judgement	[X]
#Coloured judgement		[X]
#Column separator		[X]
#Hit sounds				[X]
#Health					[X]
#Miss sound				[X]

#V3
#Receptor pos			[X]
#Better camera persp	[X]
#Fade playfield			[X]
#Bar lines				[X]
#Floor scrolling		[X]
#Better receptor		[X]
#Scrolling visibility	[X]
#Different note colors	[X]
#Better note graphics 	[X]
#Particle effects		[X]
#Camera shake			[X]

#V4
#Camera start animation	[X]
#Show keybinds at start	[#]
#Combo effects			[X]
#Judgement art			[X]
#Better ui art			[ ]
#Better background		[ ]
#Better sounds			[X]

const map_str = "res://maps/Testify/void (Mournfinale) feat. Hoshikuma Minami - Testify (Kyousuke-) [Prologue].osu"
#const map_str = "res://maps/Storm Buster/PLight - Storm Buster (Spy) [HARD].osu"
#const map_str = "res://maps/Can You Hear Me/BEN - Can You Hear Me (Garalulu) [A World Between The Worlds].osu"
#const map_str = "res://maps/Finixe/Silentroom - Finixe (shuniki) [YARANAIKA!!].osu"

const SCROLL_SPEED : float = 10.0
const VISUAL_OFFSET : float = 0.0 / 1000.0

@onready var audio_handler : Node = $AudioStreamPlayer
@onready var ui : Control = $UI
@onready var playfield : Node3D = $Playfield
@onready var cam : Camera3D = $Camera
@onready var note_group : Node3D = $Notes
@onready var fx_group : Node3D = $FX

var note_scene : Resource = preload("res://scenes/note.tscn")
var hit_fx_scene : Resource = preload("res://scenes/hit_effect.tscn")
var hold_fx_scene : Resource = preload("res://scenes/hold_effect.tscn")

var map_loaded : bool = false
var hit_objects : Array;
var column_pressed : Array
var total_single : int = 0
var total_hold : int = 0
var song_length : float = 0
var total_hits : int = 0
var score : int = 0
var hit_score : int = 0
var accuracy : float = 0
var hit_deviation : float = 0
var combo : int = 0
const COMBO_MILESTONE_STEP : int = 100
var next_combo_milestone : int = COMBO_MILESTONE_STEP
var health : float = 0.0
var dead : bool = false

var cam_start_timer : float = 0.0
var cam_start_offset : Vector3

var bar_length : float = 0.0
var bar_timing_offset : float = 0.0

var paused_pos : float = 0.0
var pitch_multiplier : float = 1.0

var current_hold_notes : Array[Node3D]

var auto_mod : bool = false
var no_fail_mod : bool = false

func _ready() -> void:
	assert(note_group != null)
	
	cam_start_offset = Vector3(0.0, 0.5, -1.0)
	cam.set_pos_offset(cam_start_offset)
	
	column_pressed.resize(InputHandler.MAX_SUPPORTED_KEY_COUNT)
	
	current_hold_notes.resize(InputHandler.MAX_SUPPORTED_KEY_COUNT)
	for i in InputHandler.MAX_SUPPORTED_KEY_COUNT:
		current_hold_notes[i] = null
	
	load_map(map_str)

func _process(delta : float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if not map_loaded:
		return
	
	cam_start_timer = min(1.0, cam_start_timer + delta / 20.0);
	cam.set_pos_offset((1.0 - smoothstep(0.0, 1.0, cam_start_timer)) * cam.pos_offset)
		
	if dead and audio_handler.stream_paused:
		if Input.is_action_just_pressed("restart"):
			audio_handler.pitch_scale = audio_handler.start_pitch
			audio_handler.stop()
			ui.set_death_overlay(0.0)
			ui.set_health_scale(1.0)
			cam.set_fov_offset(0.0)
			load_map(map_str)
			audio_handler.play(0.0)
			return
		
	if not auto_mod and not dead:
		for key_ind in range(InputHandler.key_count):
			playfield.set_key_press(key_ind, InputHandler.is_column_down(key_ind))

			if InputHandler.is_column_pressed(key_ind):
				audio_handler.oneshot(audio_handler.hit_sound)
		
	if dead and not audio_handler.stream_paused and audio_handler.pitch_scale > 0:
		var scale = max(0, audio_handler.pitch_scale - 0.6 * delta)
		if scale <= 0.0:
			audio_handler.stream_paused = true
			paused_pos = audio_handler.get_pos()
			ui.set_death_overlay(1.0)
			ui.set_health_scale(1.0 - 0.5)
			cam.set_fov_offset(50.0)
		else:
			audio_handler.pitch_scale = scale
			
			var d = clamp(1.0 - (scale / audio_handler.start_pitch), 0.0, 1.0)
			var sd = smoothstep(0.0, 1.0, d)
			
			ui.set_death_overlay(d)
			ui.set_health_scale(1.0 - sd * 0.5)
			cam.set_fov_offset(smoothstep(0.0, 1.0, sd) * 50.0)
		
	update_progress()	
	check_note_spawns()
	
	#Update note positions and handle judgements.
	playfield.set_bar_length(time_to_physical_length(bar_length))
	playfield.set_bar_offset(get_note_pos(bar_timing_offset))
	
	for i in InputHandler.MAX_SUPPORTED_KEY_COUNT:
		column_pressed[i] = false
	
	for column_ind in playfield.num_columns:
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
			
			if column_pressed[note.column]:
				continue
			
			if not note.missed_start:
				if note.holding:
					handle_note_judgement_end(note)
				elif not note.pressed:
					handle_note_judgement_start(note)

func load_map(map_file):
	map_loaded = false
	
	for column in note_group.get_children():
		column.queue_free()
		
	for i in InputHandler.MAX_SUPPORTED_KEY_COUNT:
		current_hold_notes[i] = null
	
	var map = MapParser.load_map(map_file)
	#var map = MapParser.load_map("res://maps/Testify/void (Mournfinale) feat. Hoshikuma Minami - Testify (Kyousuke-) [Epilogue].osu")
	#aar map = MapParser.load_map("res://maps/Storm Buster/PLight - Storm Buster (Spy) [HARD].osu")
	#var map = MapParser.load_map("res://maps/Can You Hear Me/BEN - Can You Hear Me (Garalulu) [A World Between The Worlds].osu")
	#var map = MapParser.load_map("res://maps/Finixe/Silentroom - Finixe (shuniki) [YARANAIKA!!].osu")

	var timing_points = map["timing_points"]
	if len(timing_points) > 0:
		if len(timing_points) > 1:
			print("WARNING: Unsupported BPM changes.")
		
		var t = timing_points[0]
		bar_length = t["beat_length"] * 4.0 #TODO: Doesn't support other time signatures
		bar_timing_offset = t["time"]
		
		playfield.set_bar_length(time_to_physical_length(bar_length))
		playfield.set_bar_offset(get_note_pos(bar_timing_offset))

	InputHandler.key_count = map["key_count"]
	playfield.set_num_columns(map["key_count"])
		
	for column_ind in playfield.num_columns:
		var column = Node3D.new()
		column.name = str(column_ind)
		column.position = playfield.get_column_center(column_ind) * Vector3.RIGHT
		note_group.add_child(column)
		note_group.move_child(column, column_ind)
	
	hit_objects = map["hit_objects"]
	
	total_single = map["total_single"]
	total_hold = map["total_hold"]
	song_length = map["last_timing"] + (2 * audio_handler.start_pitch)
	total_hits = 0
	hit_score = 0
	score = 0
	accuracy = 1.0
	hit_deviation = 0
	combo = 0
	next_combo_milestone = COMBO_MILESTONE_STEP
	health = 0.75
	dead = false
	
	cam.set_pos_offset(cam_start_offset)
	cam_start_timer = 0.0
	
	pitch_multiplier = 1.0
	
	ui.set_score(0)
	ui.set_accuracy(accuracy)
	ui.set_hit_average(0)
	ui.set_combo(0)
	ui.set_health(health)
	ui.set_health_scale(1.0)
	ui.set_death_overlay(0)
	ui.reset_judge()
	ui.reset_keybind_display()
	update_progress()
	
	check_note_spawns()
	map_loaded = true

func check_note_spawns() -> void:
	for column_ind in playfield.num_columns:
		var col_list = hit_objects[column_ind]
		
		while len(col_list) > 0:
			var obj = col_list[0]
			
			var start_delta = obj["start_time"] - audio_handler.get_pos()
			var end_delta = (obj["start_time"] + obj["time_length"]) - audio_handler.get_pos()
			
			var note_pos = get_note_pos(obj["start_time"])
			
			if note_pos > playfield.FIELD_SPAWN_POS and Judge.time_ahead(start_delta, Judge.BAD, audio_handler.start_pitch):
				break
				
			col_list.pop_front()
			
			var miss_start = false
			var miss_end = false
			
			if Judge.time_behind(start_delta, Judge.BAD, audio_handler.start_pitch):
				miss_start = true
				
			var is_hold = (obj["time_length"] > 0)
			if is_hold and Judge.time_behind(end_delta, Judge.BAD, audio_handler.start_pitch):
				miss_end = true
					
			if miss_start:
				add_hit(column_ind, is_hold, false, Judge.MISS, start_delta, false)
				
			if miss_end:
				add_hit(column_ind, is_hold, true, Judge.MISS, end_delta, false)
			
			if not miss_start or (not miss_end and is_hold):
				spawn_note_at(obj["column"], obj["start_time"], obj["time_length"])
	
	var num_notes : int = 0
	var column_ind : int = 0
	for column in note_group.get_children():
		num_notes += column.get_child_count()
		column_ind += 1
		if column_ind >= InputHandler.key_count:
			break
	
	ui.set_spawned_notes(num_notes)

func time_to_physical_length(time : float) -> float:
	return time * (SCROLL_SPEED / audio_handler.start_pitch)

func get_note_pos(time : float) -> float:
	var pos = paused_pos if audio_handler.stream_paused else audio_handler.get_pos()
	return time_to_physical_length(time - pos - VISUAL_OFFSET) + playfield.RECEPTOR_OFFSET
	#return (time - pos - VISUAL_OFFSET) * (SCROLL_SPEED / audio_handler.start_pitch) + playfield.RECEPTOR_OFFSET

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
		hold_length = (time_length * SCROLL_SPEED / audio_handler.start_pitch)
	
	var note = note_scene.instantiate();
	note.position = (note_pos * Vector3.BACK)
	note.init(column_ind, start_time, time_length, is_hold, hold_length)
	note_group.get_child(column_ind).add_child(note)

func destroy_note(note) -> void:
	if note.hold_effect != null:
		note.hold_effect.queue_free()
		note.hold_effect = null
		
	note.active = false
	note.queue_free()

func handle_note_miss_start(note) -> void:
	assert(note.active)
	assert(not note.missed_start)
	
	var start_delta = note.time - audio_handler.get_pos()
	
	var miss_start = Judge.time_behind(start_delta, Judge.BAD, audio_handler.start_pitch)
	if miss_start and note.is_hold and note.pressed:
		miss_start = false
	
	if miss_start:
		note.set_pressed()
		note.set_missed_start()
		add_hit(note.column, note.is_hold, false, Judge.MISS, start_delta)
		
func handle_note_miss_end(note) -> void:
	assert(note.active)
	assert(note.is_hold)
	assert(not note.missed_end)
	
	var end_delta = (note.time + note.length) - audio_handler.get_pos()
	var miss_end = Judge.time_behind(end_delta, Judge.BAD, audio_handler.start_pitch)
	
	if miss_end:
		note.set_missed_end()
		note.set_holding(false)
		current_hold_notes[note.column] = note
		add_hit(note.column, true, true, Judge.MISS, end_delta)

func handle_note_judgement_start(note) -> void:
	assert(note.active)
	assert(not note.missed_start)
	assert(not note.pressed)
	
	var start_delta = note.time - audio_handler.get_pos()
	var judge = Judge.time_to_judgement(abs(start_delta), audio_handler.start_pitch)

	var press_key : bool = false
	if not auto_mod:
		press_key = InputHandler.is_column_pressed(note.column) and not dead
	else:
		press_key = (start_delta <= 0.0)
		
	if press_key and judge != Judge.MISS:
		column_pressed[note.column] = true
		note.set_pressed()
		
		if not note.is_hold:
			destroy_note(note)
		else:
			note.set_holding(true)
			current_hold_notes[note.column] = note
		
		note_hit(note, start_delta)

func handle_note_judgement_end(note) -> void:
	assert(note.active)
	assert(note.pressed)
	assert(note.is_hold)
	assert(note.holding)
	assert(not note.missed_start)
	assert(not note.missed_end)
	
	var end_delta = (note.time + note.length) - audio_handler.get_pos()
	var judge = Judge.time_to_judgement(abs(end_delta), audio_handler.start_pitch)
	
	var release_key : bool = false
	if not auto_mod:
		release_key = not InputHandler.is_column_down(note.column) or dead
	else:
		release_key = (end_delta <= 0.0)
	
	if release_key:
		column_pressed[note.column] = true
		note.set_holding(false)
		
		if judge == Judge.MISS:
			note.set_missed_end()
		else:
			destroy_note(note)
		
		current_hold_notes[note.column] = null
		add_hit(note.column, true, true, judge, end_delta)

func note_hit(note, time_delta : float) -> void:
	assert(note.column >= 0 && note.column < InputHandler.key_count)
	var judge = Judge.time_to_judgement(abs(time_delta), audio_handler.start_pitch)
	assert(judge != Judge.MISS)
	add_hit(note.column, note.is_hold, false, judge, time_delta)
	
func add_hit(column : int, is_hold : bool, is_release : bool, judge, time_delta : float, user_hit : bool = true) -> void:
	assert(column >= 0 && column < InputHandler.key_count)
	
	time_delta /= audio_handler.start_pitch
	
	if user_hit:
		total_hits += 1
	
		if judge == Judge.MISS:
			combo = 0
			next_combo_milestone = COMBO_MILESTONE_STEP
			cam.shake()
		else:
			combo += 1
			var play_milestone = false
			while combo >= next_combo_milestone:
				play_milestone = true
				ui.set_combo_milestone(next_combo_milestone)
				next_combo_milestone += COMBO_MILESTONE_STEP
				
			if play_milestone:
				audio_handler.oneshot(audio_handler.combo_sound)
	
		ui.set_combo(combo)
	
		hit_score += Judge.SCORE[judge]
		accuracy = float(hit_score) / float(Judge.SCORE[Judge.PERFECT] * total_hits)
		ui.set_accuracy(accuracy)
	
		#score = int(round((float(hit_score) / float((total_single + (total_hold * 2)) * Judge.SCORE[Judge.PERFECT])) * 1000000.0))
		score += int(round(float(Judge.SCORE[judge] * max(1, combo)) / 100.0))
		ui.set_score(score)
	
		hit_deviation += time_delta;
		ui.set_hit_average(-(hit_deviation / float(total_hits)))
		
		if not dead:
			ui.set_judge(column, judge)
		
			if judge == Judge.MISS:
				audio_handler.oneshot(audio_handler.miss_sound)
			else:
				spawn_hit_effect(column, false)
				
				if is_hold and not is_release:
					var fx = spawn_hit_effect(column, true)
					current_hold_notes[column].hold_effect = fx
		
			health = clamp(health + Judge.HEALTH[judge], 0.0, 1.0)
			ui.set_health(health)
			
			if health <= 0.0 and not no_fail_mod:
				dead = true

func update_progress():
	if audio_handler.is_finished:
		ui.set_progress(1.0)
	else:
		var pos = paused_pos if audio_handler.stream_paused else audio_handler.get_pos()
		ui.set_progress(pos / song_length)
		
func spawn_hit_effect(column : int, hold : bool) -> Node3D:
	assert(column >= 0 && column < InputHandler.key_count)
	
	var fx = null
	if not hold:
		fx = hit_fx_scene.instantiate()
	else:
		fx = hold_fx_scene.instantiate()
		
	assert(fx != null)
	
	fx.position = Vector3(playfield.get_column_center(column), 0.0, playfield.RECEPTOR_OFFSET)# - 0.0125);
	fx.rotation = Vector3(-cam.rotation.x, 0.0, 0.0)
	fx_group.add_child(fx)
	
	return fx
