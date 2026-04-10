extends Node

enum ParseSection { NONE, DIFFICULTY, HIT_OBJECTS, TIMING_POINTS }

func load_map(filename : String, convert_hold_to_single : bool = false) -> Dictionary:
	var file = FileAccess.open(filename, FileAccess.READ)
	assert(file != null)
	
	var column_count : int = 0
	var timing_points : Array[Dictionary]
	var hit_objects = []
	
	var section = ParseSection.NONE
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
			
		if line.length() >= 2:
			if line[0] == "[" and line[-1] == "]":
				if line == "[Difficulty]":
					section = ParseSection.DIFFICULTY
				elif line == "[HitObjects]":
					section = ParseSection.HIT_OBJECTS
				elif line == "[TimingPoints]":
					section = ParseSection.TIMING_POINTS
				else:
					section = ParseSection.NONE
					
				continue
			
		if section == ParseSection.DIFFICULTY:
			var key_value = line.split(":", false)
			assert(key_value.size() == 2)
			
			if key_value[0].strip_edges() == "CircleSize":
				assert(key_value[1].is_valid_int())
				var count = key_value[1].to_int()
				assert(count > 0)
				column_count = count;
				
				for i in range(count):
					hit_objects.append([])
			
		elif section == ParseSection.TIMING_POINTS:
			var params = line.split(",", true)
			assert(params.size() == 8)
			
			assert(params[0].is_valid_int())
			assert(params[1].is_valid_float())
			#TODO: Time signature?
			assert(params[6].is_valid_int())
			
			if params[6].to_int() == 0: #Ignore inherited timing points.
				continue
				
			#TODO: Starting bpm?
			var time = float(params[0].to_int()) / 1000.0
			var beat_length = params[1].to_float() / 1000.0
			
			timing_points.append({ "time": time, "beat_length": beat_length})
		
		elif section == ParseSection.HIT_OBJECTS:
			assert(column_count > 0)
			
			var params = line.split(",", true)
			assert(params.size() >= 4)
			
			assert(params[0].is_valid_int())
			var col_val = params[0].to_int()
			var col : int = floor(float(col_val) * float(column_count) / 512.0)
			col = clamp(col, 0, column_count - 1)
			
			assert(params[2].is_valid_int())
			var start_time = float(params[2].to_int()) / 1000.0
			var end_time = -1
			
			assert(params[3].is_valid_int())
			var type = params[3].to_int()
			var is_hold : bool = (not convert_hold_to_single) and (type & (1 << 7))
			
			if is_hold:
				assert(params.size() >= 6)
				var temp = params[5].split(":", true)
				assert(temp.size() > 0)
				assert(temp[0].is_valid_int())
				
				end_time = float(temp[0].to_int()) / 1000.0
				assert(end_time > start_time)
			
			hit_objects[col].append({ "column": col, "start_time": start_time, "end_time": end_time, "is_hold": is_hold })
	
	file.close()
	
	return {
		"key_count": column_count,
		"timing_points": timing_points,
		"hit_objects": hit_objects
	}
