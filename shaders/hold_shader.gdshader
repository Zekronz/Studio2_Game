shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

#include "common.gdshaderinc"

uniform vec4 colors[9] : source_color;
instance uniform uint color_ind;
uniform float radius : hint_range(0.0, 1.0);
uniform float border_thickness : hint_range(0.0, 0.1);
uniform float border_glow : hint_range(1.0, 20.0);
uniform float stripe_thickness : hint_range(0.0, 1.0) = 0.1;
uniform float stripe_spacing : hint_range(0.0, 5.0) = 0.1;
uniform float stripe_intesnity : hint_range(0.0, 1.0) = 0.2;

instance uniform vec2 size = vec2(0.9, 3.0);
uniform float receptor_offset;

instance uniform float pressed;
instance uniform float missed;
instance uniform float holding;

float round_dist(vec2 uv){
	vec2 half = size * 0.5;
	vec2 q = (uv * size) - half;
	float top = step(0.0, q.y);
	
	vec2 round_d = abs(q) - (half - radius);
	float round_dist = length(max(round_d, 0.0)) - radius;
	
	vec2 rect_d = abs(q) - half;
	float rect_dist = max(rect_d.x, rect_d.y);

	return mix(rect_dist, round_dist, top);
}

float border_mix(float dist){
	return step(dist, 0.0) - step(dist, -min(border_thickness, radius));
}

vec4 fill_col(vec2 uv){
	float p = min(uv.x, 1.0 - uv.x);
	float a = smoothstep(0.0, 0.2, p);
	vec4 col = mix(colors[color_ind], colors[color_ind + 1U], pow(a, 0.6));
	return col;
}

void fragment() {
	float dist = round_dist(UV);
	if(dist > 0.0) discard;
	
	vec4 v_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	
	vec4 inner = fill_col(UV);
	vec3 border = (colors[color_ind + 2U].rgb * colors[color_ind + 2U].a * border_mix(dist));
	
	if(pressed < 0.5){
		//vec4 v_pos = inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
		//if(v_pos.z <= -0.4999) discard; //@TODO: This might have issues
	}else{
		if(v_pos.z < receptor_offset) discard;
	}

	ALBEDO = clamp(inner.rgb, 0.0, 1.0) + border * border_glow;
	ALPHA = clamp(inner.a + (holding * 0.4), 0.0, 1.0); //@TODO: Animate?
	ALPHA *= max(0.25, (1.0 - missed));
	ALPHA *= fade_out(v_pos.z);
	
	ALBEDO += stripe(UV, size, stripe_spacing, stripe_thickness, 0.0) * (colors[color_ind + 2U].rgb * stripe_intesnity);
}
