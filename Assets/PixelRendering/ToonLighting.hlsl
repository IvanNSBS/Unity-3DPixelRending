#ifndef CUSTOM_TOON_LIGHTING
#define CUSTOM_TOON_LIGHTING

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct ToonLightingData
{
    float3 normal;
    float3 albedo; 
};

struct CustomLight
{
    float3 direction;
    float distanceAttenuation;
    float shadowAttenuation;
    float3 color;
    float3 layerMask;
};

// Fills a light struct given a perObjectLightIndex
Light GetAdditionalPerObjectLightCustom(int perObjectLightIndex, float3 positionWS)
{
    // Abstraction over Light input constants
    #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    float4 lightPositionWS = _AdditionalLightsBuffer[perObjectLightIndex].position;
    half3 color = _AdditionalLightsBuffer[perObjectLightIndex].color.rgb;
    half4 distanceAndSpotAttenuation = _AdditionalLightsBuffer[perObjectLightIndex].attenuation;
    half4 spotDirection = _AdditionalLightsBuffer[perObjectLightIndex].spotDirection;
    uint lightLayerMask = _AdditionalLightsBuffer[perObjectLightIndex].layerMask;
    #else
    float4 lightPositionWS = _AdditionalLightsPosition[perObjectLightIndex];
    half3 color = _AdditionalLightsColor[perObjectLightIndex].rgb;
    half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[perObjectLightIndex];
    half4 spotDirection = _AdditionalLightsSpotDir[perObjectLightIndex];
    uint lightLayerMask = asuint(_AdditionalLightsLayerMasks[perObjectLightIndex]);
    #endif

    // Directional lights store direction in lightPosition.xyz and have .w set to 0.0.
    // This way the following code will work for both directional and punctual lights.
    float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
    float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
    // full-float precision required on some platforms
    float attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);
    int n = 3;
    float min_att = 0.4;
    float light_range = rcp(sqrt(distanceAndSpotAttenuation.x));
    
    float dst = distance(positionWS, lightPositionWS);
    if(dst > light_range)
    {
        attenuation = 0;
    }
    else
    {
        float old_min = 0, new_min = min_att;
        float old_max = 1, new_max = 1;

        float att = (light_range - dst) / light_range;
        att = smoothstep(0, 1, att);
        att = (att - old_min) * (new_max - new_min) / (old_max - old_min) + new_min;
                
        old_min = new_min, new_min = 1;
        old_max = new_max, new_max = n+1;
        att = (att - old_min) * (new_max - new_min) / (old_max - old_min) + new_min;
        att = floor(att);
        
        old_min = 0, new_min = min_att;
        old_max = 1, new_max = 1;
        att = (att - old_min) * (new_max - new_min) / (old_max - old_min) + new_min;

        attenuation = att;
    }

    Light light;
    light.direction = lightDirection;
    light.distanceAttenuation = attenuation;
    light.shadowAttenuation = 1.0; // This value can later be overridden in GetAdditionalLight(uint i, float3 positionWS, half4 shadowMask)
    light.color = color;
    light.layerMask = lightLayerMask;

    return light;
}

// Fills a light struct given a loop i index. This will convert the i
// index to a perObjectLightIndex
Light GetAdditionalLightCustom(uint i, float3 positionWS)
{
#if USE_FORWARD_PLUS
    int lightIndex = i;
#else
    int lightIndex = GetPerObjectLightIndex(i);
#endif
    return GetAdditionalPerObjectLightCustom(lightIndex, positionWS);
}

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
