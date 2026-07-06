shader_type canvas_item;

// Weather System 2D — flying birds. Drifts and bobs the whole sprite (vertex) and flaps the
// wings by squashing the texture vertically toward the body per column (fragment). Phase is
// derived from world X so a flock flaps out of sync. Assign via PropScatter2D animation = FLY.

uniform float flap_speed = 7.0;
uniform float flap_depth = 0.5;
uniform float drift_speed = 0.35;
uniform float drift_amount = 26.0;
uniform float bob_amount = 7.0;

varying float v_phase;

void vertex() {
	v_phase = MODEL_MATRIX[3].x * 0.02;
	VERTEX.x += sin(TIME * drift_speed + v_phase) * drift_amount;
	VERTEX.y += sin(TIME * drift_speed * 0.7 + v_phase * 1.3) * bob_amount;
}

void fragment() {
	float flap = sin(TIME * flap_speed + v_phase);
	float wing = abs(UV.x - 0.5) * 2.0; // 0 at body, 1 at wingtips
	vec2 uv = UV;
	uv.y = (uv.y - 0.35) / (1.0 + flap * wing * flap_depth) + 0.35;
	COLOR = texture(TEXTURE, uv) * COLOR;
}
