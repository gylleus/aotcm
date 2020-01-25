shader_type spatial;

uniform sampler2D noise_tex;

uniform float distortion;
uniform float distortion_speed;
uniform float distortion_y_factor;
uniform float scroll_speed = 1;
uniform int distinct_colors = 1;
uniform float alpha : hint_range(0.0,1.0);
uniform vec4 color1 : hint_color;
uniform vec4 color2 : hint_color;

uniform float albedo : hint_range(0.0,1.0);
uniform float emission : hint_range(0.0,1.0);

void vertex() {
    float current_distortion = sin(TIME * distortion_speed * (UV.x * UV.y) ) * distortion;
	VERTEX = VERTEX + NORMAL * current_distortion;
    VERTEX.y = VERTEX.y + current_distortion * distortion_y_factor;
}
	
void fragment() {
    float noise = texture(noise_tex, vec2(UV.x-TIME*scroll_speed, UV.y-TIME*scroll_speed/2.0)).b;
    noise = round(noise * float(distinct_colors)) / float(distinct_colors);
   // EMISSION = mix(color1, color2, noise).rgb;
    ALPHA = alpha;
    vec3 color = mix(color1, color2, noise).rgb;
    ALBEDO = color * vec3(albedo);
    EMISSION = color * emission;
}