using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace TA_Practice.Chapter05
{
    [Serializable]
    [VolumeComponentMenu("TA Practice/Chapter05 Post Process")]
    public sealed class Chapter05PostProcessVolume : VolumeComponent, IPostProcessComponent
    {
        [Header("01 Grayscale")]
        public ClampedFloatParameter grayscaleIntensity = new ClampedFloatParameter(0f, 0f, 1f);

        [Header("02 CRT")]
        public ClampedFloatParameter crtIntensity = new ClampedFloatParameter(0f, 0f, 1f);
        public ClampedFloatParameter scanlineIntensity = new ClampedFloatParameter(0.45f, 0f, 1f);
        public ClampedFloatParameter scanlineCount = new ClampedFloatParameter(360f, 80f, 900f);
        public ClampedFloatParameter curvature = new ClampedFloatParameter(0.08f, 0f, 0.25f);
        public ClampedFloatParameter vignetteIntensity = new ClampedFloatParameter(0.45f, 0f, 1f);

        [Header("03 Sobel Edge")]
        public ClampedFloatParameter edgeIntensity = new ClampedFloatParameter(0f, 0f, 1f);
        public ClampedFloatParameter edgeThreshold = new ClampedFloatParameter(0.18f, 0.01f, 1f);
        public ColorParameter edgeColor = new ColorParameter(Color.black);

        [Header("04 Gaussian Blur")]
        public ClampedFloatParameter blurIntensity = new ClampedFloatParameter(0f, 0f, 1f);
        public ClampedFloatParameter blurSize = new ClampedFloatParameter(1.5f, 0.1f, 8f);
        public ClampedIntParameter blurIterations = new ClampedIntParameter(1, 1, 4);

        [Header("05 Bloom")]
        public ClampedFloatParameter bloomIntensity = new ClampedFloatParameter(0f, 0f, 3f);
        public ClampedFloatParameter bloomThreshold = new ClampedFloatParameter(1f, 0f, 4f);
        public ClampedFloatParameter bloomSoftKnee = new ClampedFloatParameter(0.5f, 0f, 1f);
        public ClampedFloatParameter bloomRadius = new ClampedFloatParameter(2f, 0.5f, 6f);

        [Header("06 Motion Blur")]
        public ClampedFloatParameter motionBlurIntensity = new ClampedFloatParameter(0f, 0f, 1f);
        public Vector2Parameter motionBlurDirection = new Vector2Parameter(new Vector2(1f, 0f));
        public ClampedIntParameter motionBlurSamples = new ClampedIntParameter(6, 2, 8);

        public bool IsActive()
        {
            return grayscaleIntensity.value > 0.001f
                || crtIntensity.value > 0.001f
                || edgeIntensity.value > 0.001f
                || blurIntensity.value > 0.001f
                || bloomIntensity.value > 0.001f
                || motionBlurIntensity.value > 0.001f;
        }

        public bool IsTileCompatible()
        {
            // 本章效果会跨像素采样邻居颜色，不适合 tile-based 的单像素后处理路径。
            return false;
        }
    }
}
