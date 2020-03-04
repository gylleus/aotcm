shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx, world_vertex_coords;
uniform vec4 albedo : hint_color;
uniform vec4 albedo_offset : hint_color;
uniform sampler2D texture_pattern : hint_albedo;
uniform float specular : hint_range(0,1);
uniform float metallic : hint_range(0,1);
uniform float grow;
uniform float roughness : hint_range(0,1);
uniform vec3 uv1_offset;
uniform float uv1_scale;
uniform vec2 wind;
uniform float fur_length;
uniform float fur_shape;
uniform float gravity;


