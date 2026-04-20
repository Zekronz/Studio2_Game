extends Node3D

const FIELD_LENGTH : float = 25
const FIELD_SPAWN_POS : float = FIELD_LENGTH + 10.0
const FIELD_DESPAWN_POS : float = -5.0
const FIELD_EDGE : float = 0.02
var field_width : float = 0

const COLUMN_WIDTH : float = 0.7
var column_start : float = 0
var num_columns : int = InputHandler.key_count

const RECEPTOR_OFFSET : float = 0.7

var key_press : Array[bool] = []
var key_highlight : Array[float] = []

@onready var floor_mesh : MeshInstance3D = $Floor
@onready var left_mesh : MeshInstance3D = $Left
@onready var right_mesh : MeshInstance3D = $Right

const NOTE_MAT = preload("res://materials/note_mat.tres")
const HOLD_MAT = preload("res://materials/hold_mat.tres")

var floor_mat : ShaderMaterial;

func _ready() -> void:
	floor_mat = floor_mesh.get_active_material(0)
	floor_mat.set_shader_parameter("field_edge", FIELD_EDGE)
	floor_mat.set_shader_parameter("receptor_offset", RECEPTOR_OFFSET)
	floor_mat.set_shader_parameter("key_count", num_columns)
	floor_mat.set_shader_parameter("bar_length", 0.0)
	floor_mat.set_shader_parameter("bar_offset", 0.0)
	
	NOTE_MAT.set_shader_parameter("size", Vector2(NoteInfo.HOLD_WIDTH, NoteInfo.NOTE_BASE_LENGTH))
	HOLD_MAT.set_shader_parameter("receptor_offset", RECEPTOR_OFFSET)
	
	update_playfield_transform()
	
	key_press.resize(InputHandler.MAX_SUPPORTED_KEY_COUNT)
	key_highlight.resize(InputHandler.MAX_SUPPORTED_KEY_COUNT)
	
func _process(delta : float) -> void:
	for i in InputHandler.key_count:
		if key_press[i]:
			key_highlight[i] = min(key_highlight[i] + delta * 80.0, 1.0)
		else:
			key_highlight[i] = max(key_highlight[i] - delta * 10.0, 0.0)
			
	floor_mat.set_shader_parameter("key_highlight", key_highlight)
	
func set_key_press(column : int, pressed : bool) -> void:
	assert(column >= 0 && column < InputHandler.MAX_SUPPORTED_KEY_COUNT)
	key_press[column] = pressed
	
func set_num_columns(count : int) -> void:
	assert(count > 0)
	if num_columns == count:
		return
		
	num_columns = count
		
	floor_mat.set_shader_parameter("key_count", num_columns)
	update_playfield_transform()
	
func get_column_center(column : int) -> float:
	assert(column >= 0 && column < num_columns)
	return column_start + (float((num_columns - column - 1)) * COLUMN_WIDTH)
	
func get_column_2d_point(column : int, z_offset : float = 0.0) -> Vector2:
	assert(column >= 0 && column < num_columns)
	var p = Vector3(get_column_center(column), 0.0, RECEPTOR_OFFSET + z_offset)
	return get_viewport().get_camera_3d().unproject_position(p)
	
func get_2d_direction_right() -> Vector2:
	var p1 = get_viewport().get_camera_3d().unproject_position(Vector3(-field_width / 2.0, 0.0, 0.0))
	var p2 = get_viewport().get_camera_3d().unproject_position(Vector3(-field_width / 2.0, 0.0, FIELD_LENGTH))
	return p1.direction_to(p2)
	
func get_rightside_2d_point() -> Vector2:
	return get_viewport().get_camera_3d().unproject_position(Vector3(-field_width / 2.0, 0.0, RECEPTOR_OFFSET))

func update_playfield_transform() -> void:
	field_width = (COLUMN_WIDTH * num_columns) + (FIELD_EDGE * 2)
	
	column_start = -(float(num_columns) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(num_columns % 1 == 0))
	
	floor_mesh.scale = Vector3(field_width, 1, FIELD_LENGTH - FIELD_DESPAWN_POS)
	floor_mesh.position = Vector3(0.0, 0, FIELD_DESPAWN_POS);
	
	left_mesh.scale = Vector3(left_mesh.scale.x, left_mesh.scale.y, FIELD_LENGTH)
	left_mesh.position = Vector3((field_width / 2) + (left_mesh.scale.x / 2), left_mesh.position.y, (FIELD_LENGTH / 2))
	
	right_mesh.scale = Vector3(right_mesh.scale.x, right_mesh.scale.y, FIELD_LENGTH)
	right_mesh.position = Vector3(-(field_width / 2) - (right_mesh.scale.x / 2), right_mesh.position.y, (FIELD_LENGTH / 2))

	floor_mat.set_shader_parameter("field_size", Vector2(floor_mesh.scale.x, floor_mesh.scale.z))

func set_bar_length(bar_length : float) -> void:
	floor_mat.set_shader_parameter("bar_length", bar_length)

func set_bar_offset(bar_offset : float) -> void:
	floor_mat.set_shader_parameter("bar_offset", bar_offset)
