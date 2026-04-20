float rand(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 bg_color(vec4 fg, vec2 uv){
	float noise = rand(fg.xy) / 255.0;
	return mix(vec3(0.051, 0.043, 0.051), vec3(0.18, 0.043, 0.078), uv.y) + noise;
}

float fade_out(float pos){
	return 1.0 - smoothstep(8.0, 20.0, pos);
}

float stripe(vec2 uv, vec2 size, float spacing, float thickness, float offset){
	float diag = step(mod(dot(uv * size, normalize(vec2(1.0))) - offset, spacing), thickness);
	return diag;
}