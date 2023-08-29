Shader "Lit/UnlitToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1.0, 0.05, 0, 1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            "LightMode" = "UniversalForward"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100

        Pass
        {
            ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_HARD
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
            #include "./ToonLighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _ShadowColor;
            CBUFFER_END
            
            struct appdata
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 fragmentPos : TEXCOORD0;
                float3 worldSpacePos : TEXCOORD1;
            };

            float4 _Color;
            uniform float3 _Position;
            
            v2f vert (appdata v)
            {
                VertexPositionInputs posnInputs = GetVertexPositionInputs(v.vertexOS);

                v2f o;
                o.vertex = TransformObjectToHClip(v.vertexOS);
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normalOS));
                o.fragmentPos = posnInputs.positionWS;
                o.worldSpacePos = mul(unity_ObjectToWorld, v.vertexOS);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the xCoord
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldSpacePos);
                Light main_light = GetMainLight(shadowCoord);
                main_light.shadowAttenuation = clamp(main_light.shadowAttenuation, 0.3, 1);
                
                float3 lightColor = main_light.color * main_light.shadowAttenuation;
                float3 lightDirection = normalize(main_light.direction);

                float cos = saturate(dot(lightDirection, i.normal));
                cos = clamp(cos, 0.2, 1);

                float3 col = _Color;
                col = col * cos * lightColor;

                float count = GetAdditionalLightsCount();
                for(int j = 0; j < count; j++)
                {
                    Light light = GetAdditionalLightCustom(j, i.fragmentPos);
                    
                    float diffuse = saturate(dot(i.normal, light.direction));
                    float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                    float3 color = _Color * radiance; //* diffuse;
                    
                    col += color;
                }
                return float4(col, 1);
            }
            ENDHLSL
        }

        Pass {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
         
            ZWrite On
            ZTest LEqual
         
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x gles
            //#pragma target 4.5
         
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
         
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
                     
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
             
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
         
            ENDHLSL
        }
    }
}
