Shader "TA_Practice/Chapter03/01_UnlitColor"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 0.5, 0.2, 1)
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
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                // URP 中常用 HCS 表示 homogeneous clip space，也就是齐次裁剪空间。
                // 顶点着色器必须输出 SV_POSITION，GPU 后续才知道这个顶点在屏幕上的位置。
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                // Unlit 不参与光照，片元颜色完全由材质参数决定，适合先理解 ShaderLab 基本结构。
                return _BaseColor;
            }
            ENDHLSL
        }
    }
}
