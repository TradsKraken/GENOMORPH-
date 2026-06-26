shader_type canvas_item;

uniform float scroll_offset : hint_range(0.0, 1.0) = 0.0;
uniform float line_density : hint_range(10.0, 300.0) = 80.0;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.07;

void fragment() {
	float y = UV.y + scroll_offset;
	float line = mod(y * line_density, 1.0);
	float mask = step(0.5, line);
	COLOR = vec4(0.0, 0.0, 0.0, mask * line_alpha);
}
