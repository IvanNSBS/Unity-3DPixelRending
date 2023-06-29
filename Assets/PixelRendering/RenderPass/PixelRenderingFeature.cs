using UnityEngine;
using PixelRendering.RenderPass;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PixelRenderingFeature : ScriptableRendererFeature
{
    #region Fields
    private DisplayPixelFrameBufferPassDirect _displayPixelBuffer;
    private NormalsPass _normalsPass;
    private RTHandle _cameraFrameBuffer, _cameraDepthBuffer, _pixelFrameBuffer, _pixelDepthBuffer;

    [SerializeField][Min(320)] private int _width = 320; 
    [SerializeField][Min(180)] private int _height = 180;
    [SerializeField] private Material _normalPassMaterial;
    [SerializeField] private RenderPassEvent _evt = RenderPassEvent.AfterRenderingPostProcessing;
    #endregion
    
    #region Methods
    public override void Create()
    {
        _displayPixelBuffer = new DisplayPixelFrameBufferPassDirect(_evt);
        _normalsPass = new NormalsPass(_normalPassMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        #if UNITY_EDITOR
        if (renderingData.cameraData.isSceneViewCamera) return;
        #endif

        
        renderer.EnqueuePass(_normalsPass);
        renderer.EnqueuePass(_displayPixelBuffer); 
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        #if UNITY_EDITOR
        if (renderingData.cameraData.isSceneViewCamera) return;
        #endif

        if (_displayPixelBuffer is DisplayPixelFrameBufferPassDirect)
        {
            _cameraFrameBuffer = renderingData.cameraData.renderer.cameraColorTargetHandle;
            _cameraDepthBuffer = renderingData.cameraData.renderer.cameraDepthTargetHandle;
            
            _pixelFrameBuffer = RTHandles.Alloc(_width, _height, colorFormat: GraphicsFormat.R8G8B8A8_UNorm, name:"Pixel Buffer");
            _pixelDepthBuffer = RTHandles.Alloc(_width, _height, depthBufferBits: DepthBits.Depth32, colorFormat: GraphicsFormat.R8G8B8A8_UNorm);
                 
            renderer.ConfigureCameraTarget(_pixelFrameBuffer, _pixelDepthBuffer); 
        }
        
        _normalsPass.Setup(_width, _height);
        _displayPixelBuffer.Setup(_pixelFrameBuffer, _pixelDepthBuffer, _cameraFrameBuffer, _cameraDepthBuffer, _width, _height);
    }
    #endregion
}
