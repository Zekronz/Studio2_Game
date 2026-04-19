extends Node3D

@onready var f1 : MeshInstance3D = $Flash1

var released : bool
var release_timer : float
const RELEASE_TIMER_MUL : float = 10.0

var timer : float
var start_scale : Vector3

func _ready() -> void:
	start_scale = Vector3(0.8, 0.8, 1.0)
	
func _process(delta : float) -> void:
	timer += delta
	
	var s_off = sin(timer * 40.0) / 10.0
	f1.scale = start_scale + Vector3(s_off, s_off, 0.0)
	
	if released:
		release_timer = min(1.0, release_timer + delta * RELEASE_TIMER_MUL)
		f1.set_instance_shader_parameter("alpha", 1.0 - release_timer)
		
		if release_timer >= 1.0:
			queue_free()

func on_release() -> void:
	released = true
