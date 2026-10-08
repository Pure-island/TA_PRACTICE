Shader "TA_Practice/Chapter04/01_LambertPhongBlinn"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Shininess ("Shininess", Range(1, 256)) = 64
        [Enum(Lambert,0,Phong,1,BlinnPhong,2)] _LightingModel ("Lighting Model", Float) = 2
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
            Name "ForwardTraditionalLighting"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _SpecColor;
                float4 _BaseMap_ST;
                half _Shininess;
                half _LightingModel;
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
                return output;
            }

            half3 CalculateSpecular(float3 normalWS, float3 lightDirWS, float3 viewDirWS, half3 lightColor)
            {
                half specularTerm = 0;

                if (_LightingModel > 0.5 && _LightingModel < 1.5)
                {
                    // Phong：先用 reflect 得到反射方向 R，再计算 R 与视线 V 的夹角。
                    float3 reflectDirWS = reflect(-lightDirWS, normalWS);
                    specularTerm = pow(saturate(dot(reflectDirWS, viewDirWS)), _Shininess);
                }
                else if (_LightingModel >= 1.5)
                {
                    // Blinn-Phong：用半角向量 H 近似镜面方向，通常比 Phong 更稳定也更常用。
                    float3 halfDirWS = normalize(lightDirWS + viewDirWS);
                    specularTerm = pow(saturate(dot(normalWS, halfDirWS)), _Shininess);
                }

                return _SpecColor.rgb * lightColor * specularTerm;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                Light mainLight = GetMainLight();

                float3 normalWS = normalize(input.normalWS);
                float3 lightDirWS = normalize(mainLight.direction);
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(input.positionWS));

                // Lambert：漫反射强度只看法线 N 和光照方向 L 的点乘，也就是 NdotL。
                half ndotl = saturate(dot(normalWS, lightDirWS));
                half3 diffuse = baseSample.rgb * mainLight.color * ndotl;
                half3 specular = CalculateSpecular(normalWS, lightDirWS, viewDirWS, mainLight.color);

                // SampleSH 是 URP 中常用的球谐环境光近似，避免背光面完全黑掉。
                half3 ambient = SampleSH(normalWS) * baseSample.rgb;
                return half4(ambient + diffuse + specular, baseSample.a);
            }
            ENDHLSL
        }
    }
}
