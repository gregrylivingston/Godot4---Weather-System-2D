shader_type canvas_item;

// Donut Mask
uniform vec2 DonutMaskCenter = vec2(0.5);
uniform float DonutMaskSize = 0.5;
uniform float DonutMaskThickness = 0.15;

// Outline
uniform float OutlineWidth : hint_range(0.0, 64) = 3.0;
uniform float OutlinePixelSize : hint_range(0.01, 10.0) = 1;

// Rainbow
uniform bool UseRainbowColorOutline = true;
uniform float RainbowColorLightOffset : hint_range(0.0, 1.0) = 0.5;   // this offsets all color channels; if set to 0 only red green and blue colors will be shown.
uniform float RainbowColorSinFrequency : hint_range(0.1, 2.0) = 0.1;  // frequency of the rainbow

// Noise
uniform bool OutlineUseNoise = false;
uniform float NoiseBlockSize = 5.0;
uniform float NoiseMaxLineWidth = 10.0;
uniform float NoiseMinLineWidth = 5.0;
uniform float NoiseFreq = 1.0;

uniform vec4 BackgroundColor : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap ;

// Noise Constants
const int ANGLE_RESOLUTION = 16;
const int GRADIENT_RESOLUTION = 8;

// Mmmm donuts
float createDonutMask(
	vec2 inputTexturePixelSize,
	vec2 inputUV) {
	float ratio = inputTexturePixelSize.x / inputTexturePixelSize.y;
	vec2 scaledUV = (inputUV - vec2(DonutMaskCenter.x, 0.0)) / vec2(ratio, 1.0) + vec2(DonutMaskCenter.x, 0.0);
	return (1.0 - smoothstep(DonutMaskSize - 0.2, DonutMaskSize, length(scaledUV - DonutMaskCenter))) *
		smoothstep(DonutMaskSize - DonutMaskThickness - 0.1,
		DonutMaskSize - DonutMaskThickness, length(scaledUV - DonutMaskCenter)
	);
}

vec4 createRainbowColor(float t) {
	return vec4(RainbowColorLightOffset + sin(2.0*3.14*RainbowColorSinFrequency*t),
							   RainbowColorLightOffset + sin(2.0*3.14*RainbowColorSinFrequency*t + radians(120.0)),
							   RainbowColorLightOffset + sin(2.0*3.14*RainbowColorSinFrequency*t + radians(240.0)),
							   1.0);
}

vec4 handleInline(vec4 finalPixelColor, vec4 outlineColor, vec4 originalPixelColor) {
	// Handle inline
    if (finalPixelColor.r < BackgroundColor.r || finalPixelColor.g < BackgroundColor.g || finalPixelColor.b < BackgroundColor.b) {
        finalPixelColor.rgb = mix(outlineColor.rgb, finalPixelColor.rgb, 1.0 - tanh(3.0*originalPixelColor.b));
    }

	return finalPixelColor;
}

float hash(vec2 p, float s) {
	return fract(35.1 * sin(dot(vec3(112.3, 459.2, 753.2), vec3(p, s))));
}

float noise(vec2 p, float s) {
	vec2 d = vec2(0, 1);
	vec2 b = floor(p);
	vec2 f = fract(p);
	return mix(
		mix(hash(b + d.xx, s), hash(b + d.yx, s), f.x),
		mix(hash(b + d.xy, s), hash(b + d.yy, s), f.x), f.y);
}

float getLineWidth(vec2 p, float s) {
	p /= NoiseBlockSize;
	float w = 0.0;
	float intensity = 1.0;
	for (int i = 0; i < 3; i++) {
		w = mix(w, noise(p, s), intensity);
		p /= 2.0;
		intensity /= 2.0;
	}

	return mix(NoiseMaxLineWidth, NoiseMinLineWidth, w);
}

