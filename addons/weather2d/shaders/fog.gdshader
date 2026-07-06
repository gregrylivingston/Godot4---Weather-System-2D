shader_type canvas_item;

// Weather System 2D — distance fog / haze. A full-screen overlay, densest around the
// horizon and thinning toward the top and bottom, with a slow drift for life.

uniform float density : hint_range(0.0, 1.0) = 0.4;
uniform vec4 fog_color : source_color = vec4(0.80, 0.83, 0.87, 1.0);
uniform float horizon : hint_range(0.0, 1.0) = 0.52;
uniform float speed = 0.01;

float hash(vec2 p) {
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
	// Band peaking at the horizon.
	float band = 1.0 - clamp(abs(UV.y - horizon) / 0.34, 0.0, 1.0);
	float drift = vnoise(vec2(UV.x * 3.0 + TIME * speed, UV.y * 2.0));
	float a = density * (0.25 + 0.75 * band) * (0.7 + 0.5 * drift);
	COLOR = vec4(fog_color.rgb, clamp(a, 0.0, 1.0) * fog_color.a);
}
