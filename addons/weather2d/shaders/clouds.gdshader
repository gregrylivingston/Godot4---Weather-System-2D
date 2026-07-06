shader_type canvas_item;

// Weather System 2D — soft drifting clouds for the upper sky. Put on a rect over the sky
// gradient (behind the terrain). fBm blobs scroll slowly; `amount` sets coverage.

uniform float amount : hint_range(0.0, 1.0) = 0.3;
uniform float speed = 0.006;
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
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

void fragment() {
	vec2 uv = UV * vec2(3.0, 1.6);
	uv.x += TIME * speed * 10.0;
	float n = fbm(uv);
	// Clouds live in the upper sky, fading out before the horizon.
	float sky = smoothstep(0.72, 0.15, UV.y);
	float cover = smoothstep(1.0 - amount * 0.9 - 0.05, 1.0, n);
	COLOR = vec4(cloud_color.rgb, cover * cloud_color.a * sky);
}
