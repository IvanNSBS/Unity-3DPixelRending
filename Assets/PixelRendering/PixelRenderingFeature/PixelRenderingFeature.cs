using PixelRendering.PixelRenderingFeature;
using PixelRendering.RenderPass;
using UnityEngine;
using PixelRendering.TestPass;
using UnityEngine.Rendering.Universal;

public class PixelRenderingFeature : ScriptableRendererFeature
{
    #region Fields
    private RenderAsPixelsPass _renderAsPixelsPass;
    private NormalsPass _normalsPass;

    [SerializeField] private PixelSettings _settings;
    #endregion
    
    #region Methods
    public override void Create()
    {
        if (!ValidateSettings())
            return;
        
        _renderAsPixelsPass = new RenderAsPixelsPass(_settings);
        _normalsPass = new NormalsPass(_settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ValidateSettings())
            return;
        
        #if UNITY_EDITOR
        if (renderingData.cameraData.isSceneViewCamera) return;
        #endif

        renderer.EnqueuePass(_normalsPass);
        renderer.EnqueuePass(_renderAsPixelsPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        _normalsPass.Setup(renderingData.cameraData.renderer.cameraColorTargetHandle, renderingData.cameraData.renderer.cameraDepthTargetHandle);
    }

    private bool ValidateSettings()
    {
        if (_settings == null)
        {
            Debug.LogWarning("Pixel Rendering Render settings cannot be null");
            return false;
        }
        if (_settings.rt == null)
        {
            Debug.LogWarning("Pixel Rendering Render Texture cannot be null");
            return false;
        }

        return true;
    }
    #endregion
}
