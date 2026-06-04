using UnityEngine;

namespace TA_Practice.Chapter02
{
    public static class QuaternionMathUtility
    {
        public static Quaternion GetFlatLookRotation(Vector3 origin, Vector3 target)
        {
            Vector3 direction = target - origin;
            direction.y = 0f;

            // Quaternion.LookRotation 需要非零方向；没有方向时返回 identity，表示“不旋转”。
            if (direction.sqrMagnitude <= 0.0001f)
            {
                return Quaternion.identity;
            }

            return Quaternion.LookRotation(direction.normalized, Vector3.up);
        }

        public static Quaternion RotateTowards(Quaternion current, Quaternion target, float degreesPerSecond, float deltaTime)
        {
            // RotateTowards 按固定角速度靠近目标旋转，比直接赋值更适合观察“逐步转向”。
            return Quaternion.RotateTowards(current, target, degreesPerSecond * deltaTime);
        }

        public static Quaternion SlerpBySpeed(Quaternion current, Quaternion target, float interpolationSpeed, float deltaTime)
        {
            // Slerp 沿旋转球面插值，适合演示四元数如何避免欧拉角万向节锁的问题。
            float t = Mathf.Clamp01(interpolationSpeed * deltaTime);
            return Quaternion.Slerp(current, target, t);
        }
    }
}
