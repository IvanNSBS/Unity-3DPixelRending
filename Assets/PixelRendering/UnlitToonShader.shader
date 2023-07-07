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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
            #include "./ToonLighting.hlsl"

            struct appdata
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float3 fragmentPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
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
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the xCoord
                Light main_light = GetMainLight();
                float3 lightColor = main_light.color;
                float3 lightDirection = normalize(main_light.direction);

                float cos = saturate(dot(lightDirection, i.normal));
                cos = clamp(cos, 0.2, 1);

                float3 col = _Color;
                col = col * cos * lightColor;

                float count = GetAdditionalLightsCount();
                for(int j = 0; j < count; j++)
                {
                    Light light = GetAdditionalLight(j, i.fragmentPos, 1);
                    
                    float diffuse = saturate(dot(i.normal, light.direction));
                    float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                    float3 color = _Color * radiance * diffuse;
                    
                    col += color;
                }

                // if(cos < 0.4)
                //     cos = 0.4;
                // else
                //     cos = 1;


                return float4(col, 1);
            }
            ENDHLSL
        }
    }
}
