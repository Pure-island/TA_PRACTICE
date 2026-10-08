// ============================================================================
//  Shader：高级水面（折射 / 深度渐变 / 泡沫 / 焦散 / 菲涅尔）
//  这是一个偏向“写实游戏水”的综合示例
// ============================================================================
Shader "TA_Practice/Chapter04/05_WaterSurfaceAdvanced_Tutorial"
{
    Properties
    {
        // ------------------------------------------------------------
        //  纹理资源
        // ------------------------------------------------------------
        _WaterNormalMap ("Water Normal Map", 2D) = "bump" {} // 法线贴图（两层流动）
        _FoamMap ("Foam Mask", 2D) = "black" {}              // 泡沫纹理
        _CausticsMap ("Caustics Map", 2D) = "black" {}       // 焦散纹理

        // ------------------------------------------------------------
        //  颜色控制
        // ------------------------------------------------------------
        _ShallowColor ("Shallow Color", Color) = (0.15, 0.75, 0.85, 0.65) // 浅水
        _DeepColor ("Deep Color", Color) = (0.01, 0.12, 0.35, 0.85)      // 深水

        // ------------------------------------------------------------
        //  动态参数
        // ------------------------------------------------------------
        _WaveSpeed ("Wave Speed", Range(0, 3)) = 0.6
        _WaveStrength ("Wave Strength", Range(0, 1)) = 0.45

        // ------------------------------------------------------------
        //  光学参数
        // ------------------------------------------------------------
        _RefractionStrength ("Refraction Strength", Range(0, 0.08)) = 0.025
        _FresnelPower ("Fresnel Power", Range(1, 8)) = 4

        // ------------------------------------------------------------
        //  泡沫 & 焦散
        // ------------------------------------------------------------
        _FoamStrength ("Foam Strength", Range(0, 2)) = 0.8
        _FoamDepth ("Foam Depth", Range(0.01, 5)) = 1
        _CausticsStrength ("Caustics Strength", Range(0, 2)) = 0.4
        _DepthFadeDistance ("Depth Fade Distance", Range(0.1, 30)) = 8
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "WaterSurfaceAdvanced"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            // ------------------------------------------------------------
            //  URP 核心库
            // ------------------------------------------------------------
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // ------------------------------------------------------------
            //  纹理声明
            // ------------------------------------------------------------
            TEXTURE2D(_WaterNormalMap);
            SAMPLER(sampler_WaterNormalMap);

            TEXTURE2D(_FoamMap);
            SAMPLER(sampler_FoamMap);

            TEXTURE2D(_CausticsMap);
            SAMPLER(sampler_CausticsMap);

            // ------------------------------------------------------------
            //  Per Material CBuffer
            // ------------------------------------------------------------
            CBUFFER_START(UnityPerMaterial)
                half4 _ShallowColor;
                half4 _DeepColor;
                float4 _WaterNormalMap_ST;
                float4 _FoamMap_ST;
                float4 _CausticsMap_ST;
                half _WaveSpeed;
                half _WaveStrength;
                half _RefractionStrength;
                half _FresnelPower;
                half _FoamStrength;
                half _FoamDepth;
                half _CausticsStrength;
                half _DepthFadeDistance;
            CBUFFER_END

            // ------------------------------------------------------------
            //  输入输出结构
            // ------------------------------------------------------------
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float2 uv          : TEXCOORD2;
            };

            // =================================================================
            //  顶点着色器
            // =================================================================
            Varyings Vert(Attributes input)
            {
                Varyings output;
                float3 positionOS = input.positionOS.xyz;

                // ------------------------------------------------------------
                //  顶点波浪（几何层面）
                //  用 sin 叠加制造低频大波浪
                // ------------------------------------------------------------
                float wave =
                    sin(_Time.y * _WaveSpeed + positionOS.x * 2.1) *
                    sin(_Time.y * _WaveSpeed * 1.37 + positionOS.z * 1.8);

                positionOS.y += wave * _WaveStrength * 0.08;

                VertexPositionInputs positionInputs =
                    GetVertexPositionInputs(positionOS);

                VertexNormalInputs normalInputs =
                    GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.positionWS  = positionInputs.positionWS;
                output.normalWS    = normalInputs.normalWS;
                output.uv          = input.uv;

                return output;
            }

            // =================================================================
            //  动画法线采样（双层流动）
            // =================================================================
            half3 SampleAnimatedNormal(float2 uv)
            {
                // 第一层法线（慢速）
                float2 uv1 = uv * _WaterNormalMap_ST.xy +
                             _WaterNormalMap_ST.zw +
                             _Time.y * _WaveSpeed * float2(0.04, 0.03);

                // 第二层法线（反向快速）
                float2 uv2 = uv * _WaterNormalMap_ST.xy * 1.7 -
                             _Time.y * _WaveSpeed * float2(0.03, 0.05);

                half3 normalA = UnpackNormal(
                    SAMPLE_TEXTURE2D(_WaterNormalMap, sampler_WaterNormalMap, uv1));
                half3 normalB = UnpackNormal(
                    SAMPLE_TEXTURE2D(_WaterNormalMap, sampler_WaterNormalMap, uv2));

                // 混合两层法线
                half3 mixed = normalize(normalA + normalB);

                // 用 WaveStrength 控制扰动强度
                mixed.xy *= _WaveStrength;
                return normalize(mixed);
            }

            // =================================================================
            //  片元着色器
            // =================================================================
            half4 Frag(Varyings input) : SV_Target
            {
                // ------------------------------------------------------------
                //  1. 屏幕 UV（用于抓取背景）
                // ------------------------------------------------------------
                float2 screenUV = input.positionHCS.xy / _ScaledScreenParams.xy;

                // ------------------------------------------------------------
                //  2. 采样动态水法线
                // ------------------------------------------------------------
                half3 tangentNormal = SampleAnimatedNormal(input.uv);

                // ------------------------------------------------------------
                //  3. 折射偏移（简化版）
                //  直接用切线空间法线的 xy 扰动屏幕 UV
                // ------------------------------------------------------------
                float2 refractionOffset = tangentNormal.xy * _RefractionStrength;
                half3 refractedScene = SampleSceneColor(screenUV + refractionOffset);

                // ------------------------------------------------------------
                //  4. 深度检测（核心）
                //  判断水下方物体的距离，用来区分“浅水 / 深水”
                // ------------------------------------------------------------
                float rawSceneDepth = SampleSceneDepth(screenUV);
                float sceneEyeDepth = LinearEyeDepth(rawSceneDepth, _ZBufferParams);

                float waterEyeDepth = LinearEyeDepth(input.positionHCS.z, _ZBufferParams);

                float depthDifference = max(sceneEyeDepth - waterEyeDepth, 0.0);
                half depthFactor = saturate(depthDifference / _DepthFadeDistance);

                // ------------------------------------------------------------
                //  5. 水的颜色混合
                //  近处浅色，远处深色
                // ------------------------------------------------------------
                half3 waterColor = lerp(
                    _ShallowColor.rgb,
                    _DeepColor.rgb,
                    depthFactor
                );

                // ------------------------------------------------------------
                //  6. 菲涅尔反射
                // ------------------------------------------------------------
                float3 viewDirWS = normalize(
                    GetWorldSpaceViewDir(input.positionWS));

                half fresnel = pow(
                    1.0 - saturate(dot(normalize(input.normalWS), viewDirWS)),
                    _FresnelPower
                );

                // 用 SH 近似环境反射（低成本）
                half3 reflectionApprox = SampleSH(
                    reflect(-viewDirWS, normalize(input.normalWS)));

                // ------------------------------------------------------------
                //  7. 泡沫效果
                //  只在靠近岸边（depth 小）的地方显示
                // ------------------------------------------------------------
                float2 foamUv = input.uv * _FoamMap_ST.xy +
                                _FoamMap_ST.zw +
                                _Time.y * _WaveSpeed * 0.03;

                half foamTex = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, foamUv).r;
                half foamMask = saturate(
                    (1.0 - saturate(depthDifference / _FoamDepth)) *
                    foamTex *
                    _FoamStrength
                );

                // ------------------------------------------------------------
                //  8. 焦散（Caustics）
                //  投影在水底的光斑，深水区更明显
                // ------------------------------------------------------------
                float2 causticsUv = input.positionWS.xz *
                                    _CausticsMap_ST.xy * 0.2 +
                                    _CausticsMap_ST.zw +
                                    _Time.y * _WaveSpeed * 0.08;

                half caustics = SAMPLE_TEXTURE2D(
                    _CausticsMap, sampler_CausticsMap, causticsUv).r *
                    _CausticsStrength *
                    (1.0 - depthFactor);

                // ------------------------------------------------------------
                //  9. 最终合成
                // ------------------------------------------------------------
                half3 color = lerp(
                    refractedScene * waterColor,
                    reflectionApprox,
                    fresnel * 0.6
                );

                color += caustics;
                color = lerp(color, half3(1, 1, 1), foamMask);

                half alpha = lerp(_ShallowColor.a, _DeepColor.a, depthFactor);
                return half4(color, alpha);
            }

            ENDHLSL
        }
    }
}