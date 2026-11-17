shader_type canvas_item;

// --- Uniforms --- //
uniform vec4 shine_color: source_color = vec4(1.0, 1.0, 1.0, 0.5);

// Si está activo, usa el tamaño real de la textura (16x16 en tu caso)
uniform bool use_texture_size = true;
uniform vec2 pixel_resolution = vec2(16.0, 16.0);

uniform float line_width: hint_range(0.0, 2.0, 0.01) = 0.06;
uniform float angle: hint_range(0.0, 6.28318530718, 0.1308996939) = 0.785398163397;

uniform float speed: hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float wait_cycles: hint_range(0.0, 10.0, 0.1) = 1.0;

// Cuantos "frames" por segundo avanza el brillo (0 = movimiento continuo)
uniform float steps_per_second: hint_range(0.0, 60.0, 1.0) = 12.0;

// --- Functions --- //
vec2 rotate_precalculated(vec2 _pos, float _sine, float _cosine) {
	return vec2(_pos.x * _cosine + _pos.y * -_sine, _pos.x * _sine + _pos.y * _cosine);
}

void fragment() {
	// Resolución de la grilla de pixeles
	vec2 res = use_texture_size ? 1.0 / TEXTURE_PIXEL_SIZE : pixel_resolution;

	// UV ajustada al centro de cada pixel
	vec2 pixel_uv = (floor(UV * res) + 0.5) / res;

	// Tiempo escalonado para un movimiento tipo animación de sprites
	float t = TIME;
	if (steps_per_second > 0.0) {
		t = floor(TIME * steps_per_second) / steps_per_second;
	}

	float sine = sin(angle);
	float cosine = cos(angle);
	float len = 1.5 - max(abs(sine), abs(cosine)) + line_width;

	// Distancia del pixel al centro de la línea de brillo
	float d = rotate_precalculated(pixel_uv - vec2(0.5), sine, cosine).y
			- mod(t * speed, (len * 2.0) * wait_cycles) + len;

	// Banda dura: 1.0 dentro del ancho, 0.0 fuera (sin degradado)
	float line = step(abs(d), line_width);

	COLOR.rgb += shine_color.rgb * shine_color.a * line;
}