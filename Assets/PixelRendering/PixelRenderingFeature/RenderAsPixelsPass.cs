using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using PixelRendering.PixelRenderingFeature;
using UnityEngine;

namespace PixelRendering.TestPass
{
    public class RenderAsPixelsPass : ScriptableRenderPass
    {
        private PixelSettings _settings;
        private Material _mat;
        
        public RenderAsPixelsPass(PixelSettings settings)
        {
            _settings = settings;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            
            _mat = CoreUtils.CreateEngineMaterial("Hidden/UpscalePixelRT");
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.tag != "MainCamera")
                return;
            
            var cmd = CommandBufferPool.Get();
            var cameraRT = renderingData.cameraData.renderer.cameraColorTargetHandle;
            cmd.Blit(_settings.rt, cameraRT, _mat);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }
    }
}