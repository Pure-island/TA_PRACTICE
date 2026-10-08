using UnityEngine;

namespace TA_Practice.Chapter04
{
    public sealed class MaterialKeywordToggle : MonoBehaviour
    {
        [SerializeField] private Renderer targetRenderer;
        [SerializeField] private string keyword = "_DEBUG_TERMS_ON";
        [SerializeField] private bool keywordEnabled;
        [SerializeField] private bool applyOnUpdate;

        private void Reset()
        {
            targetRenderer = GetComponent<Renderer>();
        }

        private void OnEnable()
        {
            ApplyKeyword();
        }

        private void Update()
        {
            if (applyOnUpdate)
            {
                ApplyKeyword();
            }
        }

        private void ApplyKeyword()
        {
            if (targetRenderer == null || string.IsNullOrWhiteSpace(keyword))
            {
                return;
            }

            Material material = targetRenderer.material;

            // Keyword 会切换 Shader 编译分支；学习阶段可用它观察“功能开关”和变体的关系。
            if (keywordEnabled)
            {
                material.EnableKeyword(keyword);
            }
            else
            {
                material.DisableKeyword(keyword);
            }
        }
    }
}
