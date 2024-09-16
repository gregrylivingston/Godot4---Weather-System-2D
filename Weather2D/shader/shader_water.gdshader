shader_type canvas_item;

//og water shader from https://godotshaders.com/shader/2d-water-with-reflections/

//possibly to modify w/ one of the following....
//https://godotshaders.com/shader/water-with-primitive-caustics/
//https://godotshaders.com/shader/simple-2d-water/


uniform float level : hint_range(0.0, 1.0) = 0.5; 
uniform vec4 water_albedo : source_color = vec4(0.26, 0.23, 0.73, 1.0);
uniform float water_opacity : hint_range(0.0, 1.0) = 0.35;
uniform float water_speed = 0.05;
uniform float wave_distortion = 0.2;
uniform int wave_multiplyer = 7;
uniform bool water_texture_on = true;
uniform int water_texture_type:hint_range(0, 2, 1);

uniform float reflection_X_offset = 0.0;
uniform float reflection_Y_offset = 0.0;
uniform sampler2D noise_texture: repeat_enable;
uniform sampler2D noise_texture2: repeat_enable;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest, repeat_disable;
uniform vec2 param1 = vec2(0.3, 0.2);
uniform vec2 param2 = vec2(0.4, 0.7);
uniform vec2 param3 = vec2(0.3, 0.1);

void fragment() {
	vec2 uv = UV;
	COLOR = vec4(0.0);
	
	if (uv.y >= level) {
		COLOR.a = 1.0;
		
		// distorted reflections
		vec2 water_uv = vec2(uv.x, uv.y * float(wave_multiplyer));
		float noise = texture(noise_texture, vec2(water_uv.x + TIME * water_speed, water_uv.y)).x * wave_distortion;
		noise -= (0.5 * wave_distortion);
		
		// water texture
		switch(water_texture_type){
			case 1:
				float water_texture_limit = 0.35;
				vec4 water_texture = texture(noise_texture2, uv * vec2(0.5, 4.0) + vec2(noise, 0.0));
				float water_texture_value = (water_texture.x < water_texture_limit) ? 1.0 : 0.0;	
				COLOR.xyz = vec3(water_texture_value);
				break;
			case 2:

			default:
				

		};

	
		// putting everything toghether 
		vec4 current_texture = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + noise + reflection_X_offset, 1.0 - SCREEN_UV.y - (level - 0.5) * 2.0 + reflection_Y_offset));
		COLOR = mix(COLOR , current_texture * 2.0, 0.5);
		COLOR = mix(COLOR, water_albedo, water_opacity);
		//vec3 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
		//COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
		//COLOR = texture(SCREEN_TEXTURE, UV);
	}
}