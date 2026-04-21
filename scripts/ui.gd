extends Control

@onready var playfield = $"../Playfield"
@onready var debug_label = $DebugLabel

var font : Font = preload("res://fonts/Century Gothic.ttf")
var flash_tex : Texture2D = preload("res://textures/flash.png")

var spawned_notes : int = 0
var hit_average : float = 0.0

const JUDGE_TIME_MUL : float = 2.5
var judge_info : Array[Dictionary]

const COMBO_TIME_MUL : float = 4.5
var combo_timer : float = 0.0

const COMBO_MILESTONE_TIME_MUL : float = 1.75
var combo_milestone_timer : float = 0.0
var combo_milestone_str : String = ""

var combo_str : String
var health_percentage : float
var health_scale : float
var score_str : String
var acc_str : String
var acc_val : float
var progress_percentage : float
var death_overlay : float

var JUDGE_TEX : Dictionary = {
	Judge.PERFECT: preload("res://textures/judge_perfect.png"),
	Judge.GREAT: preload("res://textures/judge_great.png"),
	Judge.GOOD: preload("res://textures/judge_good.png"),
	Judge.OK: preload("res://textures/judge_ok.png"),
	Judge.BAD: preload("res://textures/judge_bad.png"),
	Judge.MISS: preload("res://textures/judge_miss.png")
}

func _ready() -> void:
	for i in InputHandler.MAX_SUPPORTED_KEY_COUNT:
		judge_info.append({ "timer": 0.0, "judge": Judge.MISS })

func _process(delta: float) -> void:
	debug_label.text = "FPS: " + str(int(Engine.get_frames_per_second())) + "\nSpawned notes: " + str(spawned_notes) + "\nHit Average: " + str(hit_average * 1000.0).pad_decimals(2) + "ms"
	
	for i in InputHandler.key_count:
		if judge_info[i]["timer"] > 0.0:
			judge_info[i]["timer"] = max(0.0, judge_info[i]["timer"] - delta * JUDGE_TIME_MUL)
			
	if combo_timer > 0.0:
		combo_timer = max(0.0, combo_timer - delta * COMBO_TIME_MUL)
			
	if combo_milestone_timer > 0.0:
		combo_milestone_timer = max(0.0, combo_milestone_timer - delta * COMBO_MILESTONE_TIME_MUL)
				
	queue_redraw()
				
