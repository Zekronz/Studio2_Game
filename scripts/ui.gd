extends Control

@onready var playfield = $"../Playfield"
@onready var debug_label = $DebugLabel

var flash_tex : Texture2D = preload("res://textures/flash.png")

var spawned_notes : int = 0
var hit_average : float = 0.0

const JUDGE_TIME : float = 0.3
var judge_info : Array[Dictionary]

var combo_str : String
var health_percentage : float
var score_str : String
var acc_str : String
var acc_val : float
var progress_percentage : float
var death_overlay : float

var JUDGE_TEXT : Dictionary = {
	Judge.PERFECT: "MAX",
	Judge.GREAT: "GREAT",
	Judge.GOOD: "GOOD",
	Judge.OK: "OK",
	Judge.BAD: "BAD",
	Judge.MISS: "MISS",
}

var JUDGE_COLOR : Dictionary = {
	Judge.PERFECT: Color(0.995, 0.719, 0.0, 1.0),
	Judge.GREAT: Color(0.767, 0.925, 0.0, 1.0),
	Judge.GOOD: Color(0.0, 0.722, 0.633, 1.0),
	Judge.OK: Color(0.0, 0.0, 1.0),
	Judge.BAD: Color(0.5, 0.5, 0.5),
	Judge.MISS: Color(1.0, 0.0, 0.0)
}

func _ready() -> void:
	for i in InputHandler.MAX_SUPPORTED_KEY_COUNT:
		judge_info.append({ "timer": 0.0, "judge": Judge.MISS })

func _process(delta: float) -> void:
	debug_label.text = "FPS: " + str(int(Engine.get_frames_per_second())) + "\nSpawned notes: " + str(spawned_notes) + "\nHit Average: " + str(hit_average * 1000.0).pad_decimals(2) + "ms"
	
	for i in InputHandler.key_count:
		if judge_info[i]["timer"] > 0:
			judge_info[i]["timer"] -= delta
			if judge_info[i]["timer"] <= 0.0:
				pass
				
	queue_redraw()
				