bool pixelInRange(sampler2D text, vec2 uv, vec2 dist) {
	float alpha = 0.0;
	for (int i = 0; i < ANGLE_RESOLUTION; i++) {
		float angle = 2.0 * PI * float(i) / float(ANGLE_RESOLUTION);
		vec2 disp = dist * vec2(cos(angle), sin(angle));
		if (texture(text, uv + disp).b < 0.5) return true;
	}
	return false;
}

float getClosestDistance(sampler2D text, vec2 uv, vec2 maxDist) {
	if (!pixelInRange(text, uv, maxDist)) return -1.0;

	float hi = 1.0; float lo = 0.0;

	for (int i = 1; i <= GRADIENT_RESOLUTION; i++) {
		float curr = (hi + lo) / 2.0;
		if (pixelInRange(text, uv, curr * maxDist)) {
			hi = curr;
		}
		else {
			lo = curr;
		}
	}
	return hi;

}

vec4 handleNoise(
	vec4 finalPixelColor,
	float t,
	vec2 pixelSize,
	sampler2D inputTexture,
	vec2 inputUV,
	vec4 originalPixelColor) {

	float timeStep = floor(NoiseFreq * t);
	vec2 scaledDistance = pixelSize * getLineWidth(inputUV / pixelSize, timeStep);
	float weight = getClosestDistance(inputTexture, inputUV, scaledDistance);

	if ( weight > 0.0) {
	    finalPixelColor.a = mix(0.0, finalPixelColor.a, tanh(5.0*weight));
	} else {
		finalPixelColor = originalPixelColor;
	}

	return finalPixelColor;
}

vec4 handleOutline(vec4 finalPixelColor,
					vec4 outlineColor,
					vec4 originalPixelColor,
					sampler2D inputTexture,
					vec2 inputUV) {
	if (finalPixelColor.r > 0.05 || finalPixelColor.g > 0.05 || finalPixelColor.b > 0.05) {
		vec2 unit = (OutlinePixelSize ) / vec2(textureSize(inputTexture, 0));

        finalPixelColor.rgb = mix(outlineColor.rgb, finalPixelColor.rgb, 1.0 - tanh(3.0*originalPixelColor.b));
		finalPixelColor.a = 0.0;

        for (float x = -ceil(OutlineWidth); x <= ceil(OutlineWidth); x++) {
            for (float y = -ceil(OutlineWidth); y <= ceil(OutlineWidth); y++) {
				vec4 current_texture = texture(inputTexture, inputUV + vec2(x*unit.x, y*unit.y));
                if (current_texture.r > 0.5 || current_texture.g > 0.5 || current_texture.b > 0.5 || (x==0.0 && y==0.0)) {
                    continue;
                }
                finalPixelColor.a += outlineColor.a / (pow(x,2)+pow(y,2)) * (1.0-pow(2.0, -OutlineWidth));
				if (finalPixelColor.a > 1.0) {
					finalPixelColor.a = 1.0;
				}
            }
        }
    }

	return finalPixelColor;
}

void fragment() {
	float mask = createDonutMask(
		TEXTURE_PIXEL_SIZE,
		UV);

	vec4 outlineColor = vec4(1.0, 0.0, 0.0, 1.0);
	if (UseRainbowColorOutline){
		outlineColor = createRainbowColor(TIME);
	}

	vec4 finalPixelColor = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 originalPixelColor = finalPixelColor;

	finalPixelColor = handleInline(finalPixelColor, outlineColor, originalPixelColor);
	finalPixelColor = handleOutline(finalPixelColor,
		outlineColor,
		originalPixelColor,
		SCREEN_TEXTURE,
		SCREEN_UV);

	finalPixelColor.a = finalPixelColor.a * mask;

	if (OutlineUseNoise) {
		finalPixelColor = handleNoise(
			finalPixelColor,
			TIME,
			SCREEN_PIXEL_SIZE,
			SCREEN_TEXTURE,
			SCREEN_UV,
			originalPixelColor);
	}

	COLOR = finalPixelColor;
}