shader_type canvas_item;

// Weather System 2D — painterly full-screen post-process.
// Drop a PainterlyLayer over the scene. Reads the rendered frame and applies a gentle
// soft-focus blur, a hint of warmth, a faint paper grain, and a soft vignette so the whole
// image reads more like a soft painting than flat shapes.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

uniform float softness : hint_range(0.0, 3.0) = 1.0;   // blur radius in pixels
uniform float blur_mix : hint_range(0.0, 1.0) = 0.55;  // how much soft-focus to blend in
uniform float grain : hint_range(0.0, 0.15) = 0.035;
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
uniform float warmth : hint_range(-0.08, 0.08) = 0.015;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * softness;
	vec2 uv = SCREEN_UV;

	// 3x3 weighted (approx Gaussian) blur.
	vec3 blur = texture(screen_tex, uv).rgb * 0.25;
	blur += texture(screen_tex, uv + vec2(px.x, 0.0)).rgb * 0.125;
	blur += texture(screen_tex, uv - vec2(px.x, 0.0)).rgb * 0.125;
	blur += texture(screen_tex, uv + vec2(0.0, px.y)).rgb * 0.125;
	blur += texture(screen_tex, uv - vec2(0.0, px.y)).rgb * 0.125;
	blur += texture(screen_tex, uv + px).rgb * 0.0625;
	blur += texture(screen_tex, uv - px).rgb * 0.0625;
	blur += texture(screen_tex, uv + vec2(px.x, -px.y)).rgb * 0.0625;
	blur += texture(screen_tex, uv + vec2(-px.x, px.y)).rgb * 0.0625;

	vec3 sharp = texture(screen_tex, uv).rgb;
	vec3 col = mix(sharp, blur, blur_mix);

	// Gentle warmth (lift reds, drop blues a touch).
	col.r += warmth;
	col.b -= warmth * 0.5;

	// Faint paper grain.
	float g = hash(FRAGCOORD.xy * 0.5);
	col += (g - 0.5) * grain;

	// Soft vignette.
	vec2 d = uv - 0.5;
	col *= 1.0 - dot(d, d) * vignette * 2.0;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
