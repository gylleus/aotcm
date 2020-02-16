shader_type spatial;

uniform sampler2D text : hint_albedo;
uniform sampler2D normal_map : hint_albedo;
uniform vec4 color : hint_color;
uniform bool useTexture = true;
uniform bool useNormalMap = false;

uniform float unlit_coefficient : hint_range(0.0,1.0) = 0.2;
uniform float normalMapDepth;
uniform int distinct_colors : hint_range(1.0, 10.0) = 2;

uniform float cutoff_point : hint_range(-1.0, 1.0) = 0.0;
uniform float transition_width : hint_range(0.0, 1.0) = 0.0;

void fragment()
{
	if(useTexture)
	{
		vec3 a1 = texture(text, UV).rgb;
		ALBEDO = a1*color.rgb;
	} else
	{
		ALBEDO = color.rgb;
	}
	if(useNormalMap == true)
	{
		vec3 normalmap = texture(normal_map, UV).xyz * vec3(2.0,2.0,2.0) - vec3(1.0,1.0,1.0);
		vec3 normal = normalize(TANGENT * normalmap.y + BINORMAL * normalmap.x + NORMAL * normalmap.z);
		NORMAL = normal;
	} else
	{
		NORMALMAP_DEPTH = 0.0;
	}
}
float calc_NdotL(vec3 light, vec3 normal)
{
	float NdotL = dot(normalize(light), normal);
	return NdotL;
}

void light()
{
	float NdotL = calc_NdotL(LIGHT, NORMAL) + 1.0;
	
	vec3 unlit_color = ALBEDO*unlit_coefficient;

    vec3 _color = ALBEDO;   

    float begin_cut = cutoff_point + transition_width/2.0 + 1.0;
    float end_cut = cutoff_point - (transition_width/2.0) + 1.0;

    if (NdotL < begin_cut) {
        float l = (NdotL - end_cut) / (begin_cut - end_cut);
        float coeff = (floor(l * float(distinct_colors)) / float(distinct_colors));
        _color = mix(unlit_color, ALBEDO, coeff);
      //  _color = vec3(coeff);
    }
    if (NdotL < end_cut) {
        _color = unlit_color;
    }
    /*if (NdotL < cutoff_point) {
        float coeff = min(ceil(NdotL * (1.0-cutoff_point) * float(distinct_colors)) / float(distinct_colors),1);
        _color = mix(unlit_color, ALBEDO, coeff);
    }*/

	DIFFUSE_LIGHT = _color * ATTENUATION;
	
}