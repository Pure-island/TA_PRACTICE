using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace TA_Practice.Chapter05
{
    public sealed class Chapter05PostProcessFeature : ScriptableRendererFeature
    {
        [Serializable]
        public sealed class Settings
        {
            public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
            public Shader shader;
            public Material material;
        }

        public Settings settings = new Settings();

        private Chapter05PostProcessPass pass;
        private Material runtimeMaterial;

        public override void Create()
        {
            pass = new Chapter05PostProcessPass(settings.renderPassEvent);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Preview || renderingData.cameraData.cameraType == CameraType.Reflection)
            {
                return;
            }

            Material material = ResolveMaterial();
            if (material == null)
            {
                return;
            }

            Chapter05PostProcessVolume volume = VolumeManager.instance.stack.GetComponent<Chapter05PostProcessVolume>();
            if (volume == null || !volume.IsActive())
            {
                return;
            }

            pass.renderPassEvent = settings.renderPassEvent;
            pass.Setup(material);
            renderer.EnqueuePass(pass);
        }

        protected override void Dispose(bool disposing)
        {
            pass?.Dispose();
            CoreUtils.Destroy(runtimeMaterial);
        }

        private Material ResolveMaterial()
        {
            if (settings.material != null)
            {
                return settings.material;
            }

            if (settings.shader == null)
            {
                settings.shader = Shader.Find("TA_Practice/Chapter05/URPPostProcess");
            }

            if (settings.shader == null)
            {
                return null;
            }

            if (runtimeMaterial == null || runtimeMaterial.shader != settings.shader)
            {
                CoreUtils.Destroy(runtimeMaterial);
                runtimeMaterial = CoreUtils.CreateEngineMaterial(settings.shader);
            }

            return runtimeMaterial;
        }
    }
}
