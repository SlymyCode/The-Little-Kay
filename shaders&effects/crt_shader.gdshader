
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.22;
uniform float scanline_count : hint_range(100.0, 1200.0) = 450.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.0005;

// Animación
uniform float scanline_speed : hint_range(0.0, 5.0) = 0.8;
uniform float flicker_intensity : hint_range(0.0, 0.1) = 0.015;
uniform float distortion_strength : hint_range(0.0001, 0.0005) = 0.0003;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Distorsión horizontal sutil
    float distortion = sin(uv.y * 80.0 + TIME * 4.0)
        * distortion_strength;

    distortion += sin(TIME * 12.0) * distortion_strength * 0.3;

    uv.x += distortion;

    // Aberración cromática
    float r = texture(
        screen_texture,
        uv + vec2(chromatic_aberration, 0.0)
    ).r;

    float g = texture(screen_texture, uv).g;

    float b = texture(
        screen_texture,
        uv - vec2(chromatic_aberration, 0.0)
    ).b;

    vec3 col = vec3(r, g, b);

    // Scanlines animadas
    float scanline = sin(
        uv.y * scanline_count * 6.2831853
        + TIME * scanline_speed * 6.2831853
    );

    col *= 1.0 - scanline_intensity
        * (0.5 + 0.5 * scanline);

    // Parpadeo sutil
    float flicker = 1.0 - flicker_intensity
        * (0.5 + 0.5 * sin(TIME * 60.0));

    col *= flicker;

    // Viñeta
    vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
    float vignette = dot(centered_uv, centered_uv);

    col *= 1.0 - vignette_intensity * vignette * 0.5;

    COLOR = vec4(col, 1.0);
}
