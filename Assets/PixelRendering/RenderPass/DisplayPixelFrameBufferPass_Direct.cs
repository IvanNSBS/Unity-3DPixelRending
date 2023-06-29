using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.RenderPass
{
    public class DisplayPixelFrameBufferPassDirect : ScriptableRenderPass
    {
        private RTHandle _pixelFB, _pixelDepth, _camColor, _camDepth;
        
        public DisplayPixelFrameBufferPassDirect(RenderPassEvent evt)
        {
            renderPassEvent = evt;
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("Display Pixel Frame");
            
            renderingData.cameraData.renderer.ConfigureCameraTarget(_camColor, _camDepth);
            cmd.Blit(_pixelFB, _camColor);
            cmd.Blit(_pixelDepth, _camDepth);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            
        }

        public void Setup(RTHandle pixelFB, RTHandle pixelDepth, RTHandle camFB, RTHandle camDepth, int width, int height)
        {
            _pixelFB = pixelFB;
            _pixelDepth = pixelDepth;
            
            _camColor = camFB;
            _camDepth = camDepth;
        }
    }
}