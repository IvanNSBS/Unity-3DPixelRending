Shader "Unlit/UnlitToonShader"
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
            "PassFlags"="OnlyDirectional "
        }
        LOD 100

        Pass
        {
            ZWrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 screenPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            float4 _Color;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the xCoord
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0;
                
                float cos = max(0, dot(lightDirection, i.normal));
                cos = clamp(cos, 0.4, 1);
                // if(cos < 0.4)
                //     cos = 0.4;
                // else
                //     cos = 1;

                fixed3 col = _Color;
                col = col * cos; //* lightColor;
                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
