shader_type canvas_item;
render_mode unshaded;

uniform sampler2D noise1 : hint_albedo;
uniform sampler2D noise2 : hint_albedo;
uniform sampler2D noise3 : hint_albedo;
uniform sampler2D noise4 : hint_albedo;
uniform float time_scale = 1f;
uniform vec2 uv_scale = vec2(1f);
uniform sampler2D gradient : hint_albedo;



void fragment() {
	vec3 noise_extra = (texture(noise1, UV * uv_scale + TIME * 0.025 * time_scale).rgb + texture(noise2, UV * uv_scale + TIME * 0.04 * time_scale).rgb) * 0.5 * (1f - UV.y);
	vec3 noise_extra_p = floor(noise_extra / 0.1) * 0.1;
	vec3 noisetex = (texture(noise3, UV * uv_scale + TIME * 0.025 * time_scale).rgb + texture(noise4, UV * uv_scale * 0.5 + TIME * 0.04 * time_scale).rgb) * 0.5;
	
	float value = (noise_extra_p.r + noise_extra_p.g + noise_extra_p.b) * 0.5;
	COLOR = vec4(texture(gradient, vec2(value)).rgb * 2.5, step(value, 0.75 * UV.y * 0.5));
	
	COLOR.rgb = texture(gradient, noise_extra.xy * 5f).rgb;
	COLOR.rgb = floor(COLOR.rgb / 0.1) * 0.1;
}