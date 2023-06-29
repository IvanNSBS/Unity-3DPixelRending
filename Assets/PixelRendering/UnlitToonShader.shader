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
            sampler2D _NormalsPassTexture;
            float4 _NormalsPassTexture_TexelSize;
            float2 _ViewportSize;
            
            sampler2D _DepthPassTexture;
            
            float getDepth(int x, int y, float4 screenPos) {
                float2 vUv = screenPos.xy;
                float x_texel_size = _NormalsPassTexture_TexelSize.x;
                float y_texel_size = _NormalsPassTexture_TexelSize.y;
                return 1 - tex2D( _DepthPassTexture, vUv + float2(x * x_texel_size, y * y_texel_size) ).r;
            }

            float3 getNormal(int x, int y, float4 screenPos) {
                float2 vUv = screenPos.xy;
                float x_texel_size = _NormalsPassTexture_TexelSize.x;
                float y_texel_size = _NormalsPassTexture_TexelSize.y;
                
                return tex2D( _NormalsPassTexture, vUv + float2(x * x_texel_size, y * y_texel_size) ).rgb * 2.0 - 1.0;
            }

            float neighborNormalEdgeIndicator(int x, int y, float depth, float3 normal, float4 screenPos) {
                float depthDiff = getDepth(x, y, screenPos) - depth;
                
                // Edge pixels should yield to faces closer to the bias direction.
                float3 normalEdgeBias = float3(1., 1., 1.); // This should probably be a parameter.
                float normalDiff = dot(normal - getNormal(x, y, screenPos), normalEdgeBias);
                float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);
                
                // Only the shallower pixel should detect the normal edge.
                float depthIndicator = clamp(sign(depthDiff * .25 + .0025), 0.0, 1.0);

                return distance(normal, getNormal(x, y, screenPos)) * depthIndicator * normalIndicator;
            }

            float depthEdgeIndicator(float4 screenPos) {
                float depth = getDepth(0, 0, screenPos);
                float3 normal = getNormal(0, 0, screenPos);
                float diff = 0.0;
                diff += clamp(getDepth(1, 0, screenPos) - depth, 0.0, 1.0);
                diff += clamp(getDepth(-1, 0, screenPos) - depth, 0.0, 1.0);
                diff += clamp(getDepth(0, 1, screenPos) - depth, 0.0, 1.0);
                diff += clamp(getDepth(0, -1, screenPos) - depth, 0.0, 1.0);
                return floor(smoothstep(0.01, 0.02, diff) * 2.) / 2.;
            }

            float normalEdgeIndicator(float4 screenPos) {
                float depth = getDepth(0, 0, screenPos);
                float3 normal = getNormal(0, 0, screenPos);
                
                float indicator = 0.0;

                indicator += neighborNormalEdgeIndicator(0, -1, depth, normal, screenPos);
                indicator += neighborNormalEdgeIndicator(0, 1, depth, normal, screenPos);
                indicator += neighborNormalEdgeIndicator(-1, 0, depth, normal, screenPos);
                indicator += neighborNormalEdgeIndicator(1, 0, depth, normal, screenPos);

                return step(0.1, indicator);
            }

            float lum(float4 color) {
                float4 weights = float4(.2126, .7152, .0722, .0);
                return dot(color, weights);
            }

            float smoothSign(float x, float radius) {
                return smoothstep(-radius, radius, x) * 2.0 - 1.0;
            }
            
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
                if(cos < 0.2)
                    cos = 0.2;
                else
                    cos = 1;

                fixed3 col = _Color;
                // float tLum = lum(float4(col, 1));
                //float normalEdgeCoefficient = (smoothSign(tLum - .3, .1) + .7) * .25;
                //float depthEdgeCoefficient = (smoothSign(tLum - .3, .1) + .7) * .3;
                float normalEdgeCoefficient = 0.7;
                float depthEdgeCoefficient = 0.65;

                //float dei = depthEdgeIndicator(i.screenPos);
                //float nei = normalEdgeIndicator(i.screenPos);

                //float coefficient = dei > 0.0 ? (1.0 - depthEdgeCoefficient * dei) : (1.0 + normalEdgeCoefficient * nei);
                // float3 highlight = dei > 0.0 ? depthEdgeCoefficient : normalEdgeCoefficient;
                // float lrp = dei > 0.0 ? dei : nei;

                col = col * cos;
                // col = col * lightColor
                // col = lerp(col, highlight, lrp);
                // col = col * coefficient;
                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
