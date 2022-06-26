shader_type canvas_item;
render_mode unshaded;

uniform vec4 color : hint_color;

void fragment() {
	COLOR.rgb = color.rgb;
	COLOR.a = distance(vec2(0.5), UV);
}
