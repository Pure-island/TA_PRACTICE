// ============================================================================
//  Shader 名称与路径
//  在 Unity 材质面板中显示为：TA_Practice/Chapter04/02_SimplePBR_GGX
// ============================================================================
Shader "TA_Practice/Chapter04/02_SimplePBR_GGX_Tutorial"
{
    // ========================================================================
    //  属性面板（Properties）
    //  这里的变量会暴露在 Inspector 中，方便美术调节
    // ========================================================================
    Properties
    {
        // 基础贴图（Albedo）
        _BaseMap ("Base Map (Albedo)", 2D) = "white" {}

        // 基础颜色，通常与 BaseMap 相乘
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        // 金属度：0 = 绝缘体（非金属），1 = 金属
        _Metallic ("Metallic", Range(0, 1)) = 0

        // 粗糙度：控制高光扩散程度
        // 最小值 0.04 是为了避免完全镜面反射导致的数值异常
        _Roughness ("Roughness", Range(0.04, 1)) = 0.5

        // 环境光遮蔽（Ambient Occlusion）
        _AO ("Ambient Occlusion", Range(0, 1)) = 1

        // 调试开关：用于可视化 BRDF 各分项
        [Toggle] _DebugTerms ("Debug BRDF Terms", Float) = 0
    }

    // ========================================================================
    //  SubShader
    //  定义渲染管线、渲染类型和渲染队列
    // ========================================================================
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" // 使用 URP 渲染管线
            "RenderType" = "Opaque"               // 不透明物体
            "Queue" = "Geometry"                  // 几何队列（最先渲染）
        }

        Pass
        {
            Name "ForwardSimplePBR"
            Tags { "LightMode" = "UniversalForward" } // URP 前向渲染路径

            HLSLPROGRAM

            // ----------------------------------------------------------------
            //  编译指令
            // ----------------------------------------------------------------
            #pragma vertex Vert      // 顶点着色器
            #pragma fragment Frag    // 片元着色器

            // ----------------------------------------------------------------
            //  引入 URP 内置库
            // ----------------------------------------------------------------
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ----------------------------------------------------------------
            //  常量定义
            // ----------------------------------------------------------------
            #define TA_PI 3.14159265

            // ----------------------------------------------------------------
            //  纹理与采样器声明
            // ----------------------------------------------------------------
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // ----------------------------------------------------------------
            //  Unity Per Material CBuffer
            //  所有材质参数必须放在这里，才能支持 SRP Batcher
            // ----------------------------------------------------------------
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;     // 贴图的 Tiling 和 Offset
                half _Metallic;
                half _Roughness;
                half _AO;
                half _DebugTerms;
            CBUFFER_END

            // ----------------------------------------------------------------
            //  输入结构体（从 CPU 到 GPU）
            // ----------------------------------------------------------------
            struct Attributes
            {
                float4 positionOS : POSITION;  // 模型空间顶点位置
                float3 normalOS   : NORMAL;   // 模型空间法线
                float2 uv         : TEXCOORD0; // UV 坐标
            };

            // ----------------------------------------------------------------
            //  插值后结构体（从顶点着色器到片元着色器）
            // ----------------------------------------------------------------
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // 裁剪空间位置
                float3 positionWS  : TEXCOORD0;  // 世界空间位置
                float3 normalWS    : TEXCOORD1;  // 世界空间法线
                float2 uv          : TEXCOORD2;  // 传递后的 UV
            };

            // =================================================================
            //  顶点着色器
            // =================================================================
            Varyings Vert(Attributes input)
            {
                Varyings output;

                // 使用 URP 内置函数计算顶点位置（自动处理 MVP 变换）
                VertexPositionInputs positionInputs =
                    GetVertexPositionInputs(input.positionOS.xyz);

                // 使用 URP 内置函数计算法线（自动处理法线矩阵变换）
                VertexNormalInputs normalInputs =
                    GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.positionWS  = positionInputs.positionWS;
                output.normalWS    = normalInputs.normalWS;

                // 应用 Tiling 和 Offset
                output.uv = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;

                return output;
            }

            // =================================================================
            //  PBR 核心函数
            // =================================================================

            // ----------------------------------------------------------------
            //  1. 法线分布函数（NDF）
            //  描述：微表面中，有多少比例的微平面法线与半角向量 H 对齐
            //  物理意义：决定高光的“尖锐”或“模糊”
            // ----------------------------------------------------------------
            float DistributionGGX(float ndoth, float roughness)
            {
                float a = roughness * roughness;
                float a2 = a * a;

                float denom = ndoth * ndoth * (a2 - 1.0) + 1.0;
                return a2 / max(TA_PI * denom * denom, 0.0001);
            }

            // ----------------------------------------------------------------
            //  2. 几何遮蔽函数（Geometry Function）
            //  描述：由于微表面凹凸不平，部分光线被自身遮挡
            //  包含：自遮挡（Shadowing）和自遮蔽（Masking）
            // ----------------------------------------------------------------
            float GeometrySchlickGGX(float ndotx, float roughness)
            {
                float r = roughness + 1.0;
                float k = (r * r) / 8.0; // UE4 风格的经验参数

                return ndotx / max(ndotx * (1.0 - k) + k, 0.0001);
            }

            float GeometrySmith(float ndotv, float ndotl, float roughness)
            {
                // 同时考虑视线方向和光照方向的遮蔽
                return GeometrySchlickGGX(ndotv, roughness) *
                       GeometrySchlickGGX(ndotl, roughness);
            }

            // ----------------------------------------------------------------
            //  3. 菲涅尔方程（Fresnel Equation）
            //  描述：视线角度越掠射（Grazing Angle），反射越强
            //  常用 Schlick 近似公式
            // ----------------------------------------------------------------
            float3 FresnelSchlick(float hdotv, float3 f0)
            {
                return f0 + (1.0 - f0) * pow(1.0 - hdotv, 5.0);
            }

            // =================================================================
            //  片元着色器
            // =================================================================
            half4 Frag(Varyings input) : SV_Target
            {
                // ---------- 1. 采样基础数据 ----------
                half3 albedo = SAMPLE_TEXTURE2D(
                    _BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;

                // 获取主光源（平行光）
                Light mainLight = GetMainLight();

                // ---------- 2. 向量准备 ----------
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(
                    GetWorldSpaceViewDir(input.positionWS));
                float3 lightDirWS = normalize(mainLight.direction);
                float3 halfDirWS = normalize(viewDirWS + lightDirWS);

                // ---------- 3. 点积计算 ----------
                float ndotl = saturate(dot(normalWS, lightDirWS));
                float ndotv = saturate(dot(normalWS, viewDirWS));
                float ndoth = saturate(dot(normalWS, halfDirWS));
                float hdotv = saturate(dot(halfDirWS, viewDirWS));

                // ---------- 4. 基础反射率 F0 ----------
                // 非金属：约 0.04
                // 金属：使用 albedo 作为反射颜色
                float3 f0 = lerp(float3(0.04, 0.04, 0.04), albedo, _Metallic);

                // ---------- 5. 计算 Cook-Torrance BRDF ----------
                float d = DistributionGGX(ndoth, _Roughness); // D
                float g = GeometrySmith(ndotv, ndotl, _Roughness); // G
                float3 f = FresnelSchlick(hdotv, f0); // F

                // 镜面反射项
                float3 specular = (d * g * f) /
                    max(4.0 * ndotv * ndotl, 0.0001);

                // ---------- 6. 漫反射项 ----------
                // 能量守恒：漫反射 = (1 - 菲涅尔) * (1 - 金属度)
                float3 kd = (1.0 - f) * (1.0 - _Metallic);
                float3 diffuse = kd * albedo / TA_PI;

                // ---------- 7. 直接光照 ----------
                float3 direct = (diffuse + specular) * mainLight.color * ndotl;

                // ---------- 8. 间接光照（环境光） ----------
                // SampleSH：使用球谐函数采样环境光
                float3 ambient = SampleSH(normalWS) * albedo * _AO;

                // ---------- 9. Debug 模式 ----------
                // R = D, G = G, B = F
                if (_DebugTerms > 0.5)
                {
                    return half4(d, g, f.r, 1);
                }

                // ---------- 10. 最终合成 ----------
                return half4(ambient + direct, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}