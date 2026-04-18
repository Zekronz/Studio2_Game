shader_type canvas_item;

#include "common.gdshaderinc"

void fragment() {
	COLOR = vec4(bg_color(FRAGCOORD, UV), 1.0);
}