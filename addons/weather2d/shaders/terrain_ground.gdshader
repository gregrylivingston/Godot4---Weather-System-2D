shader_type canvas_item;

// Weather System 2D — sandy ground / beach for a WaterBody2D to wash over.
// Driven by TerrainBand2D (GROUND role) from a TerrainLayer. Soft, painterly sand: smooth
// multi-octave grain + large tonal patches rather than hard speckle.
//
// Composition: place this BEHIND a WaterBody2D (OCEAN_BEACH). The sand fills below a gently
// wavy beach line; the water layer animating its waterline on top alternately covers and
// exposes the sand — that overlap is the "ocean washing into the sand".
//
// Keep `coast_level` near the water's `level`, and `wave_height` / `wave_frequency` equal to
// the water's, so the two coastlines share a shape.

uniform vec4 near_color : source_color = vec4(0.66, 0.58, 0.42, 1.0); // wet / lower sand
uniform vec4 far_color : source_color = vec4(0.86, 0.78, 0.60, 1.0);  // dry / upper sand
uniform float coast_level : hint_range(0.0, 1.0) = 0.4;
uniform float wave_height : hint_range(0.0, 0.2) = 0.03;
uniform float wave_frequency = 8.0;
uniform float grain_amount : hint_range(0.0, 0.4) = 0.12;
uniform float seed = 0.0;

float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Smooth (quintic) 2D value noise + fBm.
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x),
			   mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		s += a * vnoise(p);
		p = p * 2.0 + 1.7;
		a *= 0.5;
	}
	return s;
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
	float sd = mod(seed, 997.0);

	// Organic beach line: shared coastline sine + a soft low-frequency wobble.
	float wob = (fbm(vec2(uv.x * 3.0, sd)) - 0.5) * 0.02;
	float beach = coast_level - surface_wave(uv.x) * wave_height * 0.5 + wob;

	if (uv.y < beach) {
		COLOR = vec4(0.0);
	} else {
		// Dry sand near the beach line → wetter, darker sand lower down.
		float wet = clamp((uv.y - beach) / 0.5, 0.0, 1.0);
		vec3 c = mix(far_color.rgb, near_color.rgb, wet);

		// Large soft tonal patches for a painterly feel.
		float patch = fbm(uv * vec2(3.5, 2.5) + sd * 3.0);
		c = mix(c, c * 0.93, patch * 0.5);

		// Fine but smooth grain (fBm, not hard speckle).
		float gr = fbm(uv * vec2(90.0, 60.0) + sd * 5.0);
		c *= 1.0 + (gr - 0.5) * grain_amount;

		float a = smoothstep(beach - 0.01, beach + 0.01, uv.y);
		COLOR = vec4(c, a);
	}
}
