shader_type canvas_item;

// Weather System 2D — distant terrain silhouette (hills / mountains / treeline).
// Driven by TerrainBand2D from a TerrainLayer. Self-contained analytic noise, so no
// noise texture is required and a given `seed` regenerates identically.
//
// UV convention: (0,0) top-left … (1,1) bottom-right. Terrain fills BELOW a jagged
// top edge; above it is transparent so farther bands show through.

uniform vec4 near_color : source_color = vec4(0.34, 0.50, 0.36, 1.0);
uniform vec4 far_color : source_color = vec4(0.62, 0.70, 0.78, 1.0);
uniform float height : hint_range(0.0, 1.0) = 0.4;    // silhouette height (fraction of band)
uniform float roughness : hint_range(0.0, 1.0) = 0.5; // 0 rolling … 1 jagged
uniform float seed = 0.0;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

// 1D value noise.
float vnoise(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash1(i), hash1(i + 1.0), f);
}

// 1D fBm for the ridge line.
float fbm1(float x) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		s += a * vnoise(x);
		x *= 2.0;
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 uv = UV;

	// Frequency and jaggedness scale with roughness.
	float freq = 2.0 + roughness * 10.0;
	// Bound the seed: large values fed into sin() lose float precision and flatten the noise.
	float sd = mod(seed, 997.0);
	float ridge = fbm1(uv.x * freq + sd * 13.7);

	// Baseline top edge, pushed up/down by the ridge noise.
	float base_top = 1.0 - height;
	float top = base_top - (ridge - 0.5) * height * (0.4 + roughness);

	// Vertical gradient: hazy far_color at the ridge → near_color at the base.
	float g = clamp((uv.y - top) / max(height, 0.001), 0.0, 1.0);
	vec3 c = mix(far_color.rgb, near_color.rgb, g);

	// Soft (anti-aliased) silhouette edge.
	float a = smoothstep(top - 0.004, top + 0.004, uv.y);
	COLOR = vec4(c, a);
}
