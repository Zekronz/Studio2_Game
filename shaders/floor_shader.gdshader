shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;

#include "common.gdshaderinc"

uniform vec4 albedo : source_color;
uniform vec3 highlight : source_color;
uniform vec4 sep_color : source_color;

uniform float field_width;
uniform float field_edge;
uniform float fade_out_start;
uniform float fade_out_end;
uniform vec4 receptor_col : source_color;
uniform float receptor_offset;
uniform float receptor_thickness;
uniform float receptor_fade;
uniform float key_count;
uniform float key_highlight[7];
uniform float bar_length;
uniform float bar_offset;
uniform float bar_thickness = 0.1;
uniform vec4 bar_color : source_color;

float outline(float uv_x, float pos, float thickness){
	float px = fwidth(uv_x);
	thickness *= px;
	float aa = px * 0.5;
	float dist = abs(uv_x - pos);//min(uv_x, 1.0 - uv_x);
	return 1.0 - smoothstep(thickness, thickness + aa, dist);
}

float receptor(float pos){
	return (step(receptor_offset - receptor_thickness, pos)) * (1.0 - step(receptor_offset + 0.001, pos));
}

float bar(float uv_y, float pos){
	float t = fwidth(pos) * bar_thickness;
	return step(mod(pos - bar_offset + (t * 0.5), bar_length), t) * float((bar_length > 0.0));
}

void fragment() {
	vec4 v_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 col = albedo.rgb;
	
	float past_receptor = float(v_pos.z < receptor_offset);
	
	float fe = field_edge / field_width;
	float fw = 1.0 - fe * 2.0;
	float fx = (UV.x - fe) / fw;
	
	//if(v_pos.z >= receptor_offset){
		for(float i = 1.0; i < key_count; i += 1.0){
			float sep = outline(1.0 - fx, i / key_count, 0.4);
			col += (sep_color.rgb) * sep * sep_color.a;
		}
	//}
	
	if(v_pos.z >= receptor_offset && v_pos.z <= receptor_offset + receptor_fade){
		if(fx >= 0.0 && fx <= 1.0){
			uint column = uint(floor((1.0 - fx) * key_count));
			
			float fade = 1.0 - (v_pos.z - receptor_offset) / receptor_fade;
			vec3 h = (highlight * (fade * fade * float(key_highlight[column]))) / 2.0;
			col += h;
		}
	}
	
	float left = outline(UV.x, 1.0, 1.0);
	float right = outline(UV.x, 0.0, 1.0);
	
	float receptor_v = receptor(v_pos.z);
	vec3 final = mix(col, receptor_col.rgb, receptor_v);
	final = mix(final, bar_color.rgb, bar(UV.y, v_pos.z) * bar_color.a * (1.0 - past_receptor));
	final = clamp(final + left + right, 0.0, 1.0);
	if(receptor_v > 0.5) final *= 2.0;
	
	ALBEDO = final;
	ALPHA = max(left + right, mix(albedo.a, receptor_col.a, receptor_v)) * fade_out(v_pos.z);
}