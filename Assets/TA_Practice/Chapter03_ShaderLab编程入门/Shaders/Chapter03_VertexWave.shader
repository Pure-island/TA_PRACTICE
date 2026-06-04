Shader "TA_Practice/Chapter03/03_VertexWave"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.2, 0.7, 1, 1)
        _WaveAmplitude ("Wave Amplitude", Range(0, 1)) = 0.2
        _WaveFrequency ("Wave Frequency", Range(0, 20)) = 4
        _WaveSpeed ("Wave Speed", Range(0, 10)) = 2
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
                float _WaveAmplitude;
                float _WaveFrequency;
                float _WaveSpeed;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half waveFactor : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                float3 positionOS = input.positionOS.xyz;

                // 顶点函数适合做“每个顶点一次”的变形，例如水面、旗帜、草的摆动。
                // 这里在对象空间修改 y 坐标，再送入对象到裁剪空间的变换。
                float wave = sin(_Time.y * _WaveSpeed + positionOS.x * _WaveFrequency) * _WaveAmplitude;
                positionOS.y += wave;

                output.positionHCS = TransformObjectToHClip(positionOS);
                output.waveFactor = saturate(wave / max(_WaveAmplitude, 0.0001) * 0.5 + 0.5);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                // 把波形强度混到颜色里，方便在 Scene/Game 视图里观察顶点阶段传下来的数据。
                half3 color = lerp(_BaseColor.rgb * 0.5, _BaseColor.rgb, input.waveFactor);
                return half4(color, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
