shader_type canvas_item;

// Weather System 2D — WaterBody2D surface shader.
// Drive it with the WaterBody2D node (addons/weather2d/nodes/water_body_2d.gd).
//
// Modes (see the WaterBody2D.Mode enum):
//   0 STILL        — pond/lake below `level`; gentle ripples + screen reflections.
//   1 RIVER        — the whole rect is water, streaming along `flow_direction`.
//   2 OCEAN_BEACH  — an animated waterline laps up a beach with a foam band.
//
// UV convention: (0,0) top-left … (1,1) bottom-right. Water fills BELOW `level`
// (i.e. where UV.y >= level) for STILL and OCEAN_BEACH.

uniform int mode : hint_range(0, 2) = 0;

// --- palette ---
uniform vec4 deep_color : source_color = vec4(0.09, 0.22, 0.42, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.20, 0.45, 0.62, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float water_opacity : hint_range(0.0, 1.0) = 0.85;

// --- surface / waves ---
uniform float wave_scale = 6.0;
uniform float wave_speed : hint_range(0.0, 1.0) = 0.15;
uniform float wave_distortion : hint_range(0.0, 1.0) = 0.15;
// Rolling sum-of-sines that undulates the waterline (and, for OCEAN_BEACH, the shore edge).
// Keep `wave_height` / `wave_frequency` equal on the sand ground shader to align the coast.
uniform float wave_height : hint_range(0.0, 0.2) = 0.02;
uniform float wave_frequency = 8.0;

// --- waterline (STILL & OCEAN_BEACH) ---
uniform float level : hint_range(0.0, 1.0) = 0.5;

// --- river flow ---
uniform vec2 flow_direction = vec2(1.0, 0.0);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.25;

// --- foam ---
uniform float foam_amount : hint_range(0.0, 1.0) = 0.5;
uniform float foam_width : hint_range(0.0, 0.5) = 0.06;

// --- ocean-beach run-up ---
uniform float swell_height : hint_range(0.0, 0.3) = 0.05;
uniform float swell_speed : hint_range(0.0, 3.0) = 0.5;

// --- reflections ---
uniform bool reflection_enabled = true;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec2 reflection_offset = vec2(0.0, 0.0);

// --- terrain hookup (Phase 2, optional) ---
// A mask where the red channel > 0.5 marks land; lets water align with real terrain.
uniform bool use_terrain_mask = false;
uniform sampler2D terrain_mask : hint_default_black, filter_linear;

// Provided by the node (a seamless NoiseTexture2D).
uniform sampler2D noise_tex : repeat_enable, filter_linear;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear, repeat_disable;

// Two offset noise samples — cheap, tile-hiding pseudo-fbm in 0..1 space.
float noise_fbm(vec2 p) {
	float a = texture(noise_tex, p).r;
	float b = texture(noise_tex, p * 2.03 + vec2(7.1, 3.7)).r;
	return mix(a, b, 0.5);
}

// Sum-of-sines surface displacement in UV, animated by `t`. Returns roughly -1..1.
// Shared analytic form with terrain_ground.gdshader so water and sand share one coastline.
float surface_wave(float x, float t) {
	float w = sin(x * wave_frequency + t * 1.3);
	w += 0.5 * sin(x * wave_frequency * 2.17 - t * 1.9);
	w += 0.25 * sin(x * wave_frequency * 0.53 + t * 0.7);
	return w / 1.75;
}

void fragment() {
	vec2 uv = UV;

	// Guarded flow direction (avoid NaN from a zero vector).
	vec2 fdir = length(flow_direction) > 0.0001 ? normalize(flow_direction) : vec2(1.0, 0.0);
	vec2 flow = fdir * flow_speed * TIME;

	// Surface noise → waves + refraction offset.
	vec2 nuv = uv * wave_scale;
	float n1 = noise_fbm(nuv + flow + vec2(TIME * wave_speed, 0.0));
	float n2 = noise_fbm(nuv * 1.7 - flow * 0.6 + vec2(0.0, TIME * wave_speed * 0.8));
	float surface = (n1 + n2) * 0.5;
	float distort = (surface - 0.5) * wave_distortion;

	// Rolling sine waves along the surface.
	float wt = TIME * wave_speed * 6.0;
	float wave = surface_wave(uv.x, wt) * wave_height;

	// Waterline: sine waves undulate it; ocean-beach adds a slow run-up swell on top.
	float waterline = level - wave;
	if (mode == 2) {
		float swell = 0.5 + 0.5 * sin(TIME * swell_speed + surface * 3.0);
		waterline -= swell_height * swell;
	}

	// Is this fragment water? And how far is it from the shoreline (0..~0.5).
	bool is_water;
	float shore_dist;
	if (mode == 1) {
		is_water = true;
		shore_dist = 0.5; // river surface treated as mid-depth everywhere
	} else {
		is_water = uv.y >= waterline;
		shore_dist = uv.y - waterline;
	}

	// Optional terrain mask carves out land.
	if (use_terrain_mask) {
		float land = texture(terrain_mask, uv).r;
		if (land > 0.5) {
			is_water = false;
		}
		shore_dist = min(shore_dist, abs(land - 0.5));
	}

	if (!is_water) {
		COLOR = vec4(0.0);
	} else {
		// Deep water far from shore, lighter shallows near it.
		float depth_t = clamp(shore_dist / 0.5, 0.0, 1.0);
		vec3 col = mix(shallow_color.rgb, deep_color.rgb, depth_t);

		// Subtle wave highlight from the noise surface.
		col += (surface - 0.5) * 0.10;

		// Rolling sine ripples: crests catch a little light.
		if (mode == 1) {
			// River: ripples travel with the flow (vary along y, drift with x).
			float ripple = surface_wave(uv.y * 2.0, wt + uv.x * 6.28);
			col += ripple * wave_height * 2.0;
		} else {
			// Still / ocean: crest highlight near the waterline.
			col += max(wave, 0.0) * 1.5;
		}

		// Screen-space reflection (skip for river, which sits behind scenery).
		if (reflection_enabled && mode != 1) {
			vec2 ruv = vec2(
				SCREEN_UV.x + distort + reflection_offset.x,
				1.0 - SCREEN_UV.y - (waterline - 0.5) * 2.0 + reflection_offset.y
			);
			vec3 refl = texture(SCREEN_TEXTURE, clamp(ruv, vec2(0.0), vec2(1.0))).rgb;
			col = mix(col, refl, reflection_strength);
		}

		// Foam.
		float foam;
		if (mode == 1) {
			// River: broken foam streaks carried along the flow.
			float streak = noise_fbm(uv * wave_scale * 3.0 + flow * 2.0);
			foam = smoothstep(1.0 - foam_amount * 0.5, 1.0, streak) * 0.6;
		} else {
			// Still / ocean: a broken band hugging the waterline.
			float band = 1.0 - smoothstep(0.0, foam_width, shore_dist);
			float fn = noise_fbm(uv * wave_scale * 2.0 + flow + vec2(TIME * wave_speed * 1.5, 0.0));
			foam = smoothstep(0.45, 0.9, band * (0.55 + 0.9 * fn));
		}

		col = mix(col, foam_color.rgb, clamp(foam * foam_amount + foam * 0.2, 0.0, 1.0));
		COLOR = vec4(col, water_opacity);
	}
}
