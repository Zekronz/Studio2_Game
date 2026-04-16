extends Node3D

const FIELD_LENGTH : float = 30
const FIELD_SPAWN_POS : float = FIELD_LENGTH + 10.0
const FIELD_DESPAWN_POS : float = -5.0
const FIELD_EDGE : float = 0.02
var field_width : float = 0

const COLUMN_WIDTH : float = 0.7
var column_start : float = 0
var num_columns : int = InputHandler.key_count

const RECEPTOR_OFFSET : float = 1.0

@onready var floor_mesh : MeshInstance3D = $Floor
@onready var left_mesh : MeshInstance3D = $Left
@onready var right_mesh : MeshInstance3D = $Right
@onready var receptor_mesh : MeshInstance3D = $Receptor

const HOLD_MAT = preload("res://materials/hold_mat.tres")

var floor_mat : ShaderMaterial;

func _ready() -> void:
	floor_mat = floor_mesh.get_active_material(0)
	floor_mat.set_shader_parameter("field_edge", FIELD_EDGE)
	floor_mat.set_shader_parameter("receptor_offset", RECEPTOR_OFFSET)
	floor_mat.set_shader_parameter("key_count", num_columns)
	
	HOLD_MAT.set_shader_parameter("receptor_offset", RECEPTOR_OFFSET)
	
	update_playfield_transform()
	
func _process(_delta : float) -> void:
	pass
	
func set_key_presses(key_presses : int) -> void:
	floor_mat.set_shader_parameter("key_press", key_presses)
	
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
	
func get_column_2d_point(column : int) -> Vector2:
	assert(column >= 0 && column < num_columns)
	var p = Vector3(get_column_center(column), receptor_mesh.position.y, receptor_mesh.position.z + receptor_mesh.scale.z / 2.0)
	return round(get_viewport().get_camera_3d().unproject_position(p))
	
func get_2d_direction_right() -> Vector2:
	var p1 = get_viewport().get_camera_3d().unproject_position(Vector3(-field_width / 2.0, 0.0, 0.0))
	var p2 = get_viewport().get_camera_3d().unproject_position(Vector3(-field_width / 2.0, 0.0, FIELD_LENGTH))
	return p1.direction_to(p2)
	
func get_rightside_2d_point() -> Vector2:
	return round(get_viewport().get_camera_3d().unproject_position(Vector3(-field_width / 2.0, receptor_mesh.position.y, receptor_mesh.position.z + receptor_mesh.scale.z / 2.0)))

func update_playfield_transform() -> void:
	field_width = (COLUMN_WIDTH * num_columns) + (FIELD_EDGE * 2)
	floor_mat.set_shader_parameter("field_width", field_width)
	
	column_start = -(float(num_columns) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(num_columns % 1 == 0))
	
	floor_mesh.scale = Vector3(field_width, 1, FIELD_LENGTH - FIELD_DESPAWN_POS)
	floor_mesh.position = Vector3(0.0, 0, FIELD_DESPAWN_POS);
	
	receptor_mesh.scale = Vector3(field_width - 0.05, receptor_mesh.scale.y, receptor_mesh.scale.z)
	receptor_mesh.position = Vector3(0.0, 0.01, RECEPTOR_OFFSET - receptor_mesh.scale.z / 2.0)
	
	left_mesh.scale = Vector3(left_mesh.scale.x, left_mesh.scale.y, FIELD_LENGTH)
	left_mesh.position = Vector3((field_width / 2) + (left_mesh.scale.x / 2), left_mesh.position.y, (FIELD_LENGTH / 2))
	
	right_mesh.scale = Vector3(right_mesh.scale.x, right_mesh.scale.y, FIELD_LENGTH)
	right_mesh.position = Vector3(-(field_width / 2) - (right_mesh.scale.x / 2), right_mesh.position.y, (FIELD_LENGTH / 2))
