
shader_type canvas_item;

uniform float sway_speed : hint_range(0.0, 10.0) = 2.0;
uniform float sway_amount : hint_range(0.0, 20.0) = 3.0;
uniform float sway_frequency : hint_range(0.0, 10.0) = 1.0;

// Vertical position where the sway starts.
// 0.0 = top, 1.0 = bottom.
uniform float pivot : hint_range(0.0, 1.0) = 1.0;

void vertex() {
    float height = 1.0 - UV.y;

    // Sway increases towards the top of the sprite.
    float sway = sin(TIME * sway_speed + UV.y * sway_frequency)
        * sway_amount * height;

    // Snap displacement to whole pixels.
    sway = floor(sway + 0.5);

    VERTEX.x += sway;
}
