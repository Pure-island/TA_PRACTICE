using NUnit.Framework;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Object = UnityEngine.Object;

namespace TA_Practice.Chapter05.Tests
{
    public sealed class Chapter05PostProcessVolumeTests
    {
        [Test]
        public void DefaultVolumeIsInactive()
        {
            var volume = ScriptableObject.CreateInstance<Chapter05PostProcessVolume>();

            try
            {
                Assert.IsFalse(volume.IsActive());
            }
            finally
            {
                Object.DestroyImmediate(volume);
            }
        }

        [Test]
        public void VolumeBecomesActiveWhenAnyEffectHasVisibleIntensity()
        {
            var volume = ScriptableObject.CreateInstance<Chapter05PostProcessVolume>();

            try
            {
                volume.grayscaleIntensity.overrideState = true;
                volume.grayscaleIntensity.value = 0.5f;

                Assert.IsTrue(volume.IsActive());
            }
            finally
            {
                Object.DestroyImmediate(volume);
            }
        }

        [Test]
        public void VolumeIsNotTileCompatibleBecauseItSamplesNeighborPixels()
        {
            var volume = ScriptableObject.CreateInstance<Chapter05PostProcessVolume>();

            try
            {
                Assert.IsFalse(volume.IsTileCompatible());
            }
            finally
            {
                Object.DestroyImmediate(volume);
            }
        }

        [Test]
        public void RendererFeatureSettingsUseAfterRenderingPostProcessingByDefault()
        {
            var settings = new Chapter05PostProcessFeature.Settings();

            Assert.AreEqual(RenderPassEvent.AfterRenderingPostProcessing, settings.renderPassEvent);
        }
    }
}
