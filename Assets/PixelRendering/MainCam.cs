using UnityEngine;

[RequireComponent(typeof(Camera))]
public class MainCam : MonoBehaviour
{
    [SerializeField] private Camera _rt_cam;
    [SerializeField] private Camera _this;
    
    
    private void OnValidate()
    {
        _rt_cam.orthographicSize = _this.orthographicSize;
    }

    // Update is called once per frame
    void Update()
    {
        _rt_cam.orthographicSize = _this.orthographicSize;

        if (Input.GetKeyDown(KeyCode.Mouse0))
        {
            Ray ray = Camera.main.ScreenPointToRay (Input.mousePosition);
            RaycastHit[] hit = Physics.RaycastAll(ray, Mathf.Infinity);
            if (hit.Length == 0)
                return;

            float closest = 99999;
            int closest_index = -1;
            for(int i = 0; i  < hit.Length; i++)
            {
                float distance = Vector3.Distance(hit[i].collider.transform.position, transform.position);
                if (distance < closest)
                {
                    closest = distance;
                    closest_index = i;
                }
            }
            // Debug.Log(hit[closest_index].collider.gameObject.name);
        }
    }
}
