shader_type canvas_item;

// Weather System 2D — distance fog / haze. A full-screen overlay, densest around the
// horizon and thinning toward the top and bottom, with a slow drift for life.

uniform float density : hint_range(0.0, 1.0) = 0.4;
uniform vec4 fog_color : source_color = vec4(0.80, 0.83, 0.87, 1.0);
uniform float horizon : hint_range(0.0, 1.0) = 0.52;
uniform float speed = 0.01;
// 0 = low graphics (flat band, no drifting noise), 1 = full quality.
uniform int quality = 1;

const float HP = 256.0;

float hash(vec2 p) {
	p = mod(p, HP);  // keep lattice coords small so the hash stays precise (no drifting bands)
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	if (density < 0.005) {          // nothing to draw — skip the noise entirely
		COLOR = vec4(0.0);
	} else {
		// Band peaking at the horizon.
		float band = 1.0 - clamp(abs(UV.y - horizon) / 0.34, 0.0, 1.0);
		// Low graphics: a flat band (no per-pixel drifting noise).
		float drift = quality == 1 ? vnoise(vec2(UV.x * 3.0 + TIME * speed, UV.y * 2.0)) : 0.5;
		float a = density * (0.25 + 0.75 * band) * (0.7 + 0.5 * drift);
		COLOR = vec4(fog_color.rgb, clamp(a, 0.0, 1.0) * fog_color.a);
	}
}
