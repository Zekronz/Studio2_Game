shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded, depth_test_disabled;

instance uniform uint albedo_ind = 0;
instance uniform vec3 albedo = vec3(1.0);
instance uniform float alpha = 1.0;
instance uniform vec3 uv_scale = vec3(1.0);

uniform sampler2D texture_albedo[4] : source_color, filter_linear_mipmap, repeat_disable;
uniform ivec2 albedo_texture_size;

//uniform vec3 uv1_offset;

void vertex() {
	UV = UV * uv_scale.xy;// + uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo[albedo_ind], base_uv);
	ALBEDO = albedo * albedo_tex.rgb;
	ALPHA *= albedo_tex.a * alpha;
	
	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
