using UnityEngine;

namespace TA_Practice.Chapter03
{
    public sealed class MaterialFloatAnimator : MonoBehaviour
    {
        [SerializeField] private Renderer targetRenderer;
        [SerializeField] private string propertyName = "_SnowAmount";
        [SerializeField] private float minValue;
        [SerializeField] private float maxValue = 1f;
        [SerializeField] private float speed = 1f;
        [SerializeField] private bool useSineWave = true;
        [SerializeField] private float manualValue = 0.5f;
        [SerializeField] private bool logValue;

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

            float value = useSineWave
                ? Mathf.Lerp(minValue, maxValue, Mathf.Sin(Time.time * speed) * 0.5f + 0.5f)
                : manualValue;

            ApplyFloat(value);

            if (logValue)
            {
                Debug.Log($"{propertyName} = {value:F3}", this);
                logValue = false;
            }
        }

        private void ApplyFloat(float value)
        {
            // MaterialPropertyBlock 会给当前 Renderer 覆盖材质参数，但不会修改共享材质资源。
            // 这适合学习时给多个物体做不同参数，也避免误改 Project 里的 Material asset。
            targetRenderer.GetPropertyBlock(propertyBlock);
            propertyBlock.SetFloat(propertyName, value);
            targetRenderer.SetPropertyBlock(propertyBlock);
        }
    }
}
