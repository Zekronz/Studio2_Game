extends Control

@onready var playfield = $"../Playfield"

@onready var fps_label = $FPSLabel
@onready var combo_label = $ComboLabel
@onready var score_label = $ScoreLabel
@onready var acc_label = $AccLabel
@onready var progress_bar = $ProgressBar

var spawned_notes : int = 0
var hit_average : float = 0.0

const JUDGE_TIME : float = 0.3
var judge_info : Array[Dictionary]

var combo_str : String

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
	fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second())) + "\nSpawned notes: " + str(spawned_notes) + "\nHit Average: " + str(hit_average * 1000.0).pad_decimals(2) + "ms"
	
	for i in InputHandler.key_count:
		if judge_info[i]["timer"] > 0:
			judge_info[i]["timer"] -= delta
			if judge_info[i]["timer"] <= 0.0:
				pass
				
	queue_redraw()
				
func _draw() -> void:
	var judge_font = ThemeDB.fallback_font
	var judge_size = 30.0
	var judge_offset = 56.0
	
	for i in InputHandler.key_count:
		if judge_info[i]["timer"] <= 0.0:
			continue
			
		var judge = judge_info[i]["judge"]
		var s = judge_font.get_string_size(JUDGE_TEXT[judge], HORIZONTAL_ALIGNMENT_CENTER, -1, judge_size)
		var p = playfield.get_column_2d_point(i) + Vector2(-round(s.x / 2), -s.y + judge_font.get_ascent(judge_size) + judge_offset)
		
		draw_string(judge_font, p, JUDGE_TEXT[judge], HORIZONTAL_ALIGNMENT_CENTER, -1, judge_size, JUDGE_COLOR[judge])
		
	var combo_font = ThemeDB.fallback_font
	var combo_size = 35.0
	var combo_offset = 350.0
		
	if combo_str.length() > 0:
		var s = combo_font.get_string_size(combo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, combo_size)
		var p = Vector2(round(size.x / 2.0 - s.x / 2.0), playfield.get_column_2d_point(0).y - combo_offset)
		draw_string(combo_font, p, combo_str, HORIZONTAL_ALIGNMENT_CENTER, -1, combo_size)

func set_judge(column, judge) -> void:
	assert(column >= 0 && column < InputHandler.key_count)
	judge_info[column]["timer"] = JUDGE_TIME;
	judge_info[column]["judge"] = judge;
	
func set_score(score : int) -> void:
	score_label.text = format_int_commas(score)
	
func set_accuracy(accuracy : float) -> void:
	acc_label.text = str(accuracy * 100).pad_decimals(2) + "%"
	
func set_spawned_notes(notes : int) -> void:
	spawned_notes = notes
	
func set_hit_average(average : float) -> void:
	hit_average = average

func set_combo(combo : int) -> void:
	if combo == 0:
		combo_str = ""
	else:
		combo_str = str(combo)

func set_progress(progress : float) -> void:
	progress_bar.scale = Vector2(clamp(progress, 0.0, 1.0), 1.0);

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
