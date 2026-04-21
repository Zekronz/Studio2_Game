extends Camera3D

var start_fov : float
var start_pos : Vector3

const SHAKE_TIME = 0.1
var shake_timer = 0
var shake_amount = 0.3
var shake_offset : Vector3

var pos_offset : Vector3 = Vector3.ZERO

func _ready() -> void:
	start_fov = fov
	start_pos = position

func _process(delta: float) -> void:
	shake_timer = max(0.0, shake_timer - delta)
	
	var off = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	shake_offset += (off - shake_offset) * min((delta * 35.0), 0.3)
	
	position = start_pos + pos_offset + shake_offset * shake_amount * (shake_timer / SHAKE_TIME)

func shake() -> void:
	shake_timer = SHAKE_TIME
	shake_offset = Vector3.ZERO

func set_fov_offset(fov_offset : float) -> void:
	fov = start_fov + fov_offset
	
func set_pos_offset(offset : Vector3) -> void:
	pos_offset = offset;
