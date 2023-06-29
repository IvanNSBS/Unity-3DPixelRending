using UnityEngine;
using PixelRendering.TestPass;
using UnityEngine.Rendering.Universal;

public class TestFeature : ScriptableRendererFeature
{
    #region Fields
    private TestPass _testPass;
    [SerializeField] private RenderTexture _rt;
    #endregion
    
    #region Methods
    public override void Create()
    {
        _testPass = new TestPass(_rt); 
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        #if UNITY_EDITOR
        if (renderingData.cameraData.isSceneViewCamera) return;
        #endif

        renderer.EnqueuePass(_testPass);
    }
    #endregion
}
