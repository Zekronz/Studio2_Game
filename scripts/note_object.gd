extends Node3D

var column : int = 0
var time : float = 0
var length : float = -1
var is_hold : bool = false

var pressed : bool = false
var holding : bool = false
var active : bool = true
var missed_start : bool = false
var missed_end : bool = false

var main : Node3D
var hold : Node3D

var hold_mesh : MeshInstance3D
var hold_effect : Node3D

func init(column_ind : int, n_time : float, n_length : float, n_is_hold : bool, hold_length) -> void:
	main = $Main
	hold = $Hold
	
	column = column_ind
	time = n_time
	length = n_length
	is_hold = n_is_hold
	
	var color_ind = NoteInfo.COLUMN_COLOR[InputHandler.key_count - 1][column_ind]
	
	main.scale = Vector3(NoteInfo.NOTE_WIDTH, 1.0, NoteInfo.NOTE_BASE_LENGTH)
	$Main/Mesh.set_instance_shader_parameter("color_ind", color_ind);
	
	if is_hold:
		hold.visible = true
		hold.scale = Vector3(NoteInfo.HOLD_WIDTH, 1.0, hold_length)
		hold_mesh = $Hold/Mesh
		hold_mesh.set_instance_shader_parameter("size", Vector2(NoteInfo.HOLD_WIDTH, hold_length))
		hold_mesh.set_instance_shader_parameter("color_ind", color_ind)

func set_pressed() -> void:
	pressed = true
	
	if is_hold:
		main.visible = false
		hold_mesh.set_instance_shader_parameter("pressed", 1.0)

func set_holding(n_holding : bool) -> void:
	assert(is_hold)
	if holding == n_holding:
		return
		
	holding = n_holding
	hold_mesh.set_instance_shader_parameter("holding", float(n_holding))
	
	if not holding:
		assert(hold_effect != null)
		hold_effect.on_release()
		hold_effect = null

func set_missed_start() -> void:
	missed_start = true
	if is_hold:
		hold_mesh.set_instance_shader_parameter("missed", 1.0)

func set_missed_end() -> void:
	missed_end = true
	if is_hold:
		hold_mesh.set_instance_shader_parameter("missed", 1.0)
