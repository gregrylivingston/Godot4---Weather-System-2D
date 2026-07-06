shader_type canvas_item;

// Weather System 2D — sky shader (replaces the flat 2-stop gradient).
// Renders a vertical gradient with a soft horizon lift, a sun/moon disc + glow positioned
// from `sun_uv`, and a field of twinkling stars that fades in with `star_intensity`.
//
// Drive it from a full-rect ColorRect. WeatherScene assigns the palette + sun from the
// active TimeOfDay; SkyController re-pushes them each frame for a day-night cycle.

uniform vec4 sky_top : source_color = vec4(0.38, 0.62, 0.88, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.74, 0.87, 0.95, 1.0);

// Sun / moon — position in UV, light color, apparent size and glow radius.
uniform vec2 sun_uv = vec2(0.5, 0.18);
uniform vec4 sun_color : source_color = vec4(1.0, 0.98, 0.92, 1.0);
uniform float sun_size : hint_range(0.0, 0.2) = 0.045;
uniform float sun_glow : hint_range(0.0, 1.0) = 0.5;

// Stars fade in at night; concentrated above the horizon, twinkling over time.
uniform float star_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float horizon : hint_range(0.0, 1.0) = 0.62;

// Width / height of the rect, so the sun disc and glow stay round.
uniform float aspect = 1.777;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	// Base vertical gradient with a gentle horizon lift toward the sky-bottom color.
	float g = smoothstep(0.0, 1.0, UV.y);
	vec3 col = mix(sky_top.rgb, sky_bottom.rgb, g);

	// Aspect-corrected distance to the sun so glow/disc are circular, not stretched.
	vec2 d = (UV - sun_uv) * vec2(aspect, 1.0);
	float dist = length(d);

	// Broad glow around the sun, tinted by its color.
	float glow = exp(-dist * dist / (sun_glow * 0.05 + 0.002));
	col += sun_color.rgb * glow * (0.35 + sun_glow * 0.4);

	// The disc itself (a soft-edged circle).
	float disc = 1.0 - smoothstep(sun_size * 0.7, sun_size, dist);
	col = mix(col, sun_color.rgb, clamp(disc, 0.0, 1.0));

	// Stars — a sparse cell hash, only above the horizon, twinkling over time.
	if (star_intensity > 0.001) {
		vec2 grid = UV * vec2(260.0, 150.0);
		vec2 cell = floor(grid);
		vec2 f = fract(grid) - 0.5;
		float h = hash(cell);
		float is_star = step(0.985, h);                    // ~1.5% of cells
		float twinkle = 0.55 + 0.45 * sin(TIME * 2.5 + h * 100.0);
		float point = smoothstep(0.16, 0.0, length(f));
		float sky_fade = smoothstep(horizon, horizon - 0.35, UV.y); // brightest up high
		col += vec3(0.9, 0.95, 1.0) * is_star * point * twinkle * star_intensity * sky_fade;
	}

	COLOR = vec4(col, 1.0);
}
