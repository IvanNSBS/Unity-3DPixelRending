#ifndef CUSTOM_TOON_LIGHTING
#define CUSTOM_TOON_LIGHTING

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct ToonLightingData
{
    float3 normal;
    float3 albedo; 
};

float GetSmoothnessPower(float rawSmoothness) {
    return exp2(10 * rawSmoothness + 1);
}

float3 ComputeLightingColors(float3 fragNormal, float3 fragPos)
{
    float3 lightColor = GetMainLight().color;
    int count = GetAdditionalLightsCount();
    
    for(int j = 0; j < count; j++)
    {
        Light light = GetAdditionalLight(j, fragPos);
        
        float3 radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    
        float diffuse = saturate(dot(fragNormal, light.direction));
        float3 color = radiance * (diffuse);
        
        lightColor += color;
    }

    return lightColor;
}

#endif
