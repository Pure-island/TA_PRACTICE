// ============================================================================
//  Shader 名称
//  这是一个“简易玻璃折射”示例，使用 URP 的 Opaque Texture 实现
// ============================================================================
Shader "TA_Practice/Chapter04/03_GlassRefractionStep_Tutorial"
{
    Properties
    {
        // 玻璃整体色调（含透明度）
        _BaseColor ("Glass Tint", Color) = (0.7, 0.9, 1, 0.35)

        // 扰动贴图：用来模拟玻璃表面的不均匀折射
        // 灰度值越亮，折射偏移越大
        _DistortionMap ("Distortion Mask", 2D) = "gray" {}

        // 折射强度：控制屏幕采样的偏移量
        _RefractionStrength ("Refraction Strength", Range(0, 0.1)) = 0.025

        // 颜色叠加强度：控制玻璃染色程度
        _TintStrength ("Tint Strength", Range(0, 1)) = 0.35
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
            Name "GlassRefractionStep"
            Tags { "LightMode" = "UniversalForward" }

            // ------------------------------------------------------------
            //  透明混合设置
            //  SrcAlpha + (1 - SrcAlpha)：标准 Alpha 混合
            // ------------------------------------------------------------
            Blend SrcAlpha OneMinusSrcAlpha

            // 关闭深度写入，防止透明物体遮挡后面物体
            ZWrite Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            // ------------------------------------------------------------
            //  URP 核心库
            // ------------------------------------------------------------
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 关键：声明并使用 _CameraOpaqueTexture
            // 这个宏会引入 SampleSceneColor 等函数
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
                half _TintStrength;
            CBUFFER_END

            // ------------------------------------------------------------
            //  输入结构（CPU → GPU）
            // ------------------------------------------------------------
            struct Attributes
            {
                float4 positionOS : POSITION; // 模型空间顶点
                float2 uv         : TEXCOORD0;
            };

            // ------------------------------------------------------------
            //  输出结构（顶点 → 片元）
            // ------------------------------------------------------------
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // 裁剪空间
                float2 uv          : TEXCOORD0;   // UV
            };

            // =================================================================
            //  顶点着色器
            // =================================================================
            Varyings Vert(Attributes input)
            {
                Varyings output;

                // 将对象空间顶点转换到裁剪空间
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                // 应用 Tiling 和 Offset
                output.uv = input.uv * _DistortionMap_ST.xy + _DistortionMap_ST.zw;

                return output;
            }

            // =================================================================
            //  片元着色器
            // =================================================================
            half4 Frag(Varyings input) : SV_Target
            {
                // ------------------------------------------------------------
                //  1. 计算屏幕 UV
                //  _ScaledScreenParams.xy = 当前渲染目标的像素尺寸
                //  这一步把裁剪空间坐标映射到 [0, 1] 的屏幕 UV
                // ------------------------------------------------------------
                float2 screenUV = input.positionHCS.xy / _ScaledScreenParams.xy;

                // ------------------------------------------------------------
                //  2. 采样扰动贴图
                //  使用灰度值模拟玻璃表面密度变化
                //  灰度 0.5 表示无偏移，>0.5 向上偏，<0.5 向下偏
                // ------------------------------------------------------------
                half distortion = SAMPLE_TEXTURE2D(
                    _DistortionMap, sampler_DistortionMap, input.uv).r;

                // 将 [0,1] 映射到 [-0.5, 0.5]
                float2 offset = (distortion - 0.5) * _RefractionStrength;

                // ------------------------------------------------------------
                //  3. 采样背后不透明物体
                //  SampleSceneColor 来自 _CameraOpaqueTexture
                //  相当于“抓取玻璃后面的画面”
                // ------------------------------------------------------------
                half3 sceneColor = SampleSceneColor(screenUV + offset);

                // ------------------------------------------------------------
                //  4. 玻璃染色（Tint）
                //  用玻璃颜色去影响背景色，模拟透光介质的颜色吸收
                // ------------------------------------------------------------
                half3 tinted = lerp(
                    sceneColor,
                    sceneColor * _BaseColor.rgb,
                    _TintStrength
                );

                // ------------------------------------------------------------
                //  5. 最终输出
                //  RGB：折射 + 染色后的背景
                //  A：玻璃透明度
                // ------------------------------------------------------------
                return half4(tinted, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}