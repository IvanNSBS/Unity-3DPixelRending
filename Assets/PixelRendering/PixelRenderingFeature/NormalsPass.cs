using System.Collections.Generic;
using PixelRendering.PixelRenderingFeature;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.RenderPass
{
    public class NormalsPass : ScriptableRenderPass
    {
        private PixelSettings _settings;
        private RenderTextureDescriptor _descriptor;
        
        private int _testColor = Shader.PropertyToID("asdasdsa");
        private int _testIm = Shader.PropertyToID("230948u238932y7984 ");
        private int _testDepth = Shader.PropertyToID("1290381290");

        private RTHandle _cameraColorBuffer;
        private RTHandle _cameraDepthBuffer;
        
        private List<ShaderTagId> _shaderTagIdList;
        private FilteringSettings _filterSettings;
        private ProfilingSampler _profilingSampler;
        
        public NormalsPass(PixelSettings settings)
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
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

        public void Setup(RTHandle color, RTHandle depth)
        {
            _cameraColorBuffer = color;
            _cameraDepthBuffer = depth;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.tag == "MainCamera")
                return;

            CommandBuffer cmd = CommandBufferPool.Get();
            int width = _settings.width;
            int height = _settings.height;
            
            using (new ProfilingScope(cmd, _profilingSampler))
            {
                cmd.GetTemporaryRT(_testColor, width , height, 0, FilterMode.Point, GraphicsFormat.R8G8B8A8_UNorm);
                cmd.GetTemporaryRT(_testDepth, width, height , 16, FilterMode.Point, RenderTextureFormat.Depth);
                
                cmd.SetRenderTarget(
                    _testColor, 
                    RenderBufferLoadAction.Load, RenderBufferStoreAction.Store,
                    _testDepth,
                    RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);
                
                cmd.ClearRenderTarget(true, true, Color.clear);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
                DrawingSettings drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);
                drawingSettings.overrideMaterial = _settings.NormalPassMat;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filterSettings);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                cmd.SetGlobalTexture("_NormalsPassTexture", _testColor);
                cmd.SetGlobalTexture("_DepthTexture", _testDepth);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                cmd.GetTemporaryRT(_testIm, width , height, 0, FilterMode.Point, GraphicsFormat.R8G8B8A8_UNorm);
                cmd.SetRenderTarget(_testIm, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);
                cmd.ClearRenderTarget(false, true, Color.clear);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                _settings.OutlineBlitMaterial.SetFloat("_depthEdgeStrength", _settings.depthEdgeStrength);
                _settings.OutlineBlitMaterial.SetFloat("_normalEdgeStrength", _settings.normalEdgeStrength);
                cmd.Blit(_cameraColorBuffer, _testIm, _settings.OutlineBlitMaterial);
                cmd.Blit(_testIm, _cameraColorBuffer);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                cmd.ReleaseTemporaryRT(_testColor);
                cmd.ReleaseTemporaryRT(_testDepth);
                cmd.ReleaseTemporaryRT(_testIm);
            }
            
            context.ExecuteCommandBuffer(cmd); 
            CommandBufferPool.Release(cmd);
        }
    }
}