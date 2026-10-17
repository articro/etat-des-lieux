// photo_develop.gdshader — développement d'une photo instantanée (G-5).
// Le paramètre `development` va de 0 (latent, laiteux) à 1 (image révélée).
// Module Gameplay ; voir scenes/player/photo_in_hand.gd.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D photo_tex : source_color, filter_linear, repeat_disable;
uniform float development : hint_range(0.0, 1.0) = 1.0;
uniform bool has_texture = true;

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	// Marge d'une photo instantanée : fine en haut et sur les côtés,
	// épaisse en bas (zone où l'on écrit).
	float border_x = 0.06;
	float border_top = 0.06;
	float border_bottom = 0.17;
	vec3 paper = vec3(0.87, 0.855, 0.80);
	vec3 color = paper;

	bool inside = uv.x > border_x && uv.x < 1.0 - border_x
		&& uv.y > border_top && uv.y < 1.0 - border_bottom;
	if (inside) {
		vec2 puv = vec2(
			(uv.x - border_x) / (1.0 - 2.0 * border_x),
			(uv.y - border_top) / (1.0 - border_top - border_bottom)
		);
		vec3 src = has_texture ? texture(photo_tex, puv).rgb : vec3(0.42, 0.42, 0.44);
		float g = dot(src, vec3(0.299, 0.587, 0.114));
		vec3 developing = mix(vec3(g) * 0.9, src, smoothstep(0.1, 0.85, development));
		vec3 latent = vec3(0.60, 0.60, 0.58)
			+ (grain(puv * vec2(320.0, 180.0)) - 0.5) * 0.05;
		color = mix(latent, developing, smoothstep(0.0, 0.5, development));
		vec2 centered = puv - 0.5;
		float vig = 1.0 - dot(centered, centered) * 0.55;
		color *= vig;
		color += (grain(puv * vec2(640.0, 360.0)) - 0.5) * 0.035;
		color = clamp(color, 0.0, 1.0);
	}

	ALBEDO = color;
}
