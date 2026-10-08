using UnityEngine;

namespace TA_Practice.Chapter04
{
    public sealed class MaterialFloatAnimator : MonoBehaviour
    {
        [SerializeField] private Renderer targetRenderer;
        [SerializeField] private string propertyName = "_WaveStrength";
        [SerializeField] private float minValue = 0.1f;
        [SerializeField] private float maxValue = 0.8f;
        [SerializeField] private float speed = 1f;
        [SerializeField] private bool useSineWave = true;
        [SerializeField] private float manualValue = 0.5f;

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

            // 使用 MaterialPropertyBlock 只影响当前 Renderer，不会修改 Project 里的共享材质。
            targetRenderer.GetPropertyBlock(propertyBlock);
            propertyBlock.SetFloat(propertyName, value);
            targetRenderer.SetPropertyBlock(propertyBlock);
        }
    }
}
