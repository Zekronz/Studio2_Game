shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;

uniform vec4 albedo : source_color;
uniform vec3 highlight : source_color;
uniform vec4 sep_color : source_color;

uniform float field_width;
uniform float field_edge;
uniform float receptor_offset;
uniform float receptor_fade;
uniform float key_count;
uniform uint key_press;

float outline(float uv_x, float pos, float thickness){
	float px = fwidth(uv_x);
	thickness *= px;
	float aa = px * 0.5;
	float dist = abs(uv_x - pos);//min(uv_x, 1.0 - uv_x);
	return 1.0 - smoothstep(thickness, thickness + aa, dist);
}

void fragment() {
	vec4 v_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 col = albedo.rgb;
	
	float fe = field_edge / field_width;
	float fw = 1.0 - fe * 2.0;
	float fx = (UV.x - fe) / fw;
	
	if(v_pos.z >= receptor_offset){
		for(float i = 1.0; i < key_count; i += 1.0){
			float sep = outline(1.0 - fx, i / key_count, 0.4);
			col += (sep_color.rgb) * sep * sep_color.a;
		}
	}
	
	if(v_pos.z >= receptor_offset && v_pos.z <= receptor_offset + receptor_fade){
		if(fx >= 0.0 && fx <= 1.0){
			uint column = uint(floor((1.0 - fx) * key_count));
			float pressed = float((key_press & (1u << column)) != 0u);
			
			float fade = 1.0 - (v_pos.z - receptor_offset) / receptor_fade;
			vec3 h = (highlight * (fade * fade * pressed)) / 2.0;
			col += h;
		}
	}
	
	//@TODO: Bg color.
	float left = outline(UV.x, 1.0, 1.0);
	float right = outline(UV.x, 0.0, 1.0);
	ALBEDO = vec3(clamp(col + left + right, 0.0, 1.0));
	ALPHA = albedo.a;

	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
