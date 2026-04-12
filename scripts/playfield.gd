extends Node3D

const FIELD_LENGTH : float = 30
const FIELD_SPAWN_POS : float = FIELD_LENGTH + 10.0
const FIELD_DESPAWN_POS : float = -5.0
var field_width : float = 0

const COLUMN_WIDTH : float = 0.7
var column_start : float = 0
var num_columns : int = InputHandler.key_count

const RECEPTOR_OFFSET : float = 1.0

@onready var floor_mesh : MeshInstance3D = $Floor
@onready var left_mesh : MeshInstance3D = $Left
@onready var right_mesh : MeshInstance3D = $Right
@onready var receptor_mesh : MeshInstance3D = $Receptor

var floor_mat : ShaderMaterial;

func _ready() -> void:
	floor_mat = floor_mesh.get_active_material(0)
	floor_mat.set_shader_parameter("receptor_offset", RECEPTOR_OFFSET)
	floor_mat.set_shader_parameter("key_count", num_columns)
	
	update_playfield_transform()
	
func _process(delta : float) -> void:
	var key_press : int = 0
	
	for key_ind in range(InputHandler.key_count):
		if InputHandler.is_column_down(key_ind):
			key_press |= (1 << key_ind)
		
	floor_mat.set_shader_parameter("key_press", key_press)
	
func set_num_columns(count : int) -> void:
	assert(count > 0)
	if num_columns == count:
		return
		
	num_columns = count
		
	floor_mat.set_shader_parameter("key_count", num_columns)
	update_playfield_transform()
	
func get_column_center(column : int) -> float:
	assert(column >= 0 && column < num_columns)
	return column_start + (float(column) * COLUMN_WIDTH)

func update_playfield_transform() -> void:
	field_width = COLUMN_WIDTH * num_columns
	column_start = -(float(num_columns) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(num_columns % 1 == 0))
	
	floor_mesh.scale = Vector3(field_width, 1, FIELD_LENGTH)
	
	receptor_mesh.scale = Vector3(field_width, receptor_mesh.scale.y, receptor_mesh.scale.z)
	receptor_mesh.position = Vector3(0.0, -0.09, RECEPTOR_OFFSET)
	
	left_mesh.scale = Vector3(left_mesh.scale.x, left_mesh.scale.y, FIELD_LENGTH)
	left_mesh.position = Vector3((field_width / 2) + (left_mesh.scale.x / 2), left_mesh.position.y, (FIELD_LENGTH / 2))
	
	right_mesh.scale = Vector3(right_mesh.scale.x, right_mesh.scale.y, FIELD_LENGTH)
	right_mesh.position = Vector3(-(field_width / 2) - (right_mesh.scale.x / 2), right_mesh.position.y, (FIELD_LENGTH / 2))
