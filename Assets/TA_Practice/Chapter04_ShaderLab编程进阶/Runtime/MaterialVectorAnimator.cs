using UnityEngine;

namespace TA_Practice.Chapter04
{
    public sealed class MaterialVectorAnimator : MonoBehaviour
    {
        [SerializeField] private Renderer targetRenderer;
        [SerializeField] private string propertyName = "_FlowDirection";
        [SerializeField] private Vector4 baseValue = new Vector4(1f, 0f, 0f, 0f);
        [SerializeField] private Vector4 animatedAxis = new Vector4(0f, 1f, 0f, 0f);
        [SerializeField] private float amplitude = 1f;
        [SerializeField] private float speed = 1f;

        private MaterialPropertyBlock propertyBlock;

        private void Reset()
        {
            targetRenderer = GetComponent<Renderer>();
        }

        private void Awake()
        {
            propertyBlock = new MaterialPropertyBlock();
        }

        private void Update()
        {
            if (targetRenderer == null || string.IsNullOrWhiteSpace(propertyName))
            {
                return;
            }

            Vector4 value = baseValue + animatedAxis * (Mathf.Sin(Time.time * speed) * amplitude);

            // 向量参数常用于流向、颜色、裁剪平面、世界坐标控制点等 Shader 数据。
            targetRenderer.GetPropertyBlock(propertyBlock);
            propertyBlock.SetVector(propertyName, value);
            targetRenderer.SetPropertyBlock(propertyBlock);
        }
    }
}
