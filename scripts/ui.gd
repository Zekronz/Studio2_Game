extends Control

@onready var fps_label = $FPSLabel
@onready var judge_label = $JudgementLabel
@onready var combo_label = $ComboLabel
@onready var score_label = $ScoreLabel
@onready var acc_label = $AccLabel
@onready var progress_bar = $ProgressBar

var spawned_notes : int = 0
var hit_average : float = 0.0

const JUDGE_TIME : float = 0.25
var judge_timer : float = 0.0

const JUDGE_TEXT : Dictionary = {
	Judge.PERFECT: "PERFECT",
	Judge.GREAT: "GREAT",
	Judge.GOOD: "GOOD",
	Judge.OK: "OK",
	Judge.BAD: "BAD",
	Judge.MISS: "MISS",
}

const JUDGE_COLOR : Dictionary = {
	Judge.PERFECT: Color(0.995, 0.719, 0.0, 1.0),
	Judge.GREAT: Color(0.767, 0.925, 0.0, 1.0),
	Judge.GOOD: Color(0.0, 0.722, 0.633, 1.0),
	Judge.OK: Color(0.0, 0.0, 1.0),
	Judge.BAD: Color(0.5, 0.5, 0.5),
	Judge.MISS: Color(1.0, 0.0, 0.0)
}


func _process(delta: float) -> void:
	fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second())) + "\nSpawned notes: " + str(spawned_notes) + "\nHit Average: " + str(hit_average * 1000.0).pad_decimals(2) + "ms"
	
	if judge_timer > 0:
		judge_timer -= delta
		if judge_timer <= 0.0:
			judge_label.visible = false

func set_judge(judge) -> void:
	judge_timer = JUDGE_TIME
	judge_label.text = JUDGE_TEXT[judge]
	#judge_label.set("theme_override_colors/font_color", JUDGE_COLOR[judge])
	judge_label.visible = true
	
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
		combo_label.visible = false
	else:
		combo_label.text = str(combo)
		combo_label.visible = true

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
