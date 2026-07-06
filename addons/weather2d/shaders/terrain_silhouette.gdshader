shader_type canvas_item;

// Weather System 2D — distant terrain silhouette (hills / mountains / treeline).
// Driven by TerrainBand2D from a TerrainLayer. Self-contained; a given `seed` regenerates
// identically. Aims for a soft, painterly look: domain-warped organic ridges, an
// atmospheric top-to-bottom gradient, and gentle tonal mottling instead of hard banding.
//
// UV convention: (0,0) top-left … (1,1) bottom-right. Terrain fills BELOW a ridge line;
// above it is transparent so farther bands show through.

uniform vec4 near_color : source_color = vec4(0.34, 0.50, 0.36, 1.0);
uniform vec4 far_color : source_color = vec4(0.62, 0.70, 0.78, 1.0);
uniform float height : hint_range(0.0, 1.0) = 0.4;    // silhouette height (fraction of band)
uniform float roughness : hint_range(0.0, 1.0) = 0.5; // 0 rolling … 1 jagged
uniform float seed = 0.0;

// Smooth (quintic) 2D value noise + fBm — organic, no blocky cells.
float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // smootherstep
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x),
			   mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; i++) {
		s += a * vnoise(p);
		p = p * 2.0 + 1.7;
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 uv = UV;
	// Bound the seed: large values fed into hashes lose precision and flatten the noise.
	float sd = mod(seed, 997.0);

	// Domain-warped ridge line for organic, non-repetitive peaks.
	float freq = 2.0 + roughness * 8.0;
	float warp = fbm(vec2(uv.x * freq * 0.5, sd));
	float ridge = fbm(vec2(uv.x * freq + warp * 1.5, sd * 1.3));

	float base_top = 1.0 - height;
	float top = base_top - (ridge - 0.5) * height * (0.5 + roughness);

	// Atmospheric gradient by ABSOLUTE height (uniform across x -> no vertical "curtains").
	float g = clamp(uv.y, 0.0, 1.0);
	vec3 c = mix(far_color.rgb, near_color.rgb, g);

	// Soft painterly tonal variation.
	float mott = fbm(uv * vec2(3.0, 4.0) + sd * 2.0);
	c += (mott - 0.5) * 0.05;

	// Soft, wide anti-aliased ridge edge.
	float a = smoothstep(top - 0.012, top + 0.012, uv.y);
	COLOR = vec4(c, a);
}
