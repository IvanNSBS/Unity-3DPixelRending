using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PixelRendering.RenderPass
{
    public class NormalsPass : ScriptableRenderPass
    {
        private Material _normalsMat;
        private int _normalsTexture = Shader.PropertyToID("_NormalsPassTexture");
        private int _depthTexture = Shader.PropertyToID("_DepthPassTextureasdasdasd");
        private int _width, _height;
        
        private List<ShaderTagId> _shaderTagIdList;
        private FilteringSettings _filterSettings;
        private ProfilingSampler _profilingSampler;
        
        public NormalsPass(Material normalsMat)
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
            _normalsMat = normalsMat;
            
            _shaderTagIdList = new List<ShaderTagId>
            {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit")
            };
            
            _filterSettings = new FilteringSettings(RenderQueueRange.opaque);
            _profilingSampler = new ProfilingSampler("Pixel Rendering Normals Pass");
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            
            using (new ProfilingScope(cmd, _profilingSampler))
            {
                cmd.GetTemporaryRT(_normalsTexture, _width, _height, 0, FilterMode.Point);
                cmd.GetTemporaryRT(_depthTexture, _width, _height, 32, FilterMode.Point, RenderTextureFormat.Depth);
                
                cmd.SetRenderTarget(
                    _normalsTexture, 
                    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare,
                    _depthTexture, 
                    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare
                );
                
                cmd.ClearRenderTarget(true, true, Color.clear);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
                DrawingSettings drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);
                drawingSettings.overrideMaterial = _normalsMat;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filterSettings);
                
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                cmd.SetGlobalTexture("_NormalsPassTexture", _normalsTexture);
                cmd.SetGlobalTexture("_DepthPassTexture", _depthTexture);
                cmd.SetGlobalVector("_ViewportSize", new Vector4(_width, _height, 0, 0));
            }
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_normalsTexture);
            cmd.ReleaseTemporaryRT(_depthTexture);
        }

        public void Setup(int width, int height)
        {
            _width = width;
            _height = height;
        }
    }
}