# Chapter04 ShaderLab编程进阶代码说明

本章对应课程第 04 章：传统光照模型、PBR、玻璃反射折射和水面着色器。项目使用 URP，因此这里全部改写为 URP ShaderLab/HLSL，不使用 Built-in 管线的 `GrabPass`、`UnityCG.cginc` 或 `#pragma surface`。

## 文件结构

- `Shaders/Chapter04_LambertPhongBlinn.shader`：传统 Lambert、Phong、Blinn-Phong 光照模型对比。
- `Shaders/Chapter04_SimplePBR_GGX.shader`：简化 GGX PBR BRDF，用于理解 NDF、Geometry、Fresnel。
- `Shaders/Chapter04_GlassRefractionStep.shader`：URP 中用 `_CameraOpaqueTexture` 近似教程的 GrabPass 折射第一步。
- `Shaders/Chapter04_GlassFresnelFinal.shader`：玻璃最终效果，加入 Fresnel、色散、环境反射近似和划痕扰动。
- `Shaders/Chapter04_WaterSurfaceAdvanced.shader`：水面效果，包含动态法线、屏幕折射、Fresnel、深浅水颜色、泡沫和焦散。
- `Runtime/MaterialFloatAnimator.cs`：运行时驱动 float 材质参数，例如 `_WaveStrength`。
- `Runtime/MaterialVectorAnimator.cs`：运行时驱动 Vector 材质参数，用于理解 Shader 向量输入。
- `Runtime/MaterialKeywordToggle.cs`：演示材质 keyword 开关和 shader 变体概念。

## 生成贴图

- `Textures/Water_Normal_Tile.png`：水面切线空间法线贴图参考，给 `_WaterNormalMap` 使用。
- `Textures/Foam_Mask_Tile.png`：泡沫黑白遮罩，给 `_FoamMap` 使用。
- `Textures/Caustics_Tile.png`：焦散黑白纹理，给 `_CausticsMap` 使用。
- `Textures/Glass_Scratch_Distortion_Tile.png`：玻璃划痕/扰动贴图，给 `_DistortionMap` 使用。

导入注意：
- 所有 tileable 贴图建议在 Unity Editor 中设置 `Wrap Mode = Repeat`。
- `Water_Normal_Tile.png` 建议设置 `Texture Type = Normal Map`。
- 泡沫、焦散、划痕这类遮罩贴图可关闭 sRGB，用作线性数据观察更直观。

## URP 设置要求

玻璃和水面使用 `_CameraOpaqueTexture` 来模拟教程中的 GrabPass，需要你在 Unity Editor 中启用：
- URP Asset 或 Renderer 中的 `Opaque Texture`。

水面深度泡沫和深浅水颜色使用 `_CameraDepthTexture`，需要你启用：
- URP Asset 或 Renderer 中的 `Depth Texture`。

如果没有启用这些设置，Shader 仍可作为代码阅读，但折射、深度泡沫、深浅水效果可能不明显或不正确。

## Shader 使用方式

### 01_LambertPhongBlinn

演示重点：
- Lambert：只计算漫反射 `NdotL`。
- Phong：用反射向量 `R` 和视线方向 `V` 计算高光。
- Blinn-Phong：用半角向量 `H` 替代反射向量，常见且稳定。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter04/01_LambertPhongBlinn`。
- 给 Sphere 或复杂模型使用。
- 切换 `Lighting Model`，观察高光位置和范围。
- 调整 `Shininess`，数值越大，高光越小越锐利。

### 02_SimplePBR_GGX

演示重点：
- `DistributionGGX`：微表面法线分布。
- `GeometrySmith`：微表面遮蔽和阴影。
- `FresnelSchlick`：菲涅尔反射近似。
- `Metallic` 控制 F0 从非金属 0.04 过渡到基础色。
- `Roughness` 控制高光宽窄。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter04/02_SimplePBR_GGX`。
- 用 Directional Light 观察不同 `Metallic` 和 `Roughness` 下的高光变化。
- 勾选 `Debug BRDF Terms`，RGB 会显示 D/G/F 三个 BRDF 中间项。

### 03_GlassRefractionStep

演示重点：
- URP 下用 `_CameraOpaqueTexture` 替代 Built-in 的 `GrabPass` 思路。
- 用划痕/扰动贴图偏移屏幕 UV，形成折射扭曲。
- 这是玻璃反射折射的第一步，不包含完整 Fresnel 和反射混合。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter04/03_GlassRefractionStep`。
- `Distortion Mask` 指定 `Textures/Glass_Scratch_Distortion_Tile.png`。
- 把材质赋给透明物体，例如 Plane 或 Cube。
- 场景中玻璃后方要有不透明物体，折射才容易观察。

### 04_GlassFresnelFinal

演示重点：
- Fresnel：视角越掠射，反射越强。
- 色散：RGB 三个通道使用略微不同的屏幕偏移。
- 划痕扰动：模拟玻璃表面细节。
- 环境反射近似：用球谐环境光作为低成本反射参考。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter04/04_GlassFresnelFinal`。
- `Distortion Mask` 指定 `Textures/Glass_Scratch_Distortion_Tile.png`。
- 调整 `Refraction Strength`、`Chromatic Aberration`、`Fresnel Power`、`Reflection Strength`。

### 05_WaterSurfaceAdvanced

演示重点：
- 双层滚动法线模拟水面动态波纹。
- `_CameraOpaqueTexture` 提供屏幕折射。
- `_CameraDepthTexture` 提供深浅水颜色和岸边泡沫依据。
- Fresnel 混合折射和环境反射。
- 焦散贴图作为水下光斑的近似表现。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter04/05_WaterSurfaceAdvanced`。
- `Water Normal Map` 指定 `Textures/Water_Normal_Tile.png`。
- `Foam Mask` 指定 `Textures/Foam_Mask_Tile.png`。
- `Caustics Map` 指定 `Textures/Caustics_Tile.png`。
- 把材质赋给平面网格。网格细分越多，顶点位移越明显。
- 调整 `Wave Speed`、`Wave Strength`、`Refraction Strength`、`Foam Depth`、`Depth Fade Distance`。

## Runtime 脚本使用方式

### MaterialFloatAnimator

用于动态改变一个 float 材质参数。

示例：
- 挂到使用水面材质的物体。
- `Property Name` 填 `_WaveStrength`。
- 调整 `Min Value`、`Max Value`、`Speed`，观察波浪强度变化。

### MaterialVectorAnimator

用于动态改变一个 Vector 材质参数。

本章 Shader 暂时不强依赖它，但它保留给后续学习流向、裁剪平面、世界坐标控制点等向量参数。

### MaterialKeywordToggle

用于演示材质 keyword 开关。

注意：keyword 会影响 Shader 变体，后续第 11 章 Shader 变体与优化会更系统地学习。本章只作为概念预留脚本。

## 和教程原始写法的差异

- 教程中玻璃和水面使用 Built-in `GrabPass`，URP 中改用 `_CameraOpaqueTexture`。
- 教程中很多示例是 Surface Shader，本章改为手写 vertex/fragment，便于适配 URP。
- 本章水面是学习版，不是生产级水体系统；平面反射、SSR、复杂多光源和真实 IBL 暂不实现。
- 如果视觉结果不符合预期，优先检查 URP 的 `Opaque Texture`、`Depth Texture` 是否开启，以及贴图是否设置了 `Wrap Mode = Repeat`。
