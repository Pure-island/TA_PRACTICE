using UnityEngine;

namespace TA_Practice.Chapter02
{
    public sealed class DotCrossVisualizer : MonoBehaviour
    {
        [SerializeField] private Vector3 vectorA = Vector3.forward;
        [SerializeField] private Vector3 vectorB = Vector3.right;
        [SerializeField] private Transform triangleA;
        [SerializeField] private Transform triangleB;
        [SerializeField] private Transform triangleC;
        [SerializeField] private Vector3 incidentDirection = new Vector3(1f, -1f, 0f);
        [SerializeField] private Vector3 surfaceNormal = Vector3.up;
        [SerializeField] private bool logValues;

        private void Update()
        {
            DrawDotAndCross();
            DrawTriangleNormal();
            DrawReflection();

            if (logValues)
            {
                LogValues();
                logValues = false;
            }
        }

        private void DrawDotAndCross()
        {
            Vector3 a = VectorMathUtility.SafeNormalize(vectorA);
            Vector3 b = VectorMathUtility.SafeNormalize(vectorB);
            Vector3 cross = Vector3.Cross(a, b);

            // 红色和绿色是两个输入方向；点乘用于判断它们的夹角关系。
            Debug.DrawRay(transform.position, a, Color.red);
            Debug.DrawRay(transform.position, b, Color.green);

            // 蓝色是 cross(A, B)，方向垂直于 A 和 B 组成的平面。
            Debug.DrawRay(transform.position, cross, Color.blue);
        }

        private void DrawTriangleNormal()
        {
            if (triangleA == null || triangleB == null || triangleC == null)
            {
                return;
            }

            Vector3 normal = VectorMathUtility.GetTriangleNormal(triangleA.position, triangleB.position, triangleC.position);
            Vector3 center = (triangleA.position + triangleB.position + triangleC.position) / 3f;

            // 三角形法线是叉乘的典型用途：用边 AB 叉乘边 AC 得到面法线。
            Debug.DrawLine(triangleA.position, triangleB.position, Color.white);
            Debug.DrawLine(triangleB.position, triangleC.position, Color.white);
            Debug.DrawLine(triangleC.position, triangleA.position, Color.white);
            Debug.DrawRay(center, normal, Color.magenta);
        }

        private void DrawReflection()
        {
            Vector3 normal = VectorMathUtility.SafeNormalize(surfaceNormal);
            Vector3 reflected = VectorMathUtility.Reflect(incidentDirection, normal);

            // 黄色是表面法线，灰色是入射方向，青色是根据反射公式得到的反射方向。
            Debug.DrawRay(transform.position, normal, Color.yellow);
            Debug.DrawRay(transform.position, incidentDirection, Color.gray);
            Debug.DrawRay(transform.position, reflected, Color.cyan);
        }

        private void LogValues()
        {
            float dot = VectorMathUtility.GetNormalizedDot(vectorA, vectorB);
            DotRelationship relationship = VectorMathUtility.ClassifyDot(vectorA, vectorB);
            Vector3 cross = Vector3.Cross(VectorMathUtility.SafeNormalize(vectorA), VectorMathUtility.SafeNormalize(vectorB));

            Debug.Log($"Dot: {dot:F3}, Relationship: {relationship}, Cross: {cross}", this);
        }
    }
}
