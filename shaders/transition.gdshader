shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(0f, 1f);
uniform sampler2D mask : hint_albedo;

void fragment() {
	float value = texture(mask, UV).r;
	COLOR = vec4(COLOR.rgb, float(value >= cutoff));
}
