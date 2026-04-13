shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;

uniform vec4 albedo : source_color;

uniform float receptor_offset;
uniform float key_count;
uniform uint key_press;

void fragment() {
	vec4 v_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 col = albedo.rgb;
	
	float receptor_fade = 2.0;
	
	if(v_pos.z >= receptor_offset && v_pos.z <= receptor_offset + receptor_fade){
		uint column = uint(floor((1.0 - UV.x) * key_count));
		float pressed = float((key_press & (1u << column)) != 0u);
		
		float fade = 1.0 - (v_pos.z - receptor_offset) / receptor_fade;
		col = albedo.rgb + (vec3(0.059, 0.192, 0.278) * (fade * fade * pressed)) / 2.0;
	}
	
	//@TODO: Outline should be outside of field.
	float px = fwidth(UV.x);
	float thickness = 1.0 * px;
	float aa = px * 0.5;
	float edge = min(UV.x, 1.0 - UV.x);
	float outline = 1.0 - smoothstep(thickness, thickness + aa, edge);
	float receptor = 0.0;//1.0 - smoothstep(thickness, thickness + aa, UV.y + receptor_offset);
	
	//@TODO: Bg color.
	ALBEDO = vec3(clamp(outline + receptor, 0.0, 1.0));
	ALPHA = albedo.a;

	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
