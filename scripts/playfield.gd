extends Node3D

var key_count : int = 4

const FIELD_LENGTH : float = 50
const FIELD_SPAWN_LENGTH : float = FIELD_LENGTH + 10.0
var field_width : float = 0

const COLUMN_WIDTH : float = 0.85
var column_start : float = 0

const RECEPTOR_OFFSET : float = 0.5

@onready var floor : Node3D = $Floor
@onready var left : Node3D = $Left
@onready var right : Node3D = $Right
@onready var receptor : Node3D = $Receptor

func _ready() -> void:
	update_playfield_transform()
	
func set_key_count(count  : int) -> void:
	assert(count > 0)
	if key_count == count:
		return
		
	key_count = count
	update_playfield_transform()
	
func get_column_center(column : int) -> float:
	assert(column >= 0 && column < key_count)
	return column_start + (float(column) * COLUMN_WIDTH)

func update_playfield_transform() -> void:
	field_width = COLUMN_WIDTH * key_count
	column_start = -(float(key_count) / 2.0 * COLUMN_WIDTH) + ((COLUMN_WIDTH / 2.0) * float(key_count % 1 == 0))
	
	floor.scale = Vector3(field_width, 1, FIELD_LENGTH)
	
	receptor.scale = Vector3(field_width, receptor.scale.y, receptor.scale.z)
	receptor.position = RECEPTOR_OFFSET * Vector3.BACK
	
	left.scale = Vector3(left.scale.x, left.scale.y, FIELD_LENGTH)
	left.position = Vector3((field_width / 2) + (left.scale.x / 2), left.position.y, (FIELD_LENGTH / 2))
	
	right.scale = Vector3(right.scale.x, right.scale.y, FIELD_LENGTH)
	right.position = Vector3(-(field_width / 2) - (right.scale.x / 2), right.position.y, (FIELD_LENGTH / 2))
