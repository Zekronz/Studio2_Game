extends Node3D

var key_count : int = 4

const FIELD_LENGTH : float = 50
const FIELD_SPAWN_POS : float = FIELD_LENGTH + 10.0
const FIELD_DESPAWN_POS : float = -10.0
var field_width : float = 0

const COLUMN_WIDTH : float = 0.85
var column_start : float = 0

const RECEPTOR_OFFSET : float = 0.5

@onready var floor_mesh : MeshInstance3D = $Floor
@onready var left_mesh : MeshInstance3D = $Left
@onready var right_mesh : MeshInstance3D = $Right
@onready var receptor_mesh : MeshInstance3D = $Receptor

var floor_mat : ShaderMaterial;

func _ready() -> void:
	floor_mat = floor_mesh.get_active_material(0)
	floor_mat.set_shader_parameter("receptor_offset", RECEPTOR_OFFSET)
	floor_mat.set_shader_parameter("key_count", key_count)
	
	update_playfield_transform()
	
func set_key_count(count : int) -> void:
	assert(count > 0)
	if key_count == count:
		return
		
	key_count = count
	floor_mat.set_shader_parameter("key_count", key_count)
	update_playfield_transform()
	
func set_key_press(key_press : int) -> void:
	floor_mat.set_shader_parameter("key_press", key_press)
	
func get_column_center(column : int) -> float:
	assert(column >= 0 && column < key_count)
	return column_start + (float(column) * COLUMN_WIDTH)

func update_playfield_transform() -> void:
	field_width = COLUMN_WIDTH * key_count
	column_start = -(float(key_count) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(key_count % 1 == 0))
	
	floor_mesh.scale = Vector3(field_width, 1, FIELD_LENGTH)
	
	receptor_mesh.scale = Vector3(field_width, receptor_mesh.scale.y, receptor_mesh.scale.z)
	receptor_mesh.position = RECEPTOR_OFFSET * Vector3.BACK
	
	left_mesh.scale = Vector3(left_mesh.scale.x, left_mesh.scale.y, FIELD_LENGTH)
	left_mesh.position = Vector3((field_width / 2) + (left_mesh.scale.x / 2), left_mesh.position.y, (FIELD_LENGTH / 2))
	
	right_mesh.scale = Vector3(right_mesh.scale.x, right_mesh.scale.y, FIELD_LENGTH)
	right_mesh.position = Vector3(-(field_width / 2) - (right_mesh.scale.x / 2), right_mesh.position.y, (FIELD_LENGTH / 2))
