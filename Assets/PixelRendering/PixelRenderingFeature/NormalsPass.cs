using System.Collections.Generic;
using PixelRendering.PixelRenderingFeature;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.RenderPass
{
    public class NormalsPass : ScriptableRenderPass
    {
        private PixelSettings _settings;
        
        private int _normalsTexture = Shader.PropertyToID("_NormalsPassTexture");
        private int _depthTexture = Shader.PropertyToID("_DepthPassTexture");
        private List<ShaderTagId> _shaderTagIdList;
        private FilteringSettings _filterSettings;
        private ProfilingSampler _profilingSampler;
        
        public NormalsPass(PixelSettings settings)
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
            _settings = settings;
            
            _shaderTagIdList = new List<ShaderTagId>
            {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit")
            };
            
            _filterSettings = new FilteringSettings(RenderQueueRange.opaque);
            _profilingSampler = new ProfilingSampler("Pixel Rendering Normals Pass");
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            int width = _settings.width; 
            int height = _settings.height;
            cmd.GetTemporaryRT(_normalsTexture, width, height, 0, FilterMode.Point);
            cmd.GetTemporaryRT(_depthTexture, width, height, 32, FilterMode.Point, RenderTextureFormat.Depth);
            
            ConfigureTarget(_normalsTexture, _depthTexture);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.tag == "MainCamera")
                return;
            
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, _profilingSampler))
            {
                cmd.ClearRenderTarget(true, true, Color.clear);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
                DrawingSettings drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);
                drawingSettings.overrideMaterial = _settings.NormalPassMat;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filterSettings);
                
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                cmd.SetGlobalTexture("_NormalsPassTexture", _normalsTexture);
                cmd.SetGlobalTexture("_DepthPassTexture", _depthTexture);
            }
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_normalsTexture);
            cmd.ReleaseTemporaryRT(_depthTexture);
        }
    }
}