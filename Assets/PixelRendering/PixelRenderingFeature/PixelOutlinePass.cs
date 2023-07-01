using PixelRendering.PixelRenderingFeature;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.RenderPass
{
    public class PixelOutlinePass : ScriptableRenderPass
    {
        private PixelSettings _settings;
        private RTHandle _outlineTexture;
        
        private ProfilingSampler _profilingSampler;
        private RenderTextureDescriptor _descriptor;
        
        public PixelOutlinePass(PixelSettings settings)
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            _settings = settings;
            _profilingSampler = new ProfilingSampler("Pixel Rendering Normals Pass");
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            _descriptor = cameraTextureDescriptor;
            _outlineTexture = RTHandles.Alloc(_descriptor, name: "Outline Post Process Texture");
            ConfigureTarget(_outlineTexture);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.tag == "MainCamera")
                return;
            
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, _profilingSampler))
            {
                var colorBuffer = renderingData.cameraData.renderer.cameraColorTargetHandle;
                
                cmd.ClearRenderTarget(true, true, Color.clear);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                cmd.Blit(colorBuffer, _outlineTexture, _settings.OutlineBlitMaterial);
                cmd.Blit(_outlineTexture, colorBuffer);
            }
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            // _normalsTexture.Release();
            // _depthTexture.Release();
            // _outlineIntermediateTex.Release();
        }
    }
}