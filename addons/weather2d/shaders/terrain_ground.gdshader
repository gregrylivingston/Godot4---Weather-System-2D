shader_type canvas_item;

// Weather System 2D — sandy ground / beach for a WaterBody2D to wash over.
// Driven by TerrainBand2D (GROUND role) from a TerrainLayer.
//
// Composition: place this BEHIND a WaterBody2D (OCEAN_BEACH). The sand fills below a
// gently wavy beach line; the water layer, animating its own waterline on top, alternately
// covers and exposes the sand — that overlap is the "ocean washing into the sand".
//
// Keep `coast_level` near the water's `level`, and `wave_height` / `wave_frequency` equal
// to the water's, so the two coastlines share a shape.

uniform vec4 near_color : source_color = vec4(0.68, 0.60, 0.44, 1.0); // wet / lower sand
uniform vec4 far_color : source_color = vec4(0.86, 0.78, 0.60, 1.0);  // dry / upper sand
uniform float coast_level : hint_range(0.0, 1.0) = 0.55;
uniform float wave_height : hint_range(0.0, 0.2) = 0.02;
uniform float wave_frequency = 8.0;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.08;
uniform float seed = 0.0;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D value noise for sand grain.
float vnoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Same sum-of-sines the water uses, so the beach line matches the waterline shape.
float surface_wave(float x) {
	float w = sin(x * wave_frequency);
	w += 0.5 * sin(x * wave_frequency * 2.17);
	w += 0.25 * sin(x * wave_frequency * 0.53);
	return w / 1.75;
}

void fragment() {
	vec2 uv = UV;

	// Bound the seed: large values fed into sin() lose float precision.
	float sd = mod(seed, 997.0);

	// Static wavy beach line (slightly below the water's mean level so sand shows when
	// the water recedes). Combines the shared coastline sine with a little noise.
	float beach = coast_level
		- surface_wave(uv.x) * wave_height * 0.5
		+ (hash1(floor(uv.x * 40.0) + sd) - 0.5) * 0.01;

	if (uv.y < beach) {
		COLOR = vec4(0.0);
	} else {
		// Dry sand up near the beach line → wetter, darker sand lower down.
		float wet = clamp((uv.y - beach) / 0.45, 0.0, 1.0);
		vec3 c = mix(far_color.rgb, near_color.rgb, wet);

		// Grain.
		float grain = vnoise2(uv * vec2(220.0, 130.0) + sd);
		c *= 1.0 + (grain - 0.5) * grain_amount * 2.0;

		float a = smoothstep(beach - 0.004, beach + 0.004, uv.y);
		COLOR = vec4(c, a);
	}
}
