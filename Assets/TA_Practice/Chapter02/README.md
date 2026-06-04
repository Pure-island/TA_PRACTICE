# Chapter02 向量、矩阵与四元数代码说明

本章代码放在 `Assets/TA_Practice/Chapter02/Runtime/`，用于配合第 02 章的数学基础练习。代码只提供可挂载脚本和数学辅助函数，Scene、物体摆放、材质和资源导入由你在 Unity Editor 中完成。

## 数学辅助类

- `VectorMathUtility.cs`：封装位移、模长、归一化、点乘分类、投影、叉乘法线、反射方向等向量计算。
- `MatrixMathUtility.cs`：封装 TRS 矩阵组合、错误矩阵顺序对比、点/方向乘矩阵、逆矩阵还原局部坐标。
- `HomogeneousMathUtility.cs`：封装齐次坐标中 `w=1` 的点、`w=0` 的方向、透视除法和 MVP 变换。
- `QuaternionMathUtility.cs`：封装平面朝向、按角速度转向、Slerp 插值等四元数操作。

## 可挂载脚本

### VectorBasicsVisualizer

演示内容：
- 两点相减得到位移向量。
- 位移向量的模长表示距离。
- 归一化向量只保留方向，长度变为 1。
- 输入向量归一化后，斜向移动不会比横向/纵向移动更快。

使用方式：
- 新建一个 Empty GameObject，挂 `VectorBasicsVisualizer`。
- 创建两个 Transform 作为 `Start Point` 和 `End Point`。
- 可选创建一个物体作为 `Mover`，调 `Input`、`Move Speed`、`Normalize Input` 观察移动差异。
- 打开 Scene 视图的 `Gizmos` 查看蓝色/青色射线。

### DotCrossVisualizer

演示内容：
- 点乘判断两个方向的夹角关系。
- 叉乘得到垂直于两个向量平面的方向。
- 三角形边向量叉乘得到面法线。
- 通过入射方向和法线计算反射方向。

使用方式：
- 新建一个 Empty GameObject，挂 `DotCrossVisualizer`。
- 调 `Vector A` 和 `Vector B` 观察红、绿、蓝三条射线。
- 可选创建三个点作为三角形顶点，赋给 `Triangle A/B/C`。
- 勾选 `Log Values` 在 Console 输出 dot、关系分类和 cross。

### MatrixTrsDemo

演示内容：
- 正确 TRS 顺序：先缩放、再旋转、最后平移。
- 错误矩阵顺序会得到不同结果。
- 点乘矩阵会受到平移影响，方向乘矩阵会忽略平移。
- 逆矩阵可以把世界坐标还原回局部坐标。

使用方式：
- 新建一个 Empty GameObject，挂 `MatrixTrsDemo`。
- 创建两个小物体，分别赋给 `Correct Order Target` 和 `Wrong Order Target`。
- 调 `Translation`、`Euler Rotation`、`Scale` 和 `Local Point`。
- 绿色线表示正确顺序结果，红色线表示错误顺序结果。

### MvpCoordinateLogger

演示内容：
- 对象空间到世界空间、观察空间、裁剪空间、NDC 的完整 MVP 链路。
- 齐次坐标中 `w=1` 表示点，受平移影响。
- 齐次坐标中 `w=0` 表示方向，不受平移影响。

使用方式：
- 挂到任意 GameObject 上。
- 设置 `Target Camera` 和 `Target Object`。
- 勾选 `Log Once` 输出一次坐标转换链路。
- 如果想持续观察数值变化，可勾选 `Log Every Frame`。

### QuaternionLookDemo

演示内容：
- 用 `Quaternion.LookRotation` 计算目标朝向。
- 用 `Quaternion.RotateTowards` 按固定角速度转向。
- 用 `Quaternion.Slerp` 做球面插值，观察平滑旋转。
- 勾选 `Keep Rotation Flat` 时，只在 XZ 平面内转向，适合角色水平朝向练习。

使用方式：
- 把 `QuaternionLookDemo` 挂到需要转向的物体上。
- 创建一个目标物体，赋给 `Target`。
- 调 `Degrees Per Second` 或勾选 `Use Slerp` 后调 `Slerp Speed`。
- Scene 视图中蓝色射线表示当前 forward，黄色线表示目标方向。
