// cloudy skies shader
// inspired from shadertoy shader made by Drift (https://www.shadertoy.com/view/4tdSWr) 
// adapted from https://godotshaders.com/shader/cloudy-skies/


shader_type canvas_item;

uniform float cloudscale = 1.1;
uniform float speed = 0.01;
uniform float clouddark = 0.5;
uniform float cloudlight = 0.3;
uniform float cloudcover = 0.2; // no clouds is -20 fully cloudy is 5
uniform float cloudalpha = 8.0;
uniform float skytint = 0.5;

uniform mat2 m = mat2(vec2(1.6,1.2),vec2(-1.2,1.6)); // changement
uniform sampler2D skycolor;


//inserted perspective skew
uniform vec2 up_left = vec2(0.0);
uniform vec2 up_right = vec2(1.0, 0.0);
uniform vec2 down_right = vec2(1.0, 1.0);
uniform vec2 down_left = vec2(0.0, 1.0);

uniform vec2 plane_size;

varying mat3 trans_inv;
varying vec2 trans_scale;
varying vec2 trans_offset;

mat3 perspective_transform(vec2[4] poly) { 
	float dx1 = poly[1].x - poly[2].x;
	float dx2 = poly[3].x - poly[2].x;
	float dx3 = poly[0].x - poly[1].x + poly[2].x - poly[3].x;
	float dy1 = poly[1].y - poly[2].y;
	float dy2 = poly[3].y - poly[2].y;
	float dy3 = poly[0].y - poly[1].y + poly[2].y - poly[3].y;
 
	float a13 = (dx3 * dy2 - dy3 * dx2) / (dx1 * dy2 - dy1 * dx2);
	float a23 = (dx1 * dy3 - dy1 * dx3) / (dx1 * dy2 - dy1 * dx2);
	float a11 = poly[1].x - poly[0].x + a13 * poly[1].x;
	float a21 = poly[3].x - poly[0].x + a23 * poly[3].x;
	float a31 = poly[0].x;
	float a12 = poly[1].y - poly[0].y + a13 * poly[1].y;
	float a22 = poly[3].y - poly[0].y + a23 * poly[3].y;
	float a32 = poly[0].y;
 
	mat3 transform_mat = mat3(
		vec3(a11, a12, a13),
		vec3(a21, a22, a23),
		vec3(a31, a32, 1)
	);
	
	return inverse(transform_mat);
}

vec2 mult_mat_inv_point(mat3 mat_inv, vec2 point) {
	vec3 result = mat_inv * vec3(point, 1.0);
	return vec2(result.x / result.z, result.y / result.z);
}

void vertex() {
	vec2[] poly = {up_left, up_right, down_right, down_left};
	//PRECALCULATING TRANSFORMATION MATRIX
	trans_inv = perspective_transform(poly);
	//SCALE AND OFFSET TO TRANSFORM VERTEX AND LATER UV TO SUPPORT OUT OF BOUNDING BOX TRANSFORMATION
	trans_scale = vec2(
		max(max(up_right.x, down_right.x) - min(up_left.x, down_left.x), 1.0),
		max(max(down_left.y, down_right.y) - min(up_left.y, up_right.y), 1.0)
	);
	trans_offset = vec2(
		min(min(up_left.x, down_left.x), 0.0),
		min(min(up_left.y, up_right.y), 0.0)
	);
	VERTEX = VERTEX * trans_scale + plane_size * trans_offset;
}



// functions ( normal sky shader continued)




vec2 hash( vec2 p ) {
                p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
                return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p ) {
    float K1 = 0.366025404; // (sqrt(3)-1)/2;
    float K2 = 0.211324865; // (3-sqrt(3))/6;
                vec2 i = floor(p + (p.x+p.y)*K1); 
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
                vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
                vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));       
}

float fbm(vec2 n) {
                float total = 0.0, amplitude = 0.1;
                for (int i = 0; i < 7; i++) {
                               total += noise(n) * amplitude;
                               n = m * n;
                               amplitude *= 0.4;
                }
                return total;
}

// fragment shader

void fragment() {
	

vec2 pUV = mult_mat_inv_point(trans_inv, UV * trans_scale + trans_offset);
	
vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
vec2 p = FRAGCOORD.xy  / res.xy; // changement


    vec2 uv = p * vec2(res.x/res.y,1.0) ;    // changement
    float time = TIME * speed ;
    float q = fbm(uv * cloudscale * 0.5 ) ;
    
    //ridged noise shape
    float r = 0.0;
    uv *= cloudscale  ;
    uv += q - time;
    float weight = 0.8 ;
    for (int i=0; i<8; i++){
                               r += abs(weight*noise( uv ));
        uv = m*uv  + time ;
                               weight *= 0.7;
    }
    
    //noise shape
                float f = 0.0;
    uv = p*vec2(res.x/res.y,1.0) ; // changement
                uv *= cloudscale  * pUV  ;
    uv += q - time;
    weight = 0.7;
    for (int i=0; i<8; i++){
                               f += weight*noise( uv )  ;
        uv = m*uv + time ;
                               weight *= 0.6  ;
    }
    
    f *= r + f;
    
    //noise colour
    float c = 0.0;
    time = TIME * speed * 2.0;
    uv = p*vec2(res.x/res.y,1.0) ; // changement
                uv *= cloudscale*2.0 ;
    uv += q - time;
    weight = 0.4;
    for (int i=0; i<7; i++){
                               c += weight*noise( uv );
        uv = m*uv + time;
                               weight *= 0.6 - UV.y ;
    }
    
    //noise ridge colour
    float c1 = 0.0;
    time = TIME * speed * 3.0;
    uv = p*vec2(res.x/res.y,1.0);
                uv *= cloudscale*3.0;
    uv += q - time;
    weight = 0.4;
    for (int i=0; i<7; i++){
                               c1 += abs(weight*noise( uv ));
        uv = m*uv + time;
                               weight *= 0.6;
    }
                
    c += c1;
    
    vec3 skycolour = texture(skycolor, UV).rgb;
    vec3 cloudcolour = vec3(1.1, 1.1, 0.9) * clamp((clouddark + cloudlight*c), 0.0, 1.0);
   
    f = cloudcover + cloudalpha*f*r;
    
    vec3 result = mix(skycolour, clamp(skytint * skycolour + cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0));
    
    COLOR.rgb = vec3(result); 
	
}