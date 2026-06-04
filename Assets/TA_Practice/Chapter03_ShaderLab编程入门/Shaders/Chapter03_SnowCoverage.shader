Shader "TA_Practice/Chapter03/05_SnowCoverage"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _SnowMap ("Snow Map", 2D) = "white" {}
        _SnowNoiseMap ("Snow Noise Mask", 2D) = "gray" {}
        _BaseColor ("Base Color", Color) = (0.6, 0.45, 0.3, 1)
        _SnowColor ("Snow Color", Color) = (0.9, 0.95, 1, 1)
        _SnowAmount ("Snow Amount", Range(0, 1)) = 1
        _SnowNormalThreshold ("Snow Normal Threshold", Range(0, 1)) = 0.35
        _SnowEdgeSoftness ("Snow Edge Softness", Range(0.001, 1)) = 0.35
        _SnowHeightStart ("Snow Height Start", Float) = -1
        _SnowHeightBlend ("Snow Height Blend", Range(0.01, 10)) = 2
        _SnowNoiseScale ("Snow Noise Scale", Range(0.01, 3)) = 0.35
        _SnowNoiseStrength ("Snow Noise Strength", Range(0, 1)) = 0.45
        _SnowTiling ("Snow Tiling", Range(0.1, 10)) = 1
        [Enum(Final,0,SnowFactor,1,NormalUp,2,Height,3,Noise,4)] _DebugView ("Debug View", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLitSnow"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_SnowMap);
            SAMPLER(sampler_SnowMap);
            TEXTURE2D(_SnowNoiseMap);
            SAMPLER(sampler_SnowNoiseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _SnowColor;
                float4 _BaseMap_ST;
                float4 _SnowMap_ST;
                float4 _SnowNoiseMap_ST;
                half _SnowAmount;
                half _SnowNormalThreshold;
                half _SnowEdgeSoftness;
                float _SnowHeightStart;
                float _SnowHeightBlend;
                float _SnowNoiseScale;
                half _SnowNoiseStrength;
                float _SnowTiling;
                half _DebugView;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float2 snowUv : TEXCOORD3;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                output.uv = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                output.snowUv = input.uv * _SnowMap_ST.xy * _SnowTiling + _SnowMap_ST.zw;
                return output;
            }

            half SampleSnowNoise(float3 positionWS)
            {
                // 噪声用世界空间 XZ 采样，避免完全依赖模型 UV，能让积雪边缘更自然。
                // 这对应教程里 NoiseTex 用来打散积雪分布的思路。
                float2 noiseUv = positionWS.xz * _SnowNoiseScale * _SnowNoiseMap_ST.xy + _SnowNoiseMap_ST.zw;
                return SAMPLE_TEXTURE2D(_SnowNoiseMap, sampler_SnowNoiseMap, noiseUv).r;
            }

            void CalculateSnowTerms(float3 normalWS, float3 positionWS, out half normalFactor, out half heightFactor, out half noiseFactor, out half snowFactor)
            {
                float3 unitNormal = normalize(normalWS);

                // 雪更容易堆在朝上的表面：世界空间法线与 up 的点乘越大，越接近水平朝上。
                half normalUp = saturate(dot(unitNormal, float3(0, 1, 0)));
                normalFactor = smoothstep(_SnowNormalThreshold, saturate(_SnowNormalThreshold + _SnowEdgeSoftness), normalUp);

                // 高度因子用来演示世界空间位置参与材质混合；高度越超过起始值，积雪越明显。
                heightFactor = saturate((positionWS.y - _SnowHeightStart) / max(_SnowHeightBlend, 0.0001));

                half rawNoise = SampleSnowNoise(positionWS);
                noiseFactor = lerp(1.0, rawNoise, _SnowNoiseStrength);

                snowFactor = saturate(normalFactor * heightFactor * noiseFactor * _SnowAmount);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                half4 snowSample = SAMPLE_TEXTURE2D(_SnowMap, sampler_SnowMap, input.snowUv) * _SnowColor;

                half normalFactor;
                half heightFactor;
                half noiseFactor;
                half snowFactor;
                CalculateSnowTerms(input.normalWS, input.positionWS, normalFactor, heightFactor, noiseFactor, snowFactor);

                if (_DebugView > 0.5 && _DebugView < 1.5)
                {
                    return half4(snowFactor.xxx, 1);
                }

                if (_DebugView > 1.5 && _DebugView < 2.5)
                {
                    return half4(normalFactor.xxx, 1);
                }

                if (_DebugView > 2.5 && _DebugView < 3.5)
                {
                    return half4(heightFactor.xxx, 1);
                }

                if (_DebugView > 3.5)
                {
                    return half4(noiseFactor.xxx, 1);
                }

                Light mainLight = GetMainLight();
                float3 normalWS = normalize(input.normalWS);
                half ndotl = saturate(dot(normalWS, normalize(mainLight.direction)));

                // 先混合基础纹理和雪纹理，再乘一个简单 Lambert 光照。
                // 这比纯颜色 lerp 更接近教程的多纹理积雪效果。
                half3 albedo = lerp(baseSample.rgb, snowSample.rgb, snowFactor);
                half3 litColor = albedo * mainLight.color * max(ndotl, 0.2);
                return half4(litColor, baseSample.a);
            }
            ENDHLSL
        }
    }
}
