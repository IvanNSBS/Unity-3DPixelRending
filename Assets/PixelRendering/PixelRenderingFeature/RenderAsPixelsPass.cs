using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using PixelRendering.PixelRenderingFeature;

namespace PixelRendering.TestPass
{
    public class RenderAsPixelsPass : ScriptableRenderPass
    {
        private PixelSettings _settings;
        
        public RenderAsPixelsPass(PixelSettings settings)
        {
            _settings = settings;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.tag != "MainCamera")
                return;
            
            var cmd = CommandBufferPool.Get();
            var cameraRT = renderingData.cameraData.renderer.cameraColorTargetHandle;
            // cmd.Blit(_settings.rt, cameraRT);
            cmd.Blit(_settings.rt, cameraRT, _settings.OutlineBlitMaterial);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }
    }
}