# Chapter03 ShaderLab编程入门代码说明

本章教材包含 Surface Shader、Surface Function、Vertex Function、顶点/片元着色器和积雪案例。当前项目使用 URP，因此本章代码全部改写为 URP ShaderLab/HLSL，不使用 Built-in 管线的 `#pragma surface`、`UnityCG.cginc` 或 Surface Shader 输出结构。

## 文件结构

- `Shaders/Chapter03_UnlitColor.shader`：最基础的 URP ShaderLab 结构。
- `Shaders/Chapter03_TextureTint.shader`：纹理采样、UV 平铺偏移和颜色叠加。
- `Shaders/Chapter03_VertexWave.shader`：顶点函数中修改对象空间顶点，制作波浪形变。
- `Shaders/Chapter03_LambertDiffuse.shader`：用顶点/片元着色器实现简易 Lambert 漫反射。
- `Shaders/Chapter03_SnowCoverage.shader`：用世界空间法线和高度混合基础材质与雪色。
- `Textures/RockSoil_Base_Tile.png`：生成的岩土基础色贴图，可给 `_BaseMap` 使用。
- `Textures/Snow_Albedo_Tile.png`：生成的雪面基础色贴图，可给 `_SnowMap` 使用。
- `Textures/Snow_Noise_Mask_Tile.png`：生成的黑白噪声遮罩，可给 `_SnowNoiseMap` 使用。
- `Runtime/MaterialFloatAnimator.cs`：运行时驱动材质浮点参数，例如 `_SnowAmount` 或 `_WaveAmplitude`。

## Shader 使用方式

### 01_UnlitColor

演示重点：
- `Shader`、`Properties`、`SubShader`、`Pass` 的基本层级。
- URP Shader 必须通过 `Tags` 标明 `RenderPipeline = UniversalPipeline`。
- 顶点函数通过 `TransformObjectToHClip` 把对象空间坐标变换到裁剪空间。

使用方式：
- 创建一个 Material。
- Shader 选择 `TA_Practice/Chapter03/01_UnlitColor`。
- 调整 `Base Color`，把材质赋给任意 Mesh Renderer。

### 02_TextureTint

演示重点：
- `TEXTURE2D`、`SAMPLER` 和 `SAMPLE_TEXTURE2D` 的 URP 贴图采样写法。
- `_BaseMap_ST` 对应材质面板中的 Tiling 和 Offset。
- 纹理颜色乘 `_BaseColor` 得到 Tint 效果。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter03/02_TextureTint`。
- 给 `Base Map` 指定任意纹理。
- 调整材质面板中的 Tiling、Offset 和 Tint Color。

### 03_VertexWave

演示重点：
- Vertex Shader 适合做顶点级别的变形。
- 在对象空间修改顶点位置，再送入对象到裁剪空间变换。
- 顶点阶段计算的数据可以通过 `Varyings` 传给片元阶段。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter03/03_VertexWave`。
- 赋给细分较多的 Plane 或 Grid 网格，低面数 Cube 不容易看出波浪。
- 调整 `Wave Amplitude`、`Wave Frequency`、`Wave Speed`。

### 04_LambertDiffuse

演示重点：
- 用 `Lighting.hlsl` 获取 URP 主光源。
- 法线需要转换到世界空间后，再和光照方向做点乘。
- Lambert 漫反射核心是 `saturate(dot(N, L))`。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter03/04_LambertDiffuse`。
- 场景中保留一个 Directional Light。
- 旋转物体或灯光，观察明暗变化。

### 05_SnowCoverage

演示重点：
- 用世界空间法线判断表面是否朝上。
- 用世界空间高度参与积雪混合。
- 用噪声贴图打散积雪边缘，避免纯色块状过渡。
- 用 `lerp` 在基础纹理和雪纹理之间平滑过渡。
- 这是教材 Surface Shader 积雪案例的 URP 顶点/片元改写版。

使用方式：
- 创建 Material，Shader 选择 `TA_Practice/Chapter03/05_SnowCoverage`。
- `Base Map` 指定 `Textures/RockSoil_Base_Tile.png`。
- `Snow Map` 指定 `Textures/Snow_Albedo_Tile.png`。
- `Snow Noise Mask` 指定 `Textures/Snow_Noise_Mask_Tile.png`。
- 赋给有明显斜面或曲面的模型，例如 Sphere、Terrain-like Mesh、斜放的 Cube。
- 建议先把三张贴图的导入设置 `Wrap Mode` 改为 `Repeat`，这样 Tiling 放大时不会出现边缘断裂。
- 推荐初始参数：`Snow Amount = 1`，`Snow Normal Threshold = 0.35`，`Snow Edge Softness = 0.35`，`Snow Height Start = -1`，`Snow Height Blend = 2`，`Snow Noise Scale = 0.35`，`Snow Noise Strength = 0.45`，`Snow Tiling = 1.5`。
- 如果看不到雪，先把 `Debug View` 改为 `SnowFactor`。白色表示积雪多，黑色表示积雪少。

`Debug View` 用法：
- `Final`：正常最终效果。
- `SnowFactor`：显示最终积雪遮罩。
- `NormalUp`：显示世界空间法线朝上的程度。
- `Height`：显示高度因子。
- `Noise`：显示噪声贴图对积雪边缘的影响。

## MaterialFloatAnimator 使用方式

`MaterialFloatAnimator` 用来给某个 Renderer 动态设置一个 float 材质参数。

常见用法：
- 给使用 `05_SnowCoverage` 的物体挂脚本。
- `Property Name` 填 `_SnowAmount`。
- 勾选 `Use Sine Wave`，运行后积雪强度会在 `Min Value` 和 `Max Value` 之间来回变化。

也可以：
- 给使用 `03_VertexWave` 的物体挂脚本。
- `Property Name` 填 `_WaveAmplitude`。
- 用它观察顶点波浪幅度变化。

脚本使用 `MaterialPropertyBlock`，只覆盖当前 Renderer 的参数，不会直接修改 Project 里的共享材质资源。

## 和教材 Surface Shader 的对应关系

- 教材的 `Properties` 仍然保留，对应 URP Shader 的材质面板参数。
- 教材的 `surf` 表面函数在这里拆成了 `Frag` 片元函数中的颜色、法线、光照和混合计算。
- 教材的 `vert` 顶点函数对应这里的 `Vert` 函数，例如 `Chapter03_VertexWave.shader`。
- 教材的积雪案例仍保留“法线朝上”和“高度参与混合”的核心思想，只是改为 URP 手写 vertex/fragment 管线。
