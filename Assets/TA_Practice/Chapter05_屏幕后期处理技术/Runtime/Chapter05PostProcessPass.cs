using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

namespace TA_Practice.Chapter05
{
    public sealed class Chapter05PostProcessPass : ScriptableRenderPass
    {
        private const string PassName = "TA Practice Chapter05 Post Process";

        private static readonly int GrayscaleIntensityId = Shader.PropertyToID("_GrayscaleIntensity");
        private static readonly int CrtIntensityId = Shader.PropertyToID("_CrtIntensity");
        private static readonly int ScanlineIntensityId = Shader.PropertyToID("_ScanlineIntensity");
        private static readonly int ScanlineCountId = Shader.PropertyToID("_ScanlineCount");
        private static readonly int CurvatureId = Shader.PropertyToID("_Curvature");
        private static readonly int VignetteIntensityId = Shader.PropertyToID("_VignetteIntensity");
        private static readonly int EdgeIntensityId = Shader.PropertyToID("_EdgeIntensity");
        private static readonly int EdgeThresholdId = Shader.PropertyToID("_EdgeThreshold");
        private static readonly int EdgeColorId = Shader.PropertyToID("_EdgeColor");
        private static readonly int BlurIntensityId = Shader.PropertyToID("_BlurIntensity");
        private static readonly int BlurSizeId = Shader.PropertyToID("_BlurSize");
        private static readonly int BloomIntensityId = Shader.PropertyToID("_BloomIntensity");
        private static readonly int BloomThresholdId = Shader.PropertyToID("_BloomThreshold");
        private static readonly int BloomSoftKneeId = Shader.PropertyToID("_BloomSoftKnee");
        private static readonly int BloomRadiusId = Shader.PropertyToID("_BloomRadius");
        private static readonly int MotionBlurIntensityId = Shader.PropertyToID("_MotionBlurIntensity");
        private static readonly int MotionBlurDirectionId = Shader.PropertyToID("_MotionBlurDirection");
        private static readonly int MotionBlurSamplesId = Shader.PropertyToID("_MotionBlurSamples");

        private Material material;

        public Chapter05PostProcessPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;
            profilingSampler = new ProfilingSampler(PassName);
        }

        public void Setup(Material sourceMaterial)
        {
            material = sourceMaterial;

            // 后处理要读取当前相机颜色；要求 URP 提供中间颜色纹理，避免直接从 back buffer 采样。
            requiresIntermediateTexture = true;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (material == null)
            {
                return;
            }

            Chapter05PostProcessVolume volume = VolumeManager.instance.stack.GetComponent<Chapter05PostProcessVolume>();
            if (volume == null || !volume.IsActive())
            {
                return;
            }

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

            if (resourceData.isActiveTargetBackBuffer || cameraData.isSceneViewCamera)
            {
                return;
            }

            ApplyVolumeParameters(volume);

            if (volume.grayscaleIntensity.value > 0.001f)
            {
                AddBlitAndSwap(renderGraph, resourceData, 0, "Chapter05 Grayscale");
            }

            if (volume.crtIntensity.value > 0.001f)
            {
                AddBlitAndSwap(renderGraph, resourceData, 1, "Chapter05 CRT");
            }

            if (volume.edgeIntensity.value > 0.001f)
            {
                AddBlitAndSwap(renderGraph, resourceData, 2, "Chapter05 Sobel Edge");
            }

            if (volume.blurIntensity.value > 0.001f)
            {
                int iterations = Mathf.Clamp(volume.blurIterations.value, 1, 4);
                for (int i = 0; i < iterations; i++)
                {
                    AddBlitAndSwap(renderGraph, resourceData, 3, "Chapter05 Gaussian Blur H");
                    AddBlitAndSwap(renderGraph, resourceData, 4, "Chapter05 Gaussian Blur V");
                }
            }

            if (volume.bloomIntensity.value > 0.001f)
            {
                AddBlitAndSwap(renderGraph, resourceData, 5, "Chapter05 Bloom Teaching Pass");
            }

            if (volume.motionBlurIntensity.value > 0.001f)
            {
                AddBlitAndSwap(renderGraph, resourceData, 6, "Chapter05 Motion Blur Teaching Pass");
            }
        }

        public void Dispose()
        {
            material = null;
        }

        private void ApplyVolumeParameters(Chapter05PostProcessVolume volume)
        {
            material.SetFloat(GrayscaleIntensityId, volume.grayscaleIntensity.value);
            material.SetFloat(CrtIntensityId, volume.crtIntensity.value);
            material.SetFloat(ScanlineIntensityId, volume.scanlineIntensity.value);
            material.SetFloat(ScanlineCountId, volume.scanlineCount.value);
            material.SetFloat(CurvatureId, volume.curvature.value);
            material.SetFloat(VignetteIntensityId, volume.vignetteIntensity.value);
            material.SetFloat(EdgeIntensityId, volume.edgeIntensity.value);
            material.SetFloat(EdgeThresholdId, volume.edgeThreshold.value);
            material.SetColor(EdgeColorId, volume.edgeColor.value);
            material.SetFloat(BlurIntensityId, volume.blurIntensity.value);
            material.SetFloat(BlurSizeId, volume.blurSize.value);
            material.SetFloat(BloomIntensityId, volume.bloomIntensity.value);
            material.SetFloat(BloomThresholdId, volume.bloomThreshold.value);
            material.SetFloat(BloomSoftKneeId, volume.bloomSoftKnee.value);
            material.SetFloat(BloomRadiusId, volume.bloomRadius.value);
            material.SetFloat(MotionBlurIntensityId, volume.motionBlurIntensity.value);
            Vector2 motionDirection = volume.motionBlurDirection.value;
            material.SetVector(MotionBlurDirectionId, new Vector4(motionDirection.x, motionDirection.y, 0f, 0f));
            material.SetFloat(MotionBlurSamplesId, volume.motionBlurSamples.value);
        }

        private void AddBlitAndSwap(RenderGraph renderGraph, UniversalResourceData resourceData, int passIndex, string passName)
        {
            TextureHandle source = resourceData.activeColorTexture;
            TextureDesc destinationDesc = renderGraph.GetTextureDesc(source);
            destinationDesc.name = passName;
            destinationDesc.clearBuffer = false;

            TextureHandle destination = renderGraph.CreateTexture(destinationDesc);
            RenderGraphUtils.BlitMaterialParameters parameters = new RenderGraphUtils.BlitMaterialParameters(source, destination, material, passIndex);
            renderGraph.AddBlitPass(parameters, passName: passName);

            // 更新 cameraColor 后，后续 pass 会继续读取上一阶段输出，形成后处理链路。
            resourceData.cameraColor = destination;
        }
    }
}
