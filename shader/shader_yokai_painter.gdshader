shader_type canvas_item;

uniform sampler2D colorgradient;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if ( COLOR.a > 0.1){
		if ( COLOR.r > 0.3 ){
		COLOR = texture(colorgradient,UV);
	}
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
