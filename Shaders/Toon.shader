shader_type spatial;

uniform sampler2D text : hint_albedo;
uniform sampler2D normal_map : hint_albedo;
uniform vec4 color : hint_color;
uniform vec4 outline_color : hint_color;
uniform bool useTexture = true;
uniform bool useNormalMap = false;

uniform float unlit_coefficient : hint_range(0.0,1.0) = 0.2;
uniform float cut_point : hint_range(0.0, 1.0) = 0.5;
uniform float normalMapDepth;

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
	float NdotL = calc_NdotL(LIGHT, NORMAL);
	
	vec3 _color = ALBEDO*unlit_coefficient*ATTENUATION;


	if (NdotL > cut_point) {
		_color = ALBEDO * ATTENUATION;	
	}

	DIFFUSE_LIGHT = _color;
	
}