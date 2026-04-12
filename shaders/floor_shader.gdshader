shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

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
	
	ALBEDO = col;

	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
