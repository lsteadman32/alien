shader_type canvas_item;

void fragment () {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	
	float edge_fade = 1.0 - smoothstep(0.25, 0.5, distance_from_center);
	
	float final_alpha = COLOR.a * edge_fade;
	
	COLOR = vec4(0.65, 0.75, 0.90, final_alpha);
}
