using UnityEngine;

/// <summary>
/// Mobile-friendly orbit, pan and pinch-zoom camera for the city and battlefield.
/// One finger rotates, two fingers pinch to zoom, and two-finger drag pans.
/// Mouse drag and wheel remain available in the Unity Editor.
/// </summary>
[RequireComponent(typeof(Camera))]
public sealed class CityOrbitCamera : MonoBehaviour
{
    public Transform target;
    [Min(8f)] public float distance = 95f;
    [Min(8f)] public float minDistance = 24f;
    [Min(20f)] public float maxDistance = 220f;
    public float rotationSpeed = 0.18f;
    public float zoomSpeed = 0.08f;
    public float panSpeed = 0.12f;
    public float minPitch = 18f;
    public float maxPitch = 78f;

    private float yaw = 35f;
    private float pitch = 48f;
    private Vector3 lastPanPoint;

    private void Start()
    {
        ApplyLandscapeOrientation();
        if (target == null)
        {
            GameObject focus = new GameObject("Camera Focus");
            focus.transform.position = Vector3.zero;
            target = focus.transform;
        }
        Vector3 angles = transform.eulerAngles;
        yaw = angles.y;
        pitch = Mathf.Clamp(angles.x, minPitch, maxPitch);
        distance = Mathf.Clamp(Vector3.Distance(transform.position, target.position), minDistance, maxDistance);
        ApplyCamera();
    }

    private void ApplyLandscapeOrientation()
    {
        Screen.autorotateToPortrait = false;
        Screen.autorotateToPortraitUpsideDown = false;
        Screen.autorotateToLandscapeLeft = true;
        Screen.autorotateToLandscapeRight = true;
        Screen.orientation = ScreenOrientation.AutoRotation;
    }

    private void LateUpdate()
    {
        HandleTouchInput();
        HandleMouseInput();
        ApplyCamera();
    }

    private void HandleTouchInput()
    {
        if (Input.touchCount == 1)
        {
            Touch touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Moved)
            {
                yaw += touch.deltaPosition.x * rotationSpeed;
                pitch -= touch.deltaPosition.y * rotationSpeed;
                pitch = Mathf.Clamp(pitch, minPitch, maxPitch);
            }
        }
        else if (Input.touchCount >= 2)
        {
            Touch a = Input.GetTouch(0);
            Touch b = Input.GetTouch(1);
            Vector2 previousA = a.position - a.deltaPosition;
            Vector2 previousB = b.position - b.deltaPosition;
            float previousGap = Vector2.Distance(previousA, previousB);
            float currentGap = Vector2.Distance(a.position, b.position);
            distance -= (currentGap - previousGap) * zoomSpeed;
            distance = Mathf.Clamp(distance, minDistance, maxDistance);

            Vector2 midpointDelta = ((a.deltaPosition + b.deltaPosition) * 0.5f);
            Vector3 right = transform.right;
            Vector3 up = Vector3.ProjectOnPlane(transform.up, Vector3.up).normalized;
            target.position -= (right * midpointDelta.x + up * midpointDelta.y) * panSpeed;
        }
    }

    private void HandleMouseInput()
    {
#if UNITY_EDITOR || UNITY_STANDALONE
        if (Input.GetMouseButton(1))
        {
            yaw += Input.GetAxis("Mouse X") * 4f;
            pitch -= Input.GetAxis("Mouse Y") * 4f;
            pitch = Mathf.Clamp(pitch, minPitch, maxPitch);
        }
        float wheel = Input.mouseScrollDelta.y;
        if (Mathf.Abs(wheel) > 0.001f)
            distance = Mathf.Clamp(distance - wheel * 6f, minDistance, maxDistance);
#endif
    }

    private void ApplyCamera()
    {
        if (target == null) return;
        Quaternion rotation = Quaternion.Euler(pitch, yaw, 0f);
        transform.position = target.position + rotation * new Vector3(0f, 0f, -distance);
        transform.rotation = rotation;
    }

    public void Focus(Vector3 point, float newDistance)
    {
        if (target == null) return;
        target.position = point;
        distance = Mathf.Clamp(newDistance, minDistance, maxDistance);
    }
}
