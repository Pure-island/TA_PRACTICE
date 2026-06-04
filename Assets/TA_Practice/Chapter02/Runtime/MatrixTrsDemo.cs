using UnityEngine;

namespace TA_Practice.Chapter02
{
    public sealed class MatrixTrsDemo : MonoBehaviour
    {
        [SerializeField] private Transform correctOrderTarget;
        [SerializeField] private Transform wrongOrderTarget;
        [SerializeField] private Vector3 localPoint = Vector3.right;
        [SerializeField] private Vector3 translation = new Vector3(3f, 0f, 0f);
        [SerializeField] private Vector3 eulerRotation = new Vector3(0f, 45f, 0f);
        [SerializeField] private Vector3 scale = new Vector3(2f, 1f, 1f);
        [SerializeField] private bool logValues;

        private void Update()
        {
            Quaternion rotation = Quaternion.Euler(eulerRotation);
            Matrix4x4 correct = MatrixMathUtility.ComposeTrs(translation, rotation, scale);
            Matrix4x4 wrong = MatrixMathUtility.ComposeWrongOrder(translation, rotation, scale);

            Vector3 correctPoint = transform.position + MatrixMathUtility.MultiplyPoint(correct, localPoint);
            Vector3 wrongPoint = transform.position + MatrixMathUtility.MultiplyPoint(wrong, localPoint);

            if (correctOrderTarget != null)
            {
                correctOrderTarget.position = correctPoint;
            }

            if (wrongOrderTarget != null)
            {
                wrongOrderTarget.position = wrongPoint;
            }

            // 绿色表示正确的 T * R * S 顺序；红色表示故意写错的顺序，用来观察结果差异。
            Debug.DrawLine(transform.position, correctPoint, Color.green);
            Debug.DrawLine(transform.position, wrongPoint, Color.red);

            DrawLocalAxes(correct);

            if (logValues)
            {
                LogValues(correct, wrong);
                logValues = false;
            }
        }

        private void DrawLocalAxes(Matrix4x4 matrix)
        {
            Vector3 origin = transform.position + MatrixMathUtility.MultiplyPoint(matrix, Vector3.zero);

            // 矩阵变换后的基向量可以理解为物体局部坐标轴在世界中的方向和长度。
            Debug.DrawRay(origin, MatrixMathUtility.MultiplyDirection(matrix, Vector3.right), Color.red);
            Debug.DrawRay(origin, MatrixMathUtility.MultiplyDirection(matrix, Vector3.up), Color.green);
            Debug.DrawRay(origin, MatrixMathUtility.MultiplyDirection(matrix, Vector3.forward), Color.blue);
        }

        private void LogValues(Matrix4x4 correct, Matrix4x4 wrong)
        {
            Vector3 correctPoint = MatrixMathUtility.MultiplyPoint(correct, localPoint);
            Vector3 wrongPoint = MatrixMathUtility.MultiplyPoint(wrong, localPoint);
            float restoreError = MatrixMathUtility.GetRestoreError(correct, localPoint);

            Debug.Log($"Correct TRS point: {correctPoint}, Wrong-order point: {wrongPoint}, Inverse restore error: {restoreError:F6}", this);
        }
    }
}
