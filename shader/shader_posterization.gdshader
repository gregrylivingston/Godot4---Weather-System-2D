shader_type canvas_item;

// adapted from https://godotshaders.com/shader/4-level-posterization-fragment/

render_mode unshaded; // Credit: LiathTheCrow for original shader code

uniform vec4 level1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 level2 : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 level3 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 level4 : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float threshold1 	: hint_range(0.0,1.0) = .4;
uniform float threshold2 	: hint_range(0.0,1.0) = .52;
uniform float threshold3	: hint_range(0.0,1.0) = .8;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV).rgba;
	float rgb_avg = (COLOR.r + COLOR.g + COLOR.b)/3.0;
	if(rgb_avg < threshold1){
		COLOR = level1.rgba;
	}else if(rgb_avg < threshold2){
		COLOR = level2.rgba;
	}else if(rgb_avg < threshold3){
		COLOR = level3.rgba;
	}else{
		COLOR = level4.rgba;
	}
}