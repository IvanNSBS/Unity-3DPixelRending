using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.TestPass
{
    public class TestPass : ScriptableRenderPass
    {
        private RenderTexture _rt;
        public TestPass(RenderTexture rt)
        {
            _rt = rt;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.tag != "MainCamera")
                return;
            var cmd = CommandBufferPool.Get();
            var cameraRT = renderingData.cameraData.renderer.cameraColorTargetHandle;
            cmd.Blit(_rt, cameraRT);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }
    }
}