shader_type canvas_item;

void fragment() {
	COLOR.rgb /= max(COLOR.a, 0.0001);
}