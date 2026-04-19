extends Node3D

#TODO: Notes:
#Experimented with effect life time. Shorter feels snappier.
#Fade curve.
#Circle vs. diamond. Burst feeling

@onready var f1 : MeshInstance3D = $Flash1
@onready var f2 : MeshInstance3D = $Flash2
@onready var f3 : MeshInstance3D = $Flash3
@onready var f4 : MeshInstance3D = $Flash4
@onready var f5 : MeshInstance3D = $Flash5

var timer1 : float = 0.0
var timer2 : float = 0.0
var timer3 : float = 0.0

const TIMER1_MUL : float = 7.0 * 0.9
const TIMER2_MUL : float = 4.0 * 0.9
const TIMER3_MUL : float = 5.5 * 0.9

func update_values() -> void:
	var ys = timeline_smooth(timer1)
	var ys3 = timeline_smooth(timer3)
	var yys = timeline_smooth(timer1 * timer1)
	var yl = timeline_linear(timer1)
	var yl3 = timeline_linear(timer3)
	
	f1.scale = Vector3((0.3 + timer2 / 1.5) * 1.25, 1.0 - timer2, 1.0)
	f3.scale = Vector3(1.027 - timer1 / 2.0, f3.scale.y, f3.scale.z)
	f4.scale = Vector3(1.027 - timer1, f4.scale.y, f4.scale.z)
	f5.scale = Vector3(0.15 + timer3 / 1.5, 0.15 + timer3 / 1.5, 1.0)
	
	set_alpha(f1, yl / 1.3)
	set_alpha(f2, yys)
	set_alpha(f3, ys * 0.7)
	set_alpha(f4, ys * 0.1)
	set_alpha(f5, ys3 * 0.3)

func _ready() -> void:
	f2.scale = Vector3(0.5, 1.0, 1.0)
	f2.set_instance_shader_parameter("albedo", Vector3(1.0, 0.608, 0.592))
	f2.set_instance_shader_parameter("uv_scale", Vector3(0.5, 1.0, 1.0))
	
	f3.scale = Vector3(1.027, 1.1, 1.0)
	f3.set_instance_shader_parameter("albedo_ind", 1)
	f3.set_instance_shader_parameter("albedo", Vector3(73.0 * 1.5 / 255.0, 20.0 / 255.0, 30.0 / 255.0))
	
	f4.scale = Vector3(1.027, 1.2, 1.0)
	f4.position += 0.5 * Vector3.DOWN
	f4.set_instance_shader_parameter("albedo_ind", 2)
	f4.set_instance_shader_parameter("albedo", Vector3(73.0*1.5 / 255.0, 20.0 / 255.0, 35.0 / 255.0))
	
	#f5.position += 0.2 * Vector3.UP;
	f5.set_instance_shader_parameter("albedo_ind", 3)
	f5.set_instance_shader_parameter("albedo", Vector3(73.0 * 1.5 / 255.0, 20.0 / 255.0, 30.0 / 255.0))
	
	update_values()
	
func _process(delta: float) -> void:
	timer1 = min(1.0, timer1 + delta * TIMER1_MUL)
	timer2 = min(1.0, timer2 + delta * TIMER2_MUL)
	timer3 = min(1.0, timer3 + delta * TIMER3_MUL)
	
	if min(timer1, timer2, timer3) >= 1.0:
		queue_free()
		
	update_values()

func timeline_linear(t : float) -> float:
	assert(t >= 0.0 && t <= 1.0)
	return (1.0 - t)

func timeline_smooth(t : float) -> float:
	assert(t >= 0.0 && t <= 1.0)
	var a = 1.3
	var b = 2.4
	var t_peak = a / (a + b)
	var max_val = (t_peak ** a) * ((1 - t_peak) ** b)
	return (t ** a) * ((1 - t) ** b) / max_val
	
func set_alpha(mesh : MeshInstance3D, alpha : float) -> void:
	mesh.set_instance_shader_parameter("alpha", alpha)
