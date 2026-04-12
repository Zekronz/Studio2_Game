extends Node

const NOTE_WIDTH : float = 0.65
const NOTE_HEIGHT : float = 0.07
const NOTE_BASE_LENGTH : float = 0.4

const HOLD_WIDTH : float = 0.6
const HOLD_HEIGHT : float = NOTE_HEIGHT - 0.06

#func get_end_point(start_time : float, end_time : float = -1) -> float:
	#if end_time <= 0.0:
		#return position.z + NoteInfo.NOTE_BASE_LENGTH
		
	#return position.z + hold.scale.z
