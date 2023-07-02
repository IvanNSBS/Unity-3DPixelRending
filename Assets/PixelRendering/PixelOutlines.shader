

Shader "Hidden/PixelOutlines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white"
    	_depthEdgeStrength("_depthEdgeStrength", Float) = 0.3
    	_normalEdgeStrength("_normalEdgeStrength", Float) = 0.4
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
        sampler2D _DepthTexture;
        
        SamplerState sampler_point_clamp;
        
        uniform float _depthEdgeStrength;
        uniform float _normalEdgeStrength;

        float getDepth(int x, int y, float2 vUv) {
            return tex2D( _DepthTexture, vUv + float2(x, y)*_MainTex_TexelSize.xy ).r;
        }

        float3 getNormal(int x, int y, float2 vUv) {
            return tex2D( _NormalsPassTexture, vUv + float2(x, y)*_MainTex_TexelSize.xy ).rgb * 2.0 - 1.0;
        }

		float depthEdgeIndicator(float depth, float3 normal, float2 vUv) {
			float diff = 0.0;
			diff += clamp(getDepth(1, 0, vUv) - depth, 0.0, 1.0);
			diff += clamp(getDepth(-1, 0, vUv) - depth, 0.0, 1.0);
			diff += clamp(getDepth(0, 1, vUv) - depth, 0.0, 1.0);
			diff += clamp(getDepth(0, -1, vUv) - depth, 0.0, 1.0);
			return floor(smoothstep(0.01, 0.02, diff) * 2.) / 2.;
		}
        
        float neighborNormalEdgeIndicator(int x, int y, float depth, float3 normal, float2 vUv)
        {
			float depthDiff = getDepth(x, y, vUv) - depth;
			float3 neighborNormal = getNormal(x, y, vUv);
			
			// Edge pixels should yield to faces who's normals are closer to the bias normal.
			float3 normalEdgeBias = float3(1., 1., 1.); // This should probably be a parameter.
			float normalDiff = dot(normal - neighborNormal, normalEdgeBias);
			float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);
			
			// Only the shallower pixel should detect the normal edge.
			float depthIndicator = clamp(sign(depthDiff * .25 + .0025), 0.0, 1.0);

			return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;
            return distance(normal, getNormal(x, y, vUv)) * depthIndicator * normalIndicator;
		}

		float normalEdgeIndicator(float depth, float3 normal, float2 vUv)
        {
			float indicator = 0.0;

			indicator += neighborNormalEdgeIndicator(0, -1, depth, normal, vUv);
			indicator += neighborNormalEdgeIndicator(0, 1, depth, normal, vUv);
			indicator += neighborNormalEdgeIndicator(-1, 0, depth, normal, vUv);
			indicator += neighborNormalEdgeIndicator(1, 0, depth, normal, vUv);

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
            // OUT.uv = IN.uv; 
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

				float depth = 0.0;
				float3 normal = float3(0., 0., 0.);

				if (_depthEdgeStrength > 0.0 || _normalEdgeStrength > 0.0) {
					depth = getDepth(0, 0, IN.uv);
					normal = getNormal(0, 0,IN.uv);
				}

				float dei = 0.0;
				if (_depthEdgeStrength > 0.0) 
					dei = depthEdgeIndicator(depth, normal, IN.uv);

				float nei = 0.0; 
				if (_normalEdgeStrength > 0.0) 
					nei = normalEdgeIndicator(dei, normal, IN.uv);

				float strength = dei > 0.0 ? (1.0 - _depthEdgeStrength * dei) : (1.0 + _normalEdgeStrength * nei);
				
            	return texel * strength;
            	
                // float depth = 1 - tex2D(_DepthTexture, IN.uv).r;
                // float3 normal = tex2D( _NormalsPassTexture, IN.uv);
                // return float4(depth * 5, 0., 0., 1);
                // return float4(normal, 1);
                // return float4(getNormal(0, 0, IN.uv), 1);
                // return float4(getNormal(0,0, IN.uv), 1);
                return float4(dei, dei, dei, 1);
                // return float4(nei, nei, nei, 1);
                // return float4(coefficient, coefficient, coefficient, 1);
                // return float4(dei + nei, dei + nei, dei + nei, 1);
            }
            ENDHLSL
        }

        
    }
}