shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

#include "common.gdshaderinc"

uniform vec4 colors[9] : source_color;
instance uniform uint color_ind;
uniform float radius : hint_range(0.0, 1.0);
uniform float border_thickness : hint_range(0.0, 0.1);
uniform float border_glow : hint_range(1.0, 20.0);
uniform vec4 hit_bar_color : source_color;
uniform float hit_bar_size : hint_range(0.0, 1.0);
uniform vec2 size = vec2(1.0, 0.5);

float round_dist(vec2 uv){
	vec2 p = uv * size;
	vec2 half = size * 0.5;
	vec2 d = abs(p - half) - (half - radius);
	return length(max(d, 0.0)) - radius;
}

float border_mix(float dist){
	return step(dist, 0.0) - step(dist, -min(border_thickness, radius));
}

vec3 fill_col(vec2 uv){
	float p = min(uv.x, 1.0 - uv.x);
	float a = smoothstep(0.0, 0.2, p);
	return mix(colors[color_ind].rgb, colors[color_ind + 1U].rgb, pow(a, 0.6));
}

float hit_bar_mix(vec2 uv){
	return 1.0 - step(hit_bar_size, uv.y * size.y);
}

void fragment() {
	float dist = round_dist(UV);
	if(dist > 0.0) discard;
	
	vec3 inner = fill_col(UV) + (hit_bar_color.rgb * hit_bar_mix(UV) * hit_bar_color.a);
	vec3 border = (colors[color_ind + 2U].rgb * colors[color_ind + 2U].a * border_mix(dist));
	
	ALBEDO = clamp(inner, 0.0, 1.0) + border * border_glow;
	
	vec4 v_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	ALPHA = fade_out(v_pos.z);
}
