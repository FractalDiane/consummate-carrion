shader_type canvas_item;
render_mode unshaded;

uniform float amount = 0.0f;

void vertex() {
	VERTEX.y += sin(VERTEX.y) * amount;
}
