// post_process.gdshader — grain, vignette, aberration chromatique légère (G-7).
// Plein écran sur un ColorRect (CanvasLayer 3) : lit l'image déjà rendue.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.65;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.05;
uniform float aberration : hint_range(0.0, 0.01) = 0.0016;
uniform float darkness : hint_range(0.0, 1.0) = 0.97;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - 0.5;
	// Aberration chromatique radiale, plus forte sur les bords.
	vec2 offset = centered * aberration * (0.4 + dot(centered, centered) * 3.0);
	vec3 color;
	color.r = texture(screen_texture, uv + offset).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - offset).b;
	// Vignette
	float v = 1.0 - vignette_strength * smoothstep(0.25, 0.72, length(centered));
	color *= v * darkness;
	// Grain de pellicule animé
	float n = hash(uv * vec2(1920.0, 1080.0) + vec2(TIME * 91.7, TIME * 47.3));
	color += (n - 0.5) * grain_strength;
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
