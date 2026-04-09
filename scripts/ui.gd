extends Control

@onready var fps_label = $FPSLabel

var spawned_notes : int = 0

func _process(delta: float) -> void:
	fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second())) + "\nSpawned notes: " + str(spawned_notes)
