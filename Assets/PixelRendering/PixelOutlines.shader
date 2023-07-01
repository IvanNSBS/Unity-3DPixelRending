

Shader "Hidden/PixelOutlines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white"
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        TEXTURE2D(_MainTex);
        float4 _MainTex_TexelSize;
        float4 _MainTex_ST;

        sampler2D _NormalsPassTexture;
        float4 _NormalsPassTexture_TexelSize;
        sampler2D _CameraDepthTexture;
        float4 _CameraDepthTexture_TexelSize;
        
        SamplerState sampler_point_clamp;
        
        uniform float2 _BlockCount;
        uniform float2 _BlockSize;
        uniform float2 _HalfBlockSize;

        float getDepth(int x, int y, float2 vUv) {
            float x_texel_size = _CameraDepthTexture_TexelSize.x;
            float y_texel_size = _CameraDepthTexture_TexelSize.y;
            return tex2D( _CameraDepthTexture, vUv + float2(x * x_texel_size, y * y_texel_size) ).r;
        }

        float3 getNormal(int x, int y, float2 vUv) {
            float x_texel_size = _NormalsPassTexture_TexelSize.x;
            float y_texel_size = _NormalsPassTexture_TexelSize.y;

            float3 normal = tex2D( _NormalsPassTexture, vUv + float2(x * x_texel_size, y * y_texel_size) ).rgb;
            normal = normal * 2.0 - 1.0;
            
            return normal;
        }

        float neighborNormalEdgeIndicator(int x, int y, float depth, float3 normal, float2 screenPos) {
            float depthDiff = getDepth(x, y, screenPos) - depth;
            float3 neighborNormal = getNormal(x, y, screenPos);
            
            // Edge pixels should yield to faces closer to the bias direction.
            float3 normalEdgeBias = float3(1., 1., 1.); // This should probably be a parameter.
            float normalDiff = dot(normal - neighborNormal, normalEdgeBias);
            float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);
            
            // Only the shallower pixel should detect the normal edge.
            float depthIndicator = clamp(sign(depthDiff * .25 + .0025), 0.0, 1.0);

            return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;
            return distance(normal, getNormal(x, y, screenPos)) * depthIndicator * normalIndicator;
        }

        float depthEdgeIndicator(float2 screenPos) {
            float depth = getDepth(0, 0, screenPos);
            float diff = 0.0;
            diff += clamp(getDepth(1, 0, screenPos) - depth, 0.0, 1.0);
            diff += clamp(getDepth(-1, 0, screenPos) - depth, 0.0, 1.0);
            diff += clamp(getDepth(0, 1, screenPos) - depth, 0.0, 1.0);
            diff += clamp(getDepth(0, -1, screenPos) - depth, 0.0, 1.0);
            return floor(smoothstep(0.01, 0.02, diff) * 2.) / 2.;
        }

        float normalEdgeIndicator(float2 screenPos) {
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
        
        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
            return OUT;
        }
        ENDHLSL

        Pass
        {
            Name "Pixelation"

            HLSLPROGRAM
            float4 frag(Varyings IN) : SV_TARGET
            {
                // float2 blockPos = floor(IN.uv * _BlockCount);
                // float2 uv = blockPos * _BlockSize + _HalfBlockSize;
                // return float4(IN.uv.xy, 0, 1);
                float4 texel = SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, IN.uv);

                float tLum = lum(texel);
                // float normalEdgeCoefficient = (smoothSign(tLum - .3, .1) + .7) * .5;
                // float depthEdgeCoefficient = (smoothSign(tLum - .3, .1) + .7) * .6;
                float normalEdgeStrength = .9;
                float depthEdgeStrength = 0.7;

                float dei = depthEdgeIndicator(IN.uv);
                float nei = normalEdgeIndicator(IN.uv);

                float coefficient = dei > 0.0 ? (1.0 - depthEdgeStrength * dei) : (1.0 + normalEdgeStrength * nei);

                // return float4(getNormal(0, 0, IN.uv), 1);
                // return float4(getNormal(0,0, IN.uv), 1);
                return texel * coefficient;
                // return float4(dei, dei, dei, 1);
                // return float4(nei, nei, nei, 1);
                // return float4(coefficient, coefficient, coefficient, 1);
                // return float4(dei + nei, dei + nei, dei + nei, 1);
            }
            ENDHLSL
        }

        
    }
}