float rand(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 bg_color(vec4 fg, vec2 uv){
	float noise = rand(fg.xy) / 255.0;
	return mix(vec3(0.051, 0.043, 0.051), vec3(0.18, 0.043, 0.078), uv.y) + noise;
}

float fade_out(float pos){
	return 1.0 - smoothstep(15.0, 25.0, pos);
}