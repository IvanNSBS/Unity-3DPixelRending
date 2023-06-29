using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.RenderPass
{
    public class DisplayPixelFrameBufferPass : ScriptableRenderPass
    {
        private RTHandle _pixelFB, _pixelDepth, _camColor, _camDepth;
        private int _fb = Shader.PropertyToID("fb");
        private int _intermediate = Shader.PropertyToID("fb2");
        private int _width, _height;
        private Material _pixelizeMat;
        
        public DisplayPixelFrameBufferPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;
            _pixelizeMat = CoreUtils.CreateEngineMaterial("Hidden/Pixelize");
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("Display Pixel Frame");
            var cameraRT = renderingData.cameraData.renderer.cameraColorTargetHandle;

            // cmd.Blit(cameraRT, _intermediate);
            // cmd.Blit(_intermediate, _fb);
            
            cmd.Blit(cameraRT, _fb);
            cmd.Blit(_fb, cameraRT);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _pixelizeMat.SetVector("_BlockCount", new Vector2(_width, _height));
            _pixelizeMat.SetVector("_BlockSize", new Vector2(1.0f / _width, 1.0f / _height));
            _pixelizeMat.SetVector("_HalfBlockSize", new Vector2(0.5f / _width, 0.5f / _height));
            
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(_intermediate, descriptor, FilterMode.Point);
            descriptor.height = _width;
            descriptor.width = _height;
            cmd.GetTemporaryRT(_fb, descriptor, FilterMode.Point);
        }

        public void Setup(RTHandle pixelFB, RTHandle pixelDepth, RTHandle camFB, RTHandle camDepth, int width, int height)
        {
            _width = width;
            _height = height;
            
            _pixelFB = pixelFB;
            _pixelDepth = pixelDepth;
            
            _camColor = camFB;
            _camDepth = camDepth;
        }
    }
}