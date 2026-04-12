shader_type canvas_item;

uniform vec3 top_color : source_color;
uniform vec3 bottom_color : source_color;

float rand(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float noise = rand(FRAGCOORD.xy) / 255.0; //Subtle noise to avoid color banding.
	COLOR = vec4(mix(top_color, bottom_color, UV.y) + noise, 1.0);
}