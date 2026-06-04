using UnityEngine;

public class OrbitalCamera : MonoBehaviour
{
    [Header("Target")]
    public Vector3 targetPosition = Vector3.zero;
    public float upperTargetY = 140f;
    public float middleTargetY = 80f;
    public float lowerTargetY = 20f;
    public Vector3 customTargetPosition = new Vector3(-95f, 81f, -37f);
    public float customTargetDistance = 420f;
    public float targetXStep = 40f;

    [Header("Rotation")]
    public float keyboardRotationSpeed = 90f;

    [Header("Orbit")]
    public float distance = 200f;
    public float height = 10f;

    [Header("Zoom")]
    public float zoomSpeed = 40f;
    public float minDistance = 10f;
    public float maxDistance = 500f;

    private float yaw;

    void Start()
    {
        Vector3 angles = transform.eulerAngles;

        yaw = angles.y;
    }

    void LateUpdate()
    {
        UpdateTargetPosition();

        if (Input.GetKey(KeyCode.LeftArrow))
            yaw -= keyboardRotationSpeed * Time.deltaTime;

        if (Input.GetKey(KeyCode.RightArrow))
            yaw += keyboardRotationSpeed * Time.deltaTime;

        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distance -= scroll * zoomSpeed;
        distance = Mathf.Clamp(distance, minDistance, maxDistance);

        Quaternion rotation = Quaternion.Euler(0f, yaw, 0f);

        Vector3 offset = rotation * new Vector3(0f, height, -distance);

        transform.position = targetPosition + offset;

        transform.LookAt(targetPosition);
    }

    void UpdateTargetPosition()
    {
        if (Input.GetKeyDown(KeyCode.I))
            targetPosition = new Vector3(0f, upperTargetY, 0f);

        if (Input.GetKeyDown(KeyCode.O))
            targetPosition = new Vector3(0f, middleTargetY, 0f);

        if (Input.GetKeyDown(KeyCode.P))
            targetPosition = new Vector3(0f, lowerTargetY, 0f);

        if (Input.GetKeyDown(KeyCode.U))
        {
            targetPosition = customTargetPosition;
            distance = customTargetDistance;
        }

        if (Input.GetKeyDown(KeyCode.Alpha1))
            SetTargetX(1);

        if (Input.GetKeyDown(KeyCode.Alpha2))
            SetTargetX(2);

        if (Input.GetKeyDown(KeyCode.Alpha3))
            SetTargetX(3);

        if (Input.GetKeyDown(KeyCode.Alpha4))
            SetTargetX(4);

        if (Input.GetKeyDown(KeyCode.Alpha5))
            SetTargetX(5);

        if (Input.GetKeyDown(KeyCode.Alpha6))
            SetTargetX(6);
    }

    void SetTargetX(int step)
    {
        targetPosition.x = -targetXStep * step;
    }
}
