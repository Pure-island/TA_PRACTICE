# Chapter05 屏幕后期处理技术代码说明

本章对应课程第 05 章：黑白与 CRT、边缘检测、高斯模糊、Bloom、运动模糊，以及 URP 管线下的自定义后处理。项目使用 URP 17，因此这里不使用 Built-in 管线的 `OnRenderImage` 或 `Graphics.Blit` 摄像机脚本，而是使用 `ScriptableRendererFeature`、`ScriptableRenderPass`、RenderGraph 和 Volume 系统接入屏幕后处理。

## 文件结构

- `Runtime/Chapter05PostProcessFeature.cs`：URP Renderer Feature 入口，负责把本章后处理 pass 加入渲染器。
- `Runtime/Chapter05PostProcessPass.cs`：RenderGraph 后处理链路，按 Volume 参数顺序执行全屏 Shader pass。
- `Runtime/Chapter05PostProcessVolume.cs`：Volume 组件，暴露灰度、CRT、Sobel、模糊、Bloom、运动模糊参数。
- `Shaders/Chapter05_PostProcess.shader`：URP 全屏后处理 Shader，使用 `_BlitTexture` 读取当前相机颜色。
- `Tests/EditMode/Chapter05PostProcessVolumeTests.cs`：测试 Volume 激活规则和 Renderer Feature 默认注入点。

## Unity Editor 使用步骤

1. 创建一个 Material，Shader 选择 `TA_Practice/Chapter05/URPPostProcess`。
2. 打开当前使用的 URP Renderer Asset，例如 `PC_Renderer`。
3. 在 Renderer Features 中添加 `Chapter05PostProcessFeature`。
4. 将第 1 步创建的 Material 指定到 Feature 的 `Material` 字段；如果不指定 Material，也可以指定 Shader 字段。
5. 在场景中新建或选择一个 Global Volume。
6. 在 Volume Profile 中添加 `TA Practice/Chapter05 Post Process`。
7. 勾选需要调节的参数 override，并把对应强度从 0 调高。

注意：如果 Feature 没有效果，优先检查 Camera 是否使用了包含该 Feature 的 URP Renderer，以及 Volume 是否为 Global 或摄像机处于 Volume 范围内。

建议优先指定 Material 或 Shader 引用。Feature 会尝试用 `Shader.Find("TA_Practice/Chapter05/URPPostProcess")` 自动查找 Shader，但打包 Player 时如果没有资源引用保留该 Shader，可能需要把它加入 `Always Included Shaders`。

## 效果说明

### Grayscale

使用 `0.299R + 0.587G + 0.114B` 的感知亮度公式，而不是简单 RGB 平均值。这样绿色信息对灰度结果贡献更高，更接近人眼观察习惯。

### CRT

包含屏幕曲率、扫描线、RGB 通道轻微错位和暗角。它演示的是屏幕空间 UV 变形和多次采样的组合，不依赖模型或光照。

### Sobel Edge

使用 3x3 Sobel 卷积核计算亮度梯度。`Edge Threshold` 控制边缘敏感度，`Edge Intensity` 控制描边混合强度。

### Gaussian Blur

使用分离高斯思路：先水平模糊，再垂直模糊。`Blur Iterations` 会重复执行横向和纵向 pass，用更高成本换更强模糊。

### Bloom

本章 Bloom 是教学版：在单个 pass 中做亮度阈值提取和邻域扩散，便于观察 `Threshold`、`Soft Knee`、`Radius`、`Intensity` 的作用。生产级 Bloom 通常会使用多级 mip pyramid、降采样和多次上采样，本章暂不实现。

### Motion Blur

本章运动模糊是教学版方向采样模糊，通过 `Motion Blur Direction` 沿屏幕方向多次采样。它用于理解“沿运动方向累积颜色”的概念，不是基于 `_CameraMotionVectorsTexture` 的完整速度缓冲运动模糊。

## 和教程原始写法的差异

- 教程中的 Built-in 示例使用 `OnRenderImage`，本章改为 URP Renderer Feature。
- 本章使用 RenderGraph 版本的 `ScriptableRenderPass.RecordRenderGraph`，适配当前 URP 17。
- Shader 通过 `Blit.hlsl` 的 `_BlitTexture` 读取当前相机颜色，而不是声明 `_MainTex`。
- Bloom 和 Motion Blur 保持教学优先，不做完整生产级后处理管线。

## 调试建议

- 打开 Unity Console，先确认没有 C# 或 Shader 编译错误。
- 用 Frame Debugger 查找 `Chapter05 Grayscale`、`Chapter05 CRT`、`Chapter05 Sobel Edge` 等 pass 名称。
- 每次只开启一个效果，确认参数变化后再组合多个效果。
- 如果全屏效果不显示，确认 Volume 参数的 override 已勾选，且强度参数大于 0。

视觉正确性需要在 Unity Editor 中运行场景后观察，本文件级检查不能替代实际画面验证。