func _draw() -> void:
	var ui_scale = size.y / 1080.0
	
	#Flash.
	#var flash_size : Vector2 = flash_tex.get_size() * ui_scale * 1.2
	#var flash_offset = 6.0 * ui_scale
	#var flash_pos = playfield.get_column_2d_point(4) - flash_size / 2.0 + flash_offset * Vector2.DOWN
	#draw_texture_rect(flash_tex, Rect2(flash_pos.x, flash_pos.y, flash_size.x, flash_size.y), false)
	#draw_primitive([
		#Vector2(flash_pos.x, flash_pos.y),
		#Vector2(flash_pos.x + flash_size.x, flash_pos.y),
		#Vector2(flash_pos.x + flash_size.x, flash_pos.y + flash_size.y / 2.0),
		#Vector2(flash_pos.x, flash_pos.y + flash_size.y / 2.0),
	#],
	#[Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], 
	#[
		#Vector2(0.0, 1.0),
		#Vector2(0.0, 0.0),
		#Vector2(0.5, 0.0),
		#Vector2(0.5, 1.0),
		#
	#], flash_tex)
	
	#Judgement.
	var judge_font = ThemeDB.fallback_font
	var judge_size = 50.0 * ui_scale
	var judge_offset = 93.0 * ui_scale
	
	for i in InputHandler.key_count:
		if judge_info[i]["timer"] <= 0.0:
			continue
			
		var judge = judge_info[i]["judge"]
		var s = judge_font.get_string_size(JUDGE_TEXT[judge], HORIZONTAL_ALIGNMENT_CENTER, -1, judge_size)
		var p = playfield.get_column_2d_point(i) + Vector2(-(s.x / 2), -s.y + judge_font.get_ascent(judge_size) + judge_offset)		
		draw_string(judge_font, p, JUDGE_TEXT[judge], HORIZONTAL_ALIGNMENT_CENTER, -1, judge_size, JUDGE_COLOR[judge])
		
	#Combo.
	var combo_font = ThemeDB.fallback_font
	var combo_size = 58.0 * ui_scale
	var combo_offset = 320.0 * ui_scale
		
	if combo_str.length() > 0:
		var s = combo_font.get_string_size(combo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, combo_size)
		var p = Vector2((size.x / 2.0 - s.x / 2.0), playfield.get_column_2d_point(0).y - combo_offset)
		draw_string(combo_font, p, combo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, combo_size)
		
	#Health bar.
	var hp_hor_offset = 15.0 * ui_scale
	var hp_ver_offset = 20.0 * ui_scale
	var hp_dir = playfield.get_2d_direction_right()
	var hp_pos = playfield.get_rightside_2d_point() + hp_hor_offset * Vector2.RIGHT + hp_ver_offset * hp_dir
	var hp_width = 15.0 * ui_scale
	var hp_length = 350.0 * ui_scale
	var hp_bg = Color(0.0, 0.0, 0.0, 0.435)
	
	draw_primitive([
		hp_pos,
		hp_pos + hp_width * Vector2.RIGHT,
		hp_pos + hp_width * Vector2.RIGHT + hp_dir * hp_length * health_percentage,
		hp_pos + hp_dir * hp_length * health_percentage,
	],
	[ hp_bg, hp_bg, hp_bg, hp_bg ], [])
	
	draw_polyline([
		hp_pos,
		hp_pos + hp_width * Vector2.RIGHT,
		hp_pos + hp_width * Vector2.RIGHT + hp_dir * hp_length,
		hp_pos + hp_dir * hp_length,
		hp_pos
	], Color.WHITE, 1.6 * ui_scale, true)
	
	draw_primitive([
		hp_pos,
		hp_pos + hp_width * Vector2.RIGHT,
		hp_pos + hp_width * Vector2.RIGHT + hp_dir * hp_length * health_percentage,
		hp_pos + hp_dir * hp_length * health_percentage,
	],
	[ Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE ], [])
	
	#Score.
	var score_font = ThemeDB.fallback_font
	var score_size = 58.0 * ui_scale
	var score_offset = 50.0 * ui_scale
	
	var score_str_size = score_font.get_string_size(score_str, HORIZONTAL_ALIGNMENT_CENTER, -1, score_size)
	draw_string(score_font, Vector2(size.x - score_str_size.x - score_offset, score_font.get_ascent(score_size)), score_str, HORIZONTAL_ALIGNMENT_CENTER, -1, score_size)
	
	#Accuracy.
	var acc_font = ThemeDB.fallback_font
	var acc_size = 35.0 * ui_scale
	var acc_offset = 20.0 * ui_scale
	
	var acc_str_size = acc_font.get_string_size(acc_str, HORIZONTAL_ALIGNMENT_CENTER, -1, acc_size)
	draw_string(acc_font, Vector2(size.x - acc_str_size.x - acc_offset, acc_font.get_ascent(acc_size) + score_str_size.y), acc_str, HORIZONTAL_ALIGNMENT_CENTER, -1, acc_size)
	
	#Progress bar.
	var progress_height = 30 * ui_scale
	var progress_border = 8 * ui_scale
	draw_rect(Rect2(0, size.y - progress_height, size.x, progress_height), Color(0.0, 0.0, 0.0, 0.435))
	
	if progress_percentage > 0:
		draw_rect(Rect2(progress_border, size.y - progress_height + progress_border, (size.x - progress_border * 2.0) * progress_percentage, progress_height - progress_border * 2.0), Color.WHITE, true, -1, true)
	
	#Death overlay.
	if death_overlay > 0.0:
		draw_rect(Rect2(0, 0, size.x, size.y), Color(1.0, 0.0, 0.0, death_overlay * 0.5))

func set_judge(column, judge) -> void:
	assert(column >= 0 && column < InputHandler.key_count)
	judge_info[column]["timer"] = JUDGE_TIME;
	judge_info[column]["judge"] = judge;
	
func reset_judge() -> void:
	for i in InputHandler.MAX_SUPPORTED_KEY_COUNT:
		judge_info[i]["timer"] = 0.0
	
func set_score(score : int) -> void:
	score_str = format_int_commas(score)
	
func set_accuracy(accuracy : float) -> void:
	acc_str = str(accuracy * 100).pad_decimals(2) + "%"
	
func set_spawned_notes(notes : int) -> void:
	spawned_notes = notes
	
func set_hit_average(average : float) -> void:
	hit_average = average

func set_combo(combo : int) -> void:
	if combo == 0:
		combo_str = ""
	else:
		combo_str = str(combo)

func set_health(health : float) -> void:
	health_percentage = health

func set_progress(progress : float) -> void:
	progress_percentage = progress

func set_death_overlay(amount : float) -> void:
	death_overlay = amount

func format_int_commas(num: int) -> String:
	var num_str: String = str(abs(num))
	var result: String = ""
	var count: int = 0

	for i in range(num_str.length() - 1, -1, -1):
		result = num_str[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result

	if num < 0:
		result = "-" + result

	return result
