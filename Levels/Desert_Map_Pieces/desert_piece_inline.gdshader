shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0, 10) = 1.0;
uniform int pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool inside = false;
uniform bool add_margins = true; // only useful when inside is false

void vertex() {
	if (add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * width;
	}
}

// See if a pixel
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	// Double for loop to look at all the nearby pixels.
	for (float i = -ceil(width); i <= ceil(width); i++) {
		float x = abs(i) > width ? width * sign(i) : i;
		float offset;
		
		if (pattern == 0) {
			offset = width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = width;
		}
		
		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			// Coordinates of the current neighbor.
			vec2 xy = uv + texture_pixel_size * vec2(x, y);
			
			// One of two conditions is true, then that == inside
			// In the case of inline shader, one of those needs to be true for it to be inlined.
			// First condition: The neighbor is not out of bounds.
			// Second condition: OR The pixel of the texture at the neighbor location is transparent.
			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
				if (texture(texture, xy).rgb != COLOR.rgb) {
					return true;
				}
			}
		}
	}
	
	return false;
}

void fragment() {
	vec2 uv = UV;
	
	if (add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
		
		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
		
		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			// Margin color that activates if "inside" is false
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv);
			//COLOR = vec4(1.0, 0.0, 0.0, 1.0);
		}
	} else {
		COLOR = texture(TEXTURE, uv);
	}
	
	TEXTURE
	
	// The pixel has to be visible in order to inline it.
	if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		COLOR.rgb = inside ? mix(COLOR.rgb, color.rgb, color.a) : color.rgb;
		COLOR.a += (1.0 - COLOR.a) * color.a;
	}
}