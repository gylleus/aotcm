shader_type spatial;
render_mode cull_disabled;
uniform float outline_thickness = 2.0;
uniform vec4 outline_color : hint_color;

void vertex() {
	VERTEX = VERTEX + (NORMAL * outline_thickness);
}
	
void fragment() {
	ALBEDO = outline_color.rgb;
	if (FRONT_FACING) {
		ALPHA = 0.0;
	}
}