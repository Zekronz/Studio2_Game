extends Node3D

#TODO: Notes:
#Experimented with effect life time. Shorter feels snappier.
#Fade curve.

@onready var f1 : MeshInstance3D = $Flash1
@onready var f2 : MeshInstance3D = $Flash2
@onready var f3 : MeshInstance3D = $Flash3

var timer : float = 0.0
var time_mul : float = 6.0

func update_values() -> void:
	var y = timeline(timer)
	var yy = timeline(timer * timer)
	
	set_alpha(f1, yy)
	f1.scale = Vector3(0.7 + yy / 2.0, 1.0, 1.0)
	
	set_alpha(f2, yy)
	set_alpha(f3, y)

func _ready() -> void:
	f2.scale = Vector3(0.5, 1.0, 1.0)
	f2.set_instance_shader_parameter("albedo", Vector3(1.0, 0.608, 0.592))
	f2.set_instance_shader_parameter("uv_scale", Vector3(0.5, 1.0, 1.0))
	
	f3.scale = Vector3(1.02, 0.8, 1.0)
	f3.set_instance_shader_parameter("albedo_ind", 1)
	f3.set_instance_shader_parameter("albedo", Vector3(1.0, 0.31, 0.404))
	
	update_values()
	
func _process(delta: float) -> void:
	timer = min(1.0, timer + delta * time_mul)
	if timer >= 1.0:
		queue_free()
		
	update_values()

func timeline(t : float) -> float:
	assert(t >= 0.0 && t <= 1.0)
	return (1.0 - t)
	#var a = 1.3
	#var b = 2.4
	#var t_peak = a / (a + b)
	#var max_val = (t_peak ** a) * ((1 - t_peak) ** b)
	#return (t ** a) * ((1 - t) ** b) / max_val
	
func set_alpha(mesh : MeshInstance3D, alpha : float) -> void:
	mesh.set_instance_shader_parameter("alpha", alpha)
