shader_type canvas_item;

// Used to get the color of each screen pixel.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	// Called for every pixel the material is visible on.
	
	// Get each pixel on the screen corresponding to the pixel occupied by this part of the ColorRect.
	vec4 color = textureLod(screen_texture, SCREEN_UV, 0.0);
	
	// CIE 1931 grayscale equation to account for luminance.
	float gray = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722;
	
	// COLOR is the output of this function. Modifying it changes the output pixel color.
	COLOR = vec4(gray, gray, gray, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
