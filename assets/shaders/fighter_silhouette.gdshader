shader_type spatial;
render_mode unshaded, cull_back;

// Colore base del corpo: nero profondo
const vec3 BASE_COLOR = vec3(0.02, 0.02, 0.03);

uniform vec4 rim_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform float rim_intensity : hint_range(0.0, 10.0) = 3.5;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0; // Per impatti o Shadow Reflex

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	vec3 rim = rim_color.rgb * rim_intensity * fresnel;
	vec3 col = mix(BASE_COLOR + rim, vec3(1.0), flash_amount);
	ALBEDO = col;
}
