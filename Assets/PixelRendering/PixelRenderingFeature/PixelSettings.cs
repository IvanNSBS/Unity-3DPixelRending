using UnityEngine;

namespace PixelRendering.PixelRenderingFeature
{
    [CreateAssetMenu(fileName="Pixel Renderer Settings", menuName="Pixel Rendering", order=0)]
    public class PixelSettings : ScriptableObject
    {
        [SerializeField] private int _width;
        [SerializeField] private int _height;
        [SerializeField] private RenderTexture _rt;
        [SerializeField] private Material _renderNormalsMat;
        [SerializeField] private Material _outlineBlitMaterial;
        
        public int width => _width;
        public int height => _height;
        public RenderTexture rt => _rt;
        public Material NormalPassMat => _renderNormalsMat;
        public Material OutlineBlitMaterial => _outlineBlitMaterial;
    }
}