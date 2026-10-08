// ============================================================================
//  Shader：玻璃（含菲涅尔 / 色散 / 表面划痕）
//  这是一个“最终版”玻璃 Shader，偏向视觉表现而非物理绝对正确
// ============================================================================
Shader "TA_Practice/Chapter04/04_GlassFresnelFinal_Tutorial"
{
    Properties
    {
        // 玻璃基础颜色（RGB）+ 透明度（A）
        _BaseColor ("Glass Tint", Color) = (0.65, 0.9, 1, 0.42)

        // 扰动贴图：同时用于控制折射偏移 & 表面划痕
        _DistortionMap ("Distortion Mask", 2D) = "gray" {}

        // 折射偏移强度（屏幕 UV 偏移）
        _RefractionStrength ("Refraction Strength", Range(0, 0.15)) = 0.035

        // 色散强度：模拟不同波长的折射率差异
        _ChromaticAberration ("Chromatic Aberration", Range(0, 0.02)) = 0.004

        // 菲涅尔曲线硬度：值越大，边缘反射越锐利
        _FresnelPower ("Fresnel Power", Range(1, 8)) = 4

        // 反射强度（来自环境 SH）
        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 0.45

        // 划痕可见度
        _ScratchIntensity ("Scratch Intensity", Range(0, 1)) = 0.25
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
            Name "GlassFresnelFinal"
            Tags { "LightMode" = "UniversalForward" }

            // 标准 Alpha 混合
            Blend SrcAlpha OneMinusSrcAlpha

            // 透明物体通常不写深度
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

            // ------------------------------------------------------------
            //  纹理与采样器
            // ------------------------------------------------------------
            TEXTURE2D(_DistortionMap);
            SAMPLER(sampler_DistortionMap);

            // ------------------------------------------------------------
            //  Per Material CBuffer（SRP Batcher 兼容）
            // ------------------------------------------------------------
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _DistortionMap_ST;
                half _RefractionStrength;
                half _ChromaticAberration;
                half _FresnelPower;
                half _ReflectionStrength;
                half _ScratchIntensity;
            CBUFFER_END

            // ------------------------------------------------------------
            //  输入结构（CPU → GPU）
            // ------------------------------------------------------------
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            // ------------------------------------------------------------
            //  输出结构（顶点 → 片元）
            // ------------------------------------------------------------
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // 裁剪空间
                float3 positionWS  : TEXCOORD0;   // 世界坐标
                float3 normalWS    : TEXCOORD1;   // 世界法线
                float2 uv          : TEXCOORD2;   // UV
            };

            // =================================================================
            //  顶点着色器
            // =================================================================
            Varyings Vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs =
                    GetVertexPositionInputs(input.positionOS.xyz);

                VertexNormalInputs normalInputs =
                    GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.positionWS  = positionInputs.positionWS;
                output.normalWS    = normalInputs.normalWS;

                // Tiling & Offset
                output.uv = input.uv * _DistortionMap_ST.xy + _DistortionMap_ST.zw;

                return output;
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
                //  2. 基础向量
                // ------------------------------------------------------------
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(
                    GetWorldSpaceViewDir(input.positionWS));

                // ------------------------------------------------------------
                //  3. 采样扰动贴图
                //  灰度值用于模拟玻璃厚度 / 表面不规则性
                // ------------------------------------------------------------
                half scratch = SAMPLE_TEXTURE2D(
                    _DistortionMap, sampler_DistortionMap, input.uv).r;

                // 将 [0,1] 映射到 [-0.5, 0.5]
                float2 baseOffset = (scratch - 0.5) * _RefractionStrength;

                // ------------------------------------------------------------
                //  4. 色散（Chromatic Aberration）
                //  不同颜色通道使用不同偏移，模拟棱镜效果
                //  R → 向外偏移
                //  G → 无偏移
                //  B → 向内偏移
                // ------------------------------------------------------------
                half sceneR = SampleSceneColor(
                    screenUV + baseOffset + _ChromaticAberration).r;

                half sceneG = SampleSceneColor(
                    screenUV + baseOffset).g;

                half sceneB = SampleSceneColor(
                    screenUV + baseOffset - _ChromaticAberration).b;

                half3 refracted = half3(sceneR, sceneG, sceneB);

                // ------------------------------------------------------------
                //  5. 菲涅尔效应（Fresnel）
                //  视角越掠射（边缘），反射越强
                // ------------------------------------------------------------
                half fresnel = pow(
                    1.0 - saturate(dot(normalWS, viewDirWS)),
                    _FresnelPower
                );

                // ------------------------------------------------------------
                //  6. 环境反射（简化版）
                //  使用球谐函数（SH）近似环境反射
                // ------------------------------------------------------------
                half3 reflectionApprox =
                    SampleSH(reflect(-viewDirWS, normalWS));

                // ------------------------------------------------------------
                //  7. 折射 + 玻璃染色
                // ------------------------------------------------------------
                half3 tintedRefraction =
                    lerp(refracted, refracted * _BaseColor.rgb, 0.45);

                // ------------------------------------------------------------
                //  8. 折射 / 反射混合
                //  菲涅尔控制两者的权重
                // ------------------------------------------------------------
                half3 color = lerp(
                    tintedRefraction,
                    reflectionApprox,
                    fresnel * _ReflectionStrength
                );

                // ------------------------------------------------------------
                //  9. 划痕效果（视觉增强）
                //  用扰动贴图压暗局部区域，模拟表面磨损
                // ------------------------------------------------------------
                color *= 1.0 - scratch * _ScratchIntensity * fresnel;

                // ------------------------------------------------------------
                //  10. 最终输出
                // ------------------------------------------------------------
                return half4(color, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}