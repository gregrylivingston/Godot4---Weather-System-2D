shader_type canvas_item;

// Weather System 2D — moving cloud shadows on the ground/water (Phase 5).
// A full-rect overlay placed over the lower scene. Low-frequency noise drifts with the same
// `wind_dir` as the clouds, darkening the land in soft moving patches. Only below the horizon
// (the sky keeps its own cloud layer). Coverage ties it to how cloudy it is.

uniform float coverage : hint_range(0.0, 1.0) = 0.3;
uniform vec2 wind_dir = vec2(1.0, 0.0);
uniform float speed : hint_range(0.0, 0.2) = 0.03;
uniform float horizon : hint_range(0.0, 1.0) = 0.62;
uniform vec4 shadow_color : source_color = vec4(0.02, 0.03, 0.07, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.28;

const float HP = 256.0;

float hash(vec2 p) {
	p = mod(p, HP);  // bound the lattice so the hash stays precise (no drifting bands)
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

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.55;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.0 + 1.3;
		a *= 0.5;
	}
	return s;
}

void fragment() {
	// Below the horizon and cloudy enough to matter? Otherwise skip the noise.
	float below_horizon = smoothstep(horizon - 0.04, horizon + 0.10, UV.y);
	if (coverage < 0.02 || strength < 0.005 || below_horizon < 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 wdir = length(wind_dir) > 0.0001 ? normalize(wind_dir) : vec2(1.0, 0.0);
		float t = TIME * speed;
		vec2 uv = UV * vec2(3.0, 2.0) + wdir * t * 2.0;
		float n = fbm(uv);
		// More cloud → lower threshold → more of the ground falls in shadow.
		float shadow = smoothstep(0.55 - coverage * 0.45, 0.75, n);
		COLOR = vec4(shadow_color.rgb, shadow * strength * below_horizon);
	}
}
