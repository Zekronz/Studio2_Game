extends Control

@onready var fps_label = $FPSLabel
@onready var judge_label = $JudgementLabel
@onready var acc_label = $AccLabel

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

func _process(delta: float) -> void:
	fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second())) + "\nSpawned notes: " + str(spawned_notes) + "\nHit Average: " + str(hit_average * 1000.0).pad_decimals(2) + "ms"
	
	if judge_timer > 0:
		judge_timer -= delta
		if judge_timer <= 0.0:
			judge_label.visible = false

func set_judge(judge) -> void:
	judge_timer = JUDGE_TIME
	judge_label.text = JUDGE_TEXT[judge]
	judge_label.visible = true
	
func set_accuracy(accuracy : float) -> void:
	acc_label.text = str(accuracy * 100).pad_decimals(2) + "%"
	
func set_spawned_notes(notes : int) -> void:
	spawned_notes = notes
	
func set_hit_average(average : float) -> void:
	hit_average = average
