Shader "Hidden/UpscalePixelRT"
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
        SamplerState sampler_point_clamp;
        SamplerState sampler_bilinear_clamp;
        
        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            OUT.uv = IN.uv; 
            return OUT;
        }
        ENDHLSL

        Pass
        {
            Name "Pixelation"

            HLSLPROGRAM
            float4 frag(Varyings IN) : SV_TARGET
            {
                float2 boxSize = clamp(fwidth(IN.uv) * 0.70 * _MainTex_TexelSize.zw, 1e-5, 1);
                float2 tx = IN.uv * _MainTex_TexelSize.zw - 0.5 * boxSize;
                float2 txOffset = saturate((frac(tx) - (1 - boxSize)) / boxSize);
                float2 uv = (floor(tx) + 0.5 + txOffset) * _MainTex_TexelSize.xy;

                float4 texel = SAMPLE_TEXTURE2D_GRAD( _MainTex, sampler_bilinear_clamp, uv, ddx(IN.uv), ddy(IN.uv) );
                return texel;
            }
            ENDHLSL
        }

        
    }
}