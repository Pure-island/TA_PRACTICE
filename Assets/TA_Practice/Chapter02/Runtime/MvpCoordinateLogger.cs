using UnityEngine;

namespace TA_Practice.Chapter02
{
    public sealed class MvpCoordinateLogger : MonoBehaviour
    {
        [SerializeField] private Camera targetCamera;
        [SerializeField] private Transform targetObject;
        [SerializeField] private Vector3 objectSpacePoint = Vector3.zero;
        [SerializeField] private bool logEveryFrame;
        [SerializeField] private bool logOnce;

        private void Reset()
        {
            targetCamera = Camera.main;
            targetObject = transform;
        }

        private void Update()
        {
            if (logEveryFrame || logOnce)
            {
                LogCoordinateChain();
                logOnce = false;
            }
        }

        private void LogCoordinateChain()
        {
            if (targetObject == null)
            {
                Debug.Log("MvpCoordinateLogger needs Target Object assigned.", this);
                return;
            }

            if (targetCamera == null)
            {
                Debug.Log("MvpCoordinateLogger needs Target Camera assigned.", this);
                return;
            }

            Matrix4x4 model = targetObject.localToWorldMatrix;
            Matrix4x4 view = targetCamera.worldToCameraMatrix;
            Matrix4x4 projection = targetCamera.projectionMatrix;

            Vector4 objectPoint = HomogeneousMathUtility.ToPoint(objectSpacePoint);
            Vector4 worldPoint = model * objectPoint;
            Vector4 viewPoint = view * worldPoint;
            Vector4 clipPoint = projection * viewPoint;
            Vector3 ndcPoint = HomogeneousMathUtility.PerspectiveDivide(clipPoint);

            // 这里在 CPU 侧复现 Shader 顶点变换路径：对象空间 -> 世界空间 -> 观察空间 -> 裁剪空间 -> NDC。
            Debug.Log(
                $"Object: {objectPoint} | World: {worldPoint} | View: {viewPoint} | Clip: {clipPoint} | NDC: {ndcPoint}",
                this);

            Vector4 pointAsPosition = HomogeneousMathUtility.ToPoint(Vector3.right);
            Vector4 pointAsDirection = HomogeneousMathUtility.ToDirection(Vector3.right);
            Vector4 movedPoint = Matrix4x4.Translate(Vector3.up) * pointAsPosition;
            Vector4 movedDirection = Matrix4x4.Translate(Vector3.up) * pointAsDirection;

            // w = 1 会受到平移影响，w = 0 会忽略平移；这就是“点”和“方向”的核心区别。
            Debug.Log($"w=1 translated point: {movedPoint}, w=0 translated direction: {movedDirection}", this);
        }
    }
}
