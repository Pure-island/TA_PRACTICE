using UnityEngine;

namespace TA_Practice.Chapter02
{
    public static class HomogeneousMathUtility
    {
        public static Vector4 ToPoint(Vector3 position)
        {
            // w = 1 表示“点”，所以平移矩阵可以移动它。
            return new Vector4(position.x, position.y, position.z, 1f);
        }

        public static Vector4 ToDirection(Vector3 direction)
        {
            // w = 0 表示“方向”，所以平移矩阵不应该改变它。
            return new Vector4(direction.x, direction.y, direction.z, 0f);
        }

        public static Vector3 PerspectiveDivide(Vector4 clipPosition)
        {
            // 裁剪空间通过 xyz / w 进入 NDC（规范化设备坐标）。
            // 透视投影中，远处物体看起来更小，本质上就和这个 w 分量参与除法有关。
            if (Mathf.Approximately(clipPosition.w, 0f))
            {
                return Vector3.zero;
            }

            return new Vector3(
                clipPosition.x / clipPosition.w,
                clipPosition.y / clipPosition.w,
                clipPosition.z / clipPosition.w);
        }

        public static Vector4 TransformObjectToClip(Matrix4x4 model, Matrix4x4 view, Matrix4x4 projection, Vector3 objectPoint)
        {
            // MVP 顺序是 projection * view * model，因为对象空间点在最右侧，最先被 model 矩阵处理。
            return projection * view * model * ToPoint(objectPoint);
        }
    }
}
