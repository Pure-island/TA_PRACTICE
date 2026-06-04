Shader "TA_Practice/Chapter03/04_LambertDiffuse"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
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
            Name "ForwardLitSimple"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                // 法线要变换到世界空间，后面才能和主光源的世界空间方向做点乘。
                output.normalWS = normalInputs.normalWS;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                Light mainLight = GetMainLight();
                float3 normalWS = normalize(input.normalWS);
                float3 lightDirWS = normalize(mainLight.direction);

                // Lambert 漫反射核心：NdotL = max(0, dot(法线方向, 光照方向))。
                // 点乘越接近 1，表面越正对光源；接近 0，表面越侧向光源。
                half ndotl = saturate(dot(normalWS, lightDirWS));
                half3 diffuse = _BaseColor.rgb * mainLight.color * ndotl;

                return half4(diffuse, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
