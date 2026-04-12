shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

uniform vec4 albedo : source_color;
instance uniform bool missed;
instance uniform bool holding;

void fragment() {
	vec4 v_pos = inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	if(v_pos.z <= -0.4999) discard; //@TODO: This might have issues
	vec2 base_uv = UV;

	ALBEDO = (albedo.rgb + (0.05 * float(holding) * float(!missed))) * (1.0 - (0.5 * float(missed)));
	
	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
