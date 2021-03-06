#version 330 core

layout(location = 0) out vec4 color;

in vec2 v_TexCoord;
in vec3 v_SurfaceNormal;
in vec3 v_TangentToLightSource[MAX_LIGHTS];
in vec3 v_TangentToCamera;
in float v_Visibility;

struct PointLight
{
	vec3 color;
	vec3 attenuation;
};

uniform sampler2D u_Texture;

uniform bool u_HasSpecularMap;
uniform sampler2D u_SpecularMap;
uniform float u_ShineDistanceDamper;
uniform float u_Reflectivity;

uniform sampler2D u_NormalMap;

uniform float u_ParallaxMapAmplitude;
uniform sampler2D u_ParallaxMap;


uniform vec3 u_SkyColor;

uniform PointLight u_PointLights[MAX_LIGHTS];
uniform int u_LightsUsed;

#define PI 3.1416

#define LIGHTING_UNIFORMS_IN_TANGENT_SPACE
#include <phong_lighting.glsl>
#include <multiple_light_sources.glsl>

vec2 calculateParallaxTextureCoords();

void main(void)
{
	vec2 mappedTexCoords = calculateParallaxTextureCoords();

	vec4 texColor = texture(u_Texture, mappedTexCoords);
	if (texColor.a < 0.7)
		discard;

	vec3 unitSurfaceNorm = texture(u_NormalMap, mappedTexCoords).rgb;
	unitSurfaceNorm = normalize(unitSurfaceNorm * 2.0 - 1.0);

	vec3 unitVecToCamera = normalize(v_TangentToCamera);

	vec3 diffuse = vec3(0);
	vec3 specular = vec3(0);
	
	calculateLighting(unitVecToCamera, unitSurfaceNorm, mappedTexCoords, diffuse, specular);
	
	diffuse = max(diffuse, 0.2);

	color =	vec4(diffuse, 1) * texColor + vec4(specular, 1);
	color = mix(vec4(u_SkyColor.xyz, 1.0), color, v_Visibility);
}

vec2 calculateParallaxTextureCoords()
{
	vec3 unitVecToCamera = normalize(v_TangentToCamera);

	const float minLayers = 16.0;
	const float maxLayers = 32.0;

	//How similar the vector to the camera is to the surface normal
	float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), unitVecToCamera)));  
   	
    float layerDepth = 1.0 / numLayers;
    float currentLayerDepth = 0.0;
    // the amount to shift the texture coordinates per layer (from vector P)
    vec2 P = unitVecToCamera.xy * u_ParallaxMapAmplitude; 
    vec2 deltaTexCoords = P / numLayers;

    // get initial values
	vec2  currentTexCoords = v_TexCoord;
	float currentDepthMapValue = 1.0 - texture(u_ParallaxMap, currentTexCoords).r;
	  
	while(currentLayerDepth < currentDepthMapValue)
	{
	    // shift texture coordinates along direction of P
	    currentTexCoords.x += deltaTexCoords.x;
	    currentTexCoords.y -= deltaTexCoords.y;
	    // get depthmap value at current texture coordinates
	    currentDepthMapValue = texture(u_ParallaxMap, currentTexCoords).r;  
	    // get depth of next layer
	    currentLayerDepth += layerDepth;  
	}

	// get texture coordinates before collision (reverse operations)
	vec2 prevTexCoords = currentTexCoords + deltaTexCoords;

	// get depth after and before collision for linear interpolation
	float afterDepth  = currentDepthMapValue - currentLayerDepth;
	float beforeDepth = texture(u_ParallaxMap, prevTexCoords).r - currentLayerDepth + layerDepth;
	 
	// interpolation of texture coordinates
	float weight = afterDepth / (afterDepth - beforeDepth);
	vec2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

	return finalTexCoords;
}
