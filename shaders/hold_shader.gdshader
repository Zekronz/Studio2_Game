shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 albedo : source_color;
uniform float receptor_offset;
instance uniform bool pressed;
instance uniform bool missed;
instance uniform bool holding;

void fragment() {
	if(!pressed){
		vec4 v_pos = inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
		if(v_pos.z <= -0.4999) discard; //@TODO: This might have issues
	}else{
		vec4 v_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
		if(v_pos.z < receptor_offset) discard;
	}

	ALBEDO = (albedo.rgb + (0.125 * float(holding) * float(!missed))) * (1.0 - (0.6 * float(missed)));
	
	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
