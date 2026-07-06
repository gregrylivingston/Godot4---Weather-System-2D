shader_type canvas_item;

// Weather System 2D — bird wing-flap. Each bird sprite gets its own material with a random
// `phase` and `flap_speed`, so the flock beats out of sync. Travel across the sky is handled
// by PropScatter2D._process (this shader only flaps the wings by squashing the texture
// vertically toward the body per column).

uniform float phase = 0.0;
uniform float flap_speed = 8.0;
uniform float flap_depth = 0.55;

void fragment() {
	float flap = sin(TIME * flap_speed + phase);
	float wing = abs(UV.x - 0.5) * 2.0; // 0 at body, 1 at wingtips
	vec2 uv = UV;
	uv.y = (uv.y - 0.4) / (1.0 + flap * wing * flap_depth) + 0.4;
	COLOR = texture(TEXTURE, uv) * COLOR;
}
