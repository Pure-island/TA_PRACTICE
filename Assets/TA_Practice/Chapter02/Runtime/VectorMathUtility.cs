using UnityEngine;

namespace TA_Practice.Chapter02
{
    public enum DotRelationship
    {
        OppositeDirection,
        Obtuse,
        Perpendicular,
        Acute,
        SameDirection
    }

    public static class VectorMathUtility
    {
        private const float Epsilon = 0.0001f;

        public static Vector3 GetDisplacement(Vector3 start, Vector3 end)
        {
            // 位置表示空间中的点。两个位置相减，会得到从 start 指向 end 的位移向量。
            return end - start;
        }

        public static float GetMagnitude(Vector3 vector)
        {
            // 模长表示“箭头”的长度，只描述大小，不描述方向。
            return vector.magnitude;
        }

        public static Vector3 SafeNormalize(Vector3 vector)
        {
            // 归一化会把向量长度变成 1，只保留方向信息。
            // 零向量没有方向，因此这里返回零向量，而不是凭空制造一个方向。
            return vector.sqrMagnitude > Epsilon * Epsilon ? vector.normalized : Vector3.zero;
        }

        public static float GetNormalizedDot(Vector3 a, Vector3 b)
        {
            // 点乘本身同时受夹角和长度影响；先归一化后，结果就等于 cos(theta)。
            return Vector3.Dot(SafeNormalize(a), SafeNormalize(b));
        }

        public static DotRelationship ClassifyDot(Vector3 a, Vector3 b)
        {
            float dot = GetNormalizedDot(a, b);

            if (dot >= 1f - Epsilon)
            {
                return DotRelationship.SameDirection;
            }

            if (dot <= -1f + Epsilon)
            {
                return DotRelationship.OppositeDirection;
            }

            if (Mathf.Abs(dot) <= Epsilon)
            {
                return DotRelationship.Perpendicular;
            }

            return dot > 0f ? DotRelationship.Acute : DotRelationship.Obtuse;
        }

        public static Vector3 ProjectOntoDirection(Vector3 vector, Vector3 direction)
        {
            Vector3 unitDirection = SafeNormalize(direction);

            // 投影长度是 dot(vector, unitDirection)，再乘单位方向即可还原成投影向量。
            return unitDirection * Vector3.Dot(vector, unitDirection);
        }

        public static Vector3 GetTriangleNormal(Vector3 a, Vector3 b, Vector3 c)
        {
            // 用 Cross(edgeAB, edgeAC) 计算三角形法线；交换叉乘顺序会让法线反向。
            return SafeNormalize(Vector3.Cross(b - a, c - a));
        }

        public static Vector3 Reflect(Vector3 incidentDirection, Vector3 normal)
        {
            // 反射公式会减去两倍“入射方向在法线上的投影”，得到镜面反射方向。
            Vector3 unitNormal = SafeNormalize(normal);
            return incidentDirection - 2f * Vector3.Dot(incidentDirection, unitNormal) * unitNormal;
        }
    }
}
