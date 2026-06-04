using UnityEngine;

namespace TA_Practice.Chapter02
{
    public sealed class VectorBasicsVisualizer : MonoBehaviour
    {
        [SerializeField] private Transform startPoint;
        [SerializeField] private Transform endPoint;
        [SerializeField] private Transform mover;
        [SerializeField] private Vector2 input = new Vector2(1f, 1f);
        [SerializeField] private float moveSpeed = 2f;
        [SerializeField] private bool normalizeInput = true;
        [SerializeField] private bool logValues;

        private void Update()
        {
            DrawPointVectorDemo();
            MoveDemoObject();

            if (logValues)
            {
                LogVectorValues();
                logValues = false;
            }
        }

        private void DrawPointVectorDemo()
        {
            if (startPoint == null || endPoint == null)
            {
                return;
            }

            Vector3 displacement = VectorMathUtility.GetDisplacement(startPoint.position, endPoint.position);
            Vector3 direction = VectorMathUtility.SafeNormalize(displacement);

            // 蓝色射线：从 A 到 B 的完整位移，长度就是两个点之间的距离。
            Debug.DrawRay(startPoint.position, displacement, Color.blue);

            // 青色射线：同方向的单位向量，用来区分“方向”和“距离”。
            Debug.DrawRay(startPoint.position, direction, Color.cyan);
        }

        private void MoveDemoObject()
        {
            if (mover == null)
            {
                return;
            }

            Vector3 movement = new Vector3(input.x, 0f, input.y);
            Vector3 direction = normalizeInput ? VectorMathUtility.SafeNormalize(movement) : movement;

            // 输入归一化后，斜向移动速度才不会比横向/纵向移动更快。
            mover.position += direction * moveSpeed * Time.deltaTime;
            Debug.DrawRay(mover.position, direction, normalizeInput ? Color.green : Color.red);
        }

        private void LogVectorValues()
        {
            if (startPoint == null || endPoint == null)
            {
                Debug.Log("VectorBasicsVisualizer needs Start Point and End Point assigned.", this);
                return;
            }

            Vector3 displacement = VectorMathUtility.GetDisplacement(startPoint.position, endPoint.position);
            Vector3 direction = VectorMathUtility.SafeNormalize(displacement);

            Debug.Log(
                $"Displacement: {displacement}, Magnitude: {VectorMathUtility.GetMagnitude(displacement):F3}, Normalized: {direction}",
                this);
        }

        private void OnDrawGizmos()
        {
            if (startPoint == null || endPoint == null)
            {
                return;
            }

            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(startPoint.position, 0.15f);
            Gizmos.DrawWireSphere(endPoint.position, 0.15f);
        }
    }
}
