using UnityEngine;

namespace TA_Practice.Chapter02
{
    public static class MatrixMathUtility
    {
        public static Matrix4x4 ComposeTrs(Vector3 translation, Quaternion rotation, Vector3 scale)
        {
            // Unity 使用列向量思路理解时，最右侧矩阵最先作用：先 S 缩放，再 R 旋转，最后 T 平移。
            Matrix4x4 t = Matrix4x4.Translate(translation);
            Matrix4x4 r = Matrix4x4.Rotate(rotation);
            Matrix4x4 s = Matrix4x4.Scale(scale);
            return t * r * s;
        }

        public static Matrix4x4 ComposeWrongOrder(Vector3 translation, Quaternion rotation, Vector3 scale)
        {
            // 这里故意使用错误顺序，方便观察矩阵乘法“不满足交换律”带来的结果差异。
            Matrix4x4 t = Matrix4x4.Translate(translation);
            Matrix4x4 r = Matrix4x4.Rotate(rotation);
            Matrix4x4 s = Matrix4x4.Scale(scale);
            return s * r * t;
        }

        public static Vector3 MultiplyPoint(Matrix4x4 matrix, Vector3 point)
        {
            // 点的齐次坐标 w = 1，因此会受到平移矩阵影响。
            return matrix.MultiplyPoint3x4(point);
        }

        public static Vector3 MultiplyDirection(Matrix4x4 matrix, Vector3 direction)
        {
            // 方向的齐次坐标 w = 0，因此会忽略平移，只保留旋转/缩放等方向变化。
            return matrix.MultiplyVector(direction);
        }

        public static Vector3 RestoreLocalPoint(Matrix4x4 localToWorld, Vector3 worldPoint)
        {
            return localToWorld.inverse.MultiplyPoint3x4(worldPoint);
        }

        public static float GetRestoreError(Matrix4x4 localToWorld, Vector3 localPoint)
        {
            Vector3 worldPoint = MultiplyPoint(localToWorld, localPoint);
            Vector3 restoredLocal = RestoreLocalPoint(localToWorld, worldPoint);
            return Vector3.Distance(localPoint, restoredLocal);
        }
    }
}
