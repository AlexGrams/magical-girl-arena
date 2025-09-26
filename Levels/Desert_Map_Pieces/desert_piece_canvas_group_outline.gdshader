shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 line_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float line_thickness : hint_range(0, 1000) = 1.0;

const vec2 OFFSETS[8] = {
	vec2(-1, 0),vec2(0, -1),vec2(0, 1),vec2(1, 0),
	vec2(-1, -1),vec2(1, 1),vec2(1, -1),vec2(-1, 1)
};

void fragment() {
	vec2 size = SCREEN_PIXEL_SIZE * line_thickness;
	float outline = 0.0;
	
	for (int i = 0; i < OFFSETS.length(); i++) {
		outline += texture(screen_texture, SCREEN_UV + size * OFFSETS[i]).a;
	}
	outline = min(outline, 1.0);
	
	vec4 c = textureLod(screen_texture,  SCREEN_UV, 0.0);
	
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	
	COLOR = mix(c, line_color, outline - c.a);
}
