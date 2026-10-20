shader_type canvas_item;

uniform float line_count = 540.0;
uniform float line_strength : hint_range(0.0, 1.0) = 0.25;
uniform float roll_speed = 0.08;
uniform float roll_width : hint_range(0.01, 0.5) = 0.15;
uniform float roll_strength : hint_range(0.0, 1.0) = 0.08;
uniform vec3 tint : source_color = vec3(0.3, 1.0, 0.7);

void fragment() {
	//static scanlines
	float lines = 0.5 + 0.5 * sin(FRAGCOORD.y / 1.0);
	float line_alpha = lines * line_strength;
	
	// rolling bar: bright edge that fades out behind int
	float pos = fract(TIME * roll_speed);
	float dist = abs(fract(UV.y - pos + 0.5) - 0.5);
	float bar = 1.0 - smoothstep(0.0, roll_width, dist);
	
	COLOR = vec4(tint * bar, clamp(line_alpha + bar * roll_strength, 0.0, 1.0));
}
