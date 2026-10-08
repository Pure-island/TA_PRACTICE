Shader "TA_Practice/Chapter05/URPPostProcess"
{
    Properties
    {
        // ==================== 基础后处理参数 ====================
        _GrayscaleIntensity ("Grayscale Intensity", Range(0, 1)) = 0
        _CrtIntensity ("CRT Intensity", Range(0, 1)) = 0
        _ScanlineIntensity ("Scanline Intensity", Range(0, 1)) = 0.45
        _ScanlineCount ("Scanline Count", Range(80, 900)) = 360
        _Curvature ("Curvature", Range(0, 0.25)) = 0.08
        _VignetteIntensity ("Vignette Intensity", Range(0, 1)) = 0.45
        
        // ==================== 边缘检测参数 ====================
        _EdgeIntensity ("Edge Intensity", Range(0, 1)) = 0
        _EdgeThreshold ("Edge Threshold", Range(0.01, 1)) = 0.18
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        
        // ==================== 模糊参数 ====================
        _BlurIntensity ("Blur Intensity", Range(0, 1)) = 0
        _BlurSize ("Blur Size", Range(0.1, 8)) = 1.5
        
        // ==================== Bloom参数 ====================
        _BloomIntensity ("Bloom Intensity", Range(0, 3)) = 0
        _BloomThreshold ("Bloom Threshold", Range(0, 4)) = 1
        _BloomSoftKnee ("Bloom Soft Knee", Range(0, 1)) = 0.5
        _BloomRadius ("Bloom Radius", Range(0.5, 6)) = 2
        
        // ==================== 运动模糊参数 ====================
        _MotionBlurIntensity ("Motion Blur Intensity", Range(0, 1)) = 0
        _MotionBlurDirection ("Motion Blur Direction", Vector) = (1, 0, 0, 0)
        _MotionBlurSamples ("Motion Blur Samples", Range(2, 8)) = 6
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        // 关闭深度写入和深度测试，确保全屏覆盖
        ZWrite Off
        ZTest Always
        Cull Off

        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        // ==================== 变量声明 ====================
        float _GrayscaleIntensity;
        float _CrtIntensity;
        float _ScanlineIntensity;
        float _ScanlineCount;
        float _Curvature;
        float _VignetteIntensity;
        float _EdgeIntensity;
        float _EdgeThreshold;
        float4 _EdgeColor;
        float _BlurIntensity;
        float _BlurSize;
        float _BloomIntensity;
        float _BloomThreshold;
        float _BloomSoftKnee;
        float _BloomRadius;
        float _MotionBlurIntensity;
        float2 _MotionBlurDirection;
        float _MotionBlurSamples;

        // ==================== 工具函数 ====================
        
        /// <summary>
        /// 采样源纹理（URP的Blit纹理）
        /// </summary>
        half4 SampleSource(float2 uv)
        {
            return SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv);
        }

        /// <summary>
        /// 计算亮度（感知加权）
        /// 使用人眼对颜色的敏感度权重，比简单平均更准确
        /// </summary>
        half Luminance(half3 color)
        {
            return dot(color, half3(0.299, 0.587, 0.114));
        }

        /// <summary>
        /// 应用CRT曲面曲率
        /// 将UV坐标向外推，模拟老式CRT显示器的曲面效果
        /// </summary>
        float2 ApplyCrtCurvature(float2 uv)
        {
            // 将UV从[0,1]转换到[-1,1]的中心坐标系
            float2 centered = uv * 2.0 - 1.0;
            
            // 根据UV的偏移量计算曲率变形
            float2 offset = abs(centered.yx) * centered.yx;
            centered += centered * offset * _Curvature;
            
            // 转换回[0,1]范围
            return centered * 0.5 + 0.5;
        }

        /// <summary>
        /// Bloom提取函数
        /// 提取超过阈值的亮部区域，用于光晕效果
        /// </summary>
        half3 ExtractBloom(half3 color)
        {
            // 找到最亮的颜色通道
            half brightness = max(max(color.r, color.g), color.b);
            
            // 软膝盖处理：在阈值附近平滑过渡
            float knee = max(_BloomThreshold * _BloomSoftKnee, 0.0001);
            float soft = brightness - (_BloomThreshold - knee);
            soft = saturate(soft / (2.0 * knee));
            soft = soft * soft * knee;
            
            // 计算贡献值：超过阈值的部分
            float contribution = max(brightness - _BloomThreshold, soft) / max(brightness, 0.0001);
            
            return color * contribution;
        }

        // ==================== 片元着色器 ====================
        
        /// <summary>
        /// 灰度效果Pass
        /// 将彩色图像转换为灰度图
        /// </summary>
        half4 FragGrayscale(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            half4 color = SampleSource(input.texcoord);
            half gray = Luminance(color.rgb);
            
            // 根据强度插值：原色 -> 灰度
            color.rgb = lerp(color.rgb, gray.xxx, _GrayscaleIntensity);
            return color;
        }

        /// <summary>
        /// CRT显示器效果Pass
        /// 模拟老式CRT显示器的视觉效果
        /// </summary>
        half4 FragCrt(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            // 应用曲面变形
            float2 curvedUv = ApplyCrtCurvature(input.texcoord);
            
            // 如果UV超出屏幕范围，返回黑色（模拟显示器边框）
            if (any(curvedUv < 0.0) || any(curvedUv > 1.0))
            {
                return half4(0, 0, 0, 1);
            }
            
            half4 color = SampleSource(curvedUv);
            
            // RGB通道偏移（色差效果）
            float2 chromaOffset = float2(_BlitTexture_TexelSize.x * 1.5, 0.0);
            half red = SampleSource(curvedUv + chromaOffset).r;
            half blue = SampleSource(curvedUv - chromaOffset).b;
            half3 colorBleed = half3(red, color.g, blue);
            color.rgb = lerp(color.rgb, colorBleed, _CrtIntensity * 0.5);
            
            // 扫描线效果（模拟CRT的栅条）
            float scanline = sin(input.texcoord.y * _ScanlineCount * 3.14159265) * 0.5 + 0.5;
            color.rgb *= lerp(1.0, scanline, _ScanlineIntensity * _CrtIntensity);
            
            // 暗角效果（模拟CRT屏幕边缘变暗）
            float2 center = input.texcoord - 0.5;
            float vignette = saturate(1.0 - dot(center, center) * _VignetteIntensity * 2.5);
            color.rgb *= lerp(1.0, vignette, _CrtIntensity);
            
            return color;
        }

        /// <summary>
        /// Sobel边缘检测Pass
        /// 使用Sobel算子检测图像边缘
        /// </summary>
        half4 FragSobel(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            float2 texel = _BlitTexture_TexelSize.xy; // 单个纹素的大小
            float2 uv = input.texcoord;
            
            // 采样3x3邻域的亮度值
            half tl = Luminance(SampleSource(uv + texel * float2(-1,  1)).rgb); // 左上
            half tc = Luminance(SampleSource(uv + texel * float2( 0,  1)).rgb); // 上
            half tr = Luminance(SampleSource(uv + texel * float2( 1,  1)).rgb); // 右上
            half ml = Luminance(SampleSource(uv + texel * float2(-1,  0)).rgb); // 左
            half mr = Luminance(SampleSource(uv + texel * float2( 1,  0)).rgb); // 右
            half bl = Luminance(SampleSource(uv + texel * float2(-1, -1)).rgb); // 左下
            half bc = Luminance(SampleSource(uv + texel * float2( 0, -1)).rgb); // 下
            half br = Luminance(SampleSource(uv + texel * float2( 1, -1)).rgb); // 右下
            
            // Sobel算子卷积核
            // Gx = [-1, 0, +1; -2, 0, +2; -1, 0, +1]  (水平梯度)
            // Gy = [-1, -2, -1;  0, 0,  0; +1, +2, +1]  (垂直梯度)
            half gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
            half gy = -bl - 2.0 * bc - br + tl + 2.0 * tc + tr;
            
            // 计算梯度幅度（边缘强度）
            float edge = saturate((abs(gx) + abs(gy) - _EdgeThreshold) / max(1.0 - _EdgeThreshold, 0.0001));
            
            half4 color = SampleSource(uv);
            // 用边缘强度混合原色和边缘颜色
            color.rgb = lerp(color.rgb, _EdgeColor.rgb, edge * _EdgeIntensity);
            return color;
        }

        /// <summary>
        /// 高斯模糊采样函数
        /// 沿指定方向进行一维高斯模糊采样
        /// </summary>
        half4 BlurAt(float2 uv, float2 direction)
        {
            // 高斯权重（7-tap，对称分布）
            // 权重总和应为1，保证亮度不变
            float2 stepUv = direction * _BlurSize;
            half4 color = SampleSource(uv) * 0.227027;          // 中心权重
            color += SampleSource(uv + stepUv * 1.0) * 0.1945946;
            color += SampleSource(uv - stepUv * 1.0) * 0.1945946;
            color += SampleSource(uv + stepUv * 2.0) * 0.1216216;
            color += SampleSource(uv - stepUv * 2.0) * 0.1216216;
            color += SampleSource(uv + stepUv * 3.0) * 0.054054;
            color += SampleSource(uv - stepUv * 3.0) * 0.054054;
            color += SampleSource(uv + stepUv * 4.0) * 0.016216;
            color += SampleSource(uv - stepUv * 4.0) * 0.016216;
            return color;
        }

        /// <summary>
        /// 水平高斯模糊Pass
        /// 只沿X轴进行模糊
        /// </summary>
        half4 FragBlurHorizontal(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            half4 original = SampleSource(input.texcoord);
            half4 blurred = BlurAt(input.texcoord, float2(_BlitTexture_TexelSize.x, 0.0));
            
            // 根据强度混合原图和模糊图
            return lerp(original, blurred, _BlurIntensity);
        }

        /// <summary>
        /// 垂直高斯模糊Pass
        /// 只沿Y轴进行模糊
        /// </summary>
        half4 FragBlurVertical(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            half4 original = SampleSource(input.texcoord);
            half4 blurred = BlurAt(input.texcoord, float2(0.0, _BlitTexture_TexelSize.y));
            
            return lerp(original, blurred, _BlurIntensity);
        }

        /// <summary>
        /// Bloom光晕效果Pass（教学版）
        /// 单Pass实现Bloom，便于理解原理
        /// </summary>
        half4 FragBloom(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            float2 uv = input.texcoord;
            half4 color = SampleSource(uv);
            float2 radius = _BlitTexture_TexelSize.xy * _BloomRadius;
            
            // 提取中心区域的亮部
            half3 bloom = ExtractBloom(color.rgb) * 0.25;
            
            // 采样周围8个方向的亮部，形成十字形扩散
            bloom += ExtractBloom(SampleSource(uv + radius * float2( 1,  0)).rgb) * 0.125;  // 右
            bloom += ExtractBloom(SampleSource(uv + radius * float2(-1,  0)).rgb) * 0.125;  // 左
            bloom += ExtractBloom(SampleSource(uv + radius * float2( 0,  1)).rgb) * 0.125;  // 上
            bloom += ExtractBloom(SampleSource(uv + radius * float2( 0, -1)).rgb) * 0.125;  // 下
            bloom += ExtractBloom(SampleSource(uv + radius * float2( 1,  1)).rgb) * 0.0625; // 右上
            bloom += ExtractBloom(SampleSource(uv + radius * float2(-1,  1)).rgb) * 0.0625; // 左上
            bloom += ExtractBloom(SampleSource(uv + radius * float2( 1, -1)).rgb) * 0.0625; // 右下
            bloom += ExtractBloom(SampleSource(uv + radius * float2(-1, -1)).rgb) * 0.0625; // 左下
            
            // 将Bloom叠加到原图上
            color.rgb += bloom * _BloomIntensity;
            return color;
        }

        /// <summary>
        /// 运动模糊Pass（教学版）
        /// 沿指定方向进行多次采样模拟运动模糊
        /// </summary>
        half4 FragMotionBlur(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            // 归一化方向向量（避免零向量）
            float2 direction = normalize(_MotionBlurDirection + float2(0.0001, 0.0001));
            
            // 计算每步的UV偏移量
            float2 stepUv = direction * _BlitTexture_TexelSize.xy * 3.0 * _MotionBlurIntensity;
            
            // 确保采样数在有效范围内
            float samples = clamp(_MotionBlurSamples, 2.0, 8.0);
            
            half4 accumulated = 0;  // 累积颜色
            half totalWeight = 0;    // 总权重
            
            // 沿方向进行多次采样
            [unroll]  // 循环展开，提高性能
            for (int i = 0; i < 8; i++)
            {
                // 计算当前采样位置（-0.5到0.5之间）
                float t = (i / max(samples - 1.0, 1.0)) - 0.5;
                
                // 判断是否启用该采样（防止越界）
                float enabled = step(i + 0.5, samples);
                half weight = enabled / samples;
                
                // 累积采样颜色
                accumulated += SampleSource(input.texcoord + stepUv * t) * weight;
                totalWeight += weight;
            }
            
            half4 original = SampleSource(input.texcoord);
            half4 blurred = accumulated / max(totalWeight, 0.0001);
            
            // 根据强度混合
            return lerp(original, blurred, _MotionBlurIntensity);
        }
        ENDHLSL

        // ==================== Pass定义 ====================
        
        Pass
        {
            Name "Grayscale"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragGrayscale
            ENDHLSL
        }

        Pass
        {
            Name "CRT"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragCrt
            ENDHLSL
        }

        Pass
        {
            Name "SobelEdge"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragSobel
            ENDHLSL
        }

        Pass
        {
            Name "GaussianBlurHorizontal"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragBlurHorizontal
            ENDHLSL
        }

        Pass
        {
            Name "GaussianBlurVertical"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragBlurVertical
            ENDHLSL
        }

        Pass
        {
            Name "BloomTeaching"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragBloom
            ENDHLSL
        }

        Pass
        {
            Name "MotionBlurTeaching"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragMotionBlur
            ENDHLSL
        }
    }
}