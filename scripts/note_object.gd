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

var hold_mesh : MeshInstance3D;

func init(column_ind : int, n_time : float, n_length : float, n_is_hold : bool, hold_length) -> void:
	main = $Main
	hold = $Hold
	
	column = column_ind
	time = n_time
	length = n_length
	is_hold = n_is_hold
	
	main.scale = Vector3(NoteInfo.NOTE_WIDTH, NoteInfo.NOTE_HEIGHT, NoteInfo.NOTE_BASE_LENGTH)
	
	if is_hold:
		hold.visible = true
		hold.scale = Vector3(NoteInfo.HOLD_WIDTH, NoteInfo.HOLD_HEIGHT, hold_length)
		hold_mesh = $Hold/Mesh

func set_pressed():
	pressed = true

func set_holding(n_holding : bool):
	assert(is_hold)
	holding = n_holding
	hold_mesh.set_instance_shader_parameter("holding", n_holding)

func set_missed_start():
	missed_start = true
	if is_hold:
		hold_mesh.set_instance_shader_parameter("missed", true)

func set_missed_end():
	missed_end = true
	if is_hold:
		hold_mesh.set_instance_shader_parameter("missed", true)
