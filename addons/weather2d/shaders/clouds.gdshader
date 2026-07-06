shader_type canvas_item;

// Weather System 2D — layered volumetric clouds (fBm + ridged detail + shading), adapted
// from the "Cloudy skies" technique. Overlay over the sky gradient, behind the terrain.
// A horizon perspective compresses the clouds toward the horizon so they recede naturally.
// Driven by a CloudPreset via WeatherScene.

uniform float coverage : hint_range(-0.4, 1.0) = 0.25; // higher = more of the sky is cloud
uniform float cloud_scale = 1.4;
// Overall pace: clouds slowly billow/evolve in place with only a gentle horizontal drift.
uniform float speed : hint_range(0.0, 0.2) = 0.03;
uniform float cloud_dark : hint_range(0.0, 1.0) = 0.4;  // base/shadow brightness
uniform float cloud_light : hint_range(0.0, 1.0) = 0.85; // highlight brightness
uniform float density : hint_range(0.0, 1.0) = 0.85;    // overall opacity
uniform float softness : hint_range(0.0, 1.0) = 0.5;    // wispy (1) … crisp cumulus (0)
uniform float detail : hint_range(0.0, 1.0) = 0.5;      // ridged detail strength
uniform float horizon : hint_range(0.3, 1.0) = 0.62;    // sky/ground line in UV.y
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Phase 5 — the shared sun model + wind. `sun_uv` lights the cloud edge that faces the sun;
// `wind_dir` sets the drift direction (was a fixed rightward push).
uniform vec2 sun_uv = vec2(0.5, 0.18);
uniform vec4 sun_tint : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform vec2 wind_dir = vec2(1.0, 0.0);

const mat2 m = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	const float K1 = 0.366025404;
	const float K2 = 0.211324865;
	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
	return dot(n, vec3(70.0));
}

// Time churns the octaves (each one drifts differently after the m rotation), so the clouds
// slowly billow and evolve in place rather than sliding across the screen.
float fbm(vec2 n, float t) {
	float total = 0.0;
	float amp = 0.6;
	for (int i = 0; i < 6; i++) {
		total += noise(n + vec2(t, t * 0.7)) * amp;
		n = m * n + t * 0.35;
		amp *= 0.5;
	}
	return total;
}

void fragment() {
	// Clouds fill the sky and fade out only in the band just above the horizon.
	float sky = smoothstep(horizon, horizon - 0.2, UV.y);
	if (sky <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		// Mild perspective: clouds pack a little tighter toward the horizon.
		float depth = clamp((horizon - UV.y) / horizon, 0.03, 1.0);
		vec2 uv = UV * vec2(2.2, 1.4) * cloud_scale;
		uv.y /= mix(0.6, 1.0, depth);
		float t = TIME * speed;
		// Drift along the wind (falls back to a gentle rightward push for a zero vector).
		vec2 wdir = length(wind_dir) > 0.0001 ? normalize(wind_dir) : vec2(1.0, 0.0);
		uv += wdir * t * 0.9; // slow translation; the rest is evolution in place

		// Base shape (0..1) plus billowy ridged detail — both evolve slowly over time.
		float base = fbm(uv * 3.2, t) * 0.5 + 0.5;
		// Density a short step toward the sun: where the cloud thins toward the sun, this
		// pixel's edge faces the light and reads brighter (a cheap directional shading term).
		vec2 sdir = normalize((sun_uv - UV) + vec2(0.0001, 0.0001));
		float toward_sun = fbm((uv - sdir * 0.10) * 3.2, t) * 0.5 + 0.5;
		float sun_rim = clamp((base - toward_sun) * 2.2, 0.0, 1.0);
		float r = 0.0;
		vec2 ruv = uv * 2.0 + base;
		float w = 0.6;
		for (int i = 0; i < 4; i++) {
			r += abs(w * noise(ruv));
			ruv = m * ruv + t * 0.5;
			w *= 0.55;
		}

		float shape = base + coverage + r * detail * 0.5;
		// Softness widens the edge (wispy) vs sharpens it (defined cumulus).
		float edge = mix(0.04, 0.30, softness);
		float a = smoothstep(0.6 - edge, 0.6 + edge, shape) * density * sky;

		// Lit tops, shadowed base; tinted by the time-of-day cloud color.
		float shade = clamp(cloud_dark + cloud_light * (base * 0.6 + 0.4 + r * 0.35), 0.0, 1.0);
		vec3 rgb = cloud_color.rgb * shade;
		// The sun-facing edge picks up the sun's tint.
		rgb += sun_tint.rgb * sun_rim * 0.5;
		COLOR = vec4(rgb, clamp(a, 0.0, 1.0));
	}
}
