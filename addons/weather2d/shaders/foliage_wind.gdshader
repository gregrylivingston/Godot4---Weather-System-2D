shader_type canvas_item;

// Weather System 2D — gentle foliage sway for scattered props (trees, palms, bushes).
// Anchors the base and bends the crown with a wind sine. Each sprite gets a different phase
// from its world X, so a stand of trees sways naturally out of sync. Assign as the material
// on prop sprites (PropScatter2D does this when animation = SWAY).

uniform float wind_strength = 4.0; // horizontal bend at the crown, in local pixels
uniform float wind_speed = 1.1;

void vertex() {
	float crown = 1.0 - UV.y;                 // 0 at the base, 1 at the top
	float phase = MODEL_MATRIX[3].x * 0.012;  // per-sprite offset from world position
	float wind = sin(TIME * wind_speed + phase)
		+ 0.35 * sin(TIME * wind_speed * 2.3 + phase * 1.7);
	VERTEX.x += wind * wind_strength * crown * crown;
}