func _draw() -> void:
	var ui_scale = size.y / 1080.0
	
	#Judgement.
	var judge_scale = 0.45
	var judge_offset = 0.3
	
	for i in InputHandler.key_count:
		var timer = judge_info[i]["timer"]
		if timer <= 0.0:
			continue
			
		var judge = judge_info[i]["judge"]
		var t = JUDGE_TEX[judge]
		var s = t.get_size() * ui_scale * (judge_scale + timeline_smooth((1.0 - timer) * 3.0) * 0.1)
		var p = playfield.get_column_2d_point(i, judge_offset) + Vector2(-(s.x / 2), -s.y)
		var alpha = timeline_smooth(1.0 - timer, 0.2, 0.4)
		draw_texture_rect(t, Rect2(p, s), false, Color(1.0, 1.0, 1.0, alpha))
		
	#Combo.
	var combo_font = font
	var combo_size = 56.0 * ui_scale
	var combo_offset = 350.0 * ui_scale
		
	if combo_milestone_str.length() > 0 and combo_milestone_timer > 0.0:
		var cs = combo_size * (1.0 + (1.0 - combo_milestone_timer) * 1.2)
		var s = combo_font.get_string_size(combo_milestone_str, HORIZONTAL_ALIGNMENT_CENTER, -1, cs)
		var p = Vector2((size.x / 2.0 - s.x / 2.0), playfield.get_column_2d_point(0).y - combo_offset + combo_font.get_ascent(cs) / 2.0)
		
		var a = 1.0 - combo_milestone_timer
		draw_string(combo_font, p, combo_milestone_str, HORIZONTAL_ALIGNMENT_CENTER, -1, cs, Color(1.0, 1.0, 1.0, (1.0 - (a * a)) * 0.4))
		
	if combo_str.length() > 0:
		var cs = combo_size * (1.0 + timeline_smooth(1.0 - combo_timer) * 0.12)
		var s = combo_font.get_string_size(combo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, cs)
		var p = Vector2((size.x / 2.0 - s.x / 2.0), playfield.get_column_2d_point(0).y - combo_offset + combo_font.get_ascent(cs) / 2.0)
		draw_string(combo_font, p, combo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, cs)
		
	#Health bar.
	var hp_hor_offset = 15.0 * ui_scale * health_scale
	var hp_ver_offset = 20.0 * ui_scale * health_scale
	var hp_dir = playfield.get_2d_direction_right()
	var hp_pos = playfield.get_rightside_2d_point() + hp_hor_offset * Vector2.RIGHT + hp_ver_offset * hp_dir
	var hp_width = 25.0 * ui_scale * health_scale
	var hp_length = 400.0 * ui_scale * health_scale
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
	], Color.WHITE, 1.6 * ui_scale * health_scale, true)
	
	draw_primitive([
		hp_pos,
		hp_pos + hp_width * Vector2.RIGHT,
		hp_pos + hp_width * Vector2.RIGHT + hp_dir * hp_length * health_percentage,
		hp_pos + hp_dir * hp_length * health_percentage,
	],
	[ Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE ], [])
	
	#Score.
	var score_font = font
	var score_size = 63.0 * ui_scale
	var score_offset = 50.0 * ui_scale
	
	var score_str_size = score_font.get_string_size(score_str, HORIZONTAL_ALIGNMENT_CENTER, -1, score_size)
	draw_string(score_font, Vector2(size.x - score_str_size.x - score_offset, score_font.get_ascent(score_size)), score_str, HORIZONTAL_ALIGNMENT_CENTER, -1, score_size)
	
	#Accuracy.
	var acc_font = font
	var acc_size = 40.0 * ui_scale
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
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.5, 0.0, 0.05, death_overlay * 0.5))
		
	#Fail.
	if death_overlay >= 1.0:
		var fail_font = font
		var fail_title_size = 100.0 * ui_scale
		var fail_title_offset = -350.0 * ui_scale
		
		var fail_restart_size = 52.0 * ui_scale
		var fail_restart_offset = 0# * ui_scale
		
		draw_text_centered(fail_font, Vector2(size.x / 2.0, size.y / 2.0 + fail_title_offset), "You Failed!", fail_title_size)
		draw_text_centered(fail_font, Vector2(size.x / 2.0, size.y / 2.0 + fail_restart_offset), "Press 'R' to restart.", fail_restart_size)

func draw_text_centered(str_font : Font, pos : Vector2, text : String, str_size : int, col : Color = Color(1, 1, 1, 1)) -> void:
	var s = str_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, str_size)
	var str_pos = Vector2(pos.x - s.x / 2.0, pos.y + str_font.get_ascent(str_size) - s.y / 2.0)
	draw_string(str_font, str_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, str_size, col)

func set_judge(column, judge) -> void:
	assert(column >= 0 && column < InputHandler.key_count)
	judge_info[column]["timer"] = 1.0;
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
		combo_timer = 0.0
	else:
		combo_str = str(combo)
		combo_timer = 1.0
		
func set_combo_milestone(milestone : int) -> void:
	assert(milestone > 0)
	combo_milestone_str = str(milestone)
	combo_milestone_timer = 1.0

func set_health(health : float) -> void:
	health_percentage = health

func set_health_scale(s : float) -> void:
	health_scale = s

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
	
func timeline_smooth(t : float, a : float = 1.3, b : float = 2.4) -> float:
	t = clamp(t, 0.0, 1.0)
	var t_peak = a / (a + b)
	var max_val = (t_peak ** a) * ((1 - t_peak) ** b)
	return (t ** a) * ((1 - t) ** b) / max_val
