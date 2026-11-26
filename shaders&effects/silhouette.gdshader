shader_type canvas_item;

// Flat one-color silhouette of a sprite (its alpha is kept). Used by the afterimages of the speed potion.
// The color is a palette color, so the color quantization does not shift it.
uniform vec3 silhouette_color = vec3(0.263, 0.400, 0.749); // #4366bf

void fragment() {
	COLOR = vec4(silhouette_color, COLOR.a);
}
