shader_type canvas_item;

// Weather System 2D — simple falling-rain overlay (line SDFs), driven by `amount`.
// Meant for a full-screen ColorRect on a CanvasLayer above the scene.

uniform float amount : hint_range(0.0, 1.0) = 0.5;
uniform float speed = 1.0;
uniform float slant = -0.05;
uniform vec4 rain_color : source_color = vec4(0.80, 0.85, 0.95, 0.5);

float hash(float x) { return fract(sin(x * 18.34) * 51.78); }
float hash2(float x) { return fract(sin(x * 25.42) * 21.24); }

float line_sdf(vec2 p, vec2 s) {
	vec2 d = abs(p) - s;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

void fragment() {
	int count = int(amount * 300.0);
	vec2 uv = UV;
	uv.x += uv.y * slant;
	float o = 0.0;
	vec2 s = vec2(0.0009, 0.03);
	float t = TIME * speed + 500.0;
	for (int i = 1; i <= 300; i++) {
		if (i > count) { break; }
		float h1 = hash(float(i));
		float h2 = hash2(float(i));
		float px = h1 * 1.2;
		float py = max(h2 * 60.0, px * 60.0);
		vec2 pos = vec2(px, -mod(-py * t * 0.1, -1.0));
		float d = line_sdf(uv - pos, s);
		o += clamp(-d / 0.0015, 0.0, 1.0);
	}
	COLOR = vec4(rain_color.rgb, rain_color.a * clamp(o, 0.0, 1.0));
}
