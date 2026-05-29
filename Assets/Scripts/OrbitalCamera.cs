using UnityEngine;

public class OrbitalCamera : MonoBehaviour
{
    [Header("Target")]
    public Vector3 targetPosition = Vector3.zero;

    [Header("Rotation")]
    public float rotationSpeed = 120f;
    public float keyboardRotationSpeed = 90f;

    public float minVerticalAngle = -80f;
    public float maxVerticalAngle = 80f;

    [Header("Zoom")]
    public float distance = 40f;
    public float minDistance = 2f;
    public float maxDistance = 40f;
    public float zoomSpeed = 5f;

    private float yaw;
    private float pitch;

    void Start()
    {
        Vector3 angles = transform.eulerAngles;

        yaw = angles.y;
        pitch = angles.x;
    }

    void LateUpdate()
    {
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");

        if (Input.GetMouseButton(1))
        {
            yaw += mouseX * rotationSpeed * Time.deltaTime;
            pitch -= mouseY * rotationSpeed * Time.deltaTime;
        }

        if (Input.GetKey(KeyCode.LeftArrow))
            yaw -= keyboardRotationSpeed * Time.deltaTime;

        if (Input.GetKey(KeyCode.RightArrow))
            yaw += keyboardRotationSpeed * Time.deltaTime;

        if (Input.GetKey(KeyCode.UpArrow))
            pitch -= keyboardRotationSpeed * Time.deltaTime;

        if (Input.GetKey(KeyCode.DownArrow))
            pitch += keyboardRotationSpeed * Time.deltaTime;

        pitch = Mathf.Clamp(pitch, minVerticalAngle, maxVerticalAngle);

        float scroll = Input.GetAxis("Mouse ScrollWheel");

        distance -= scroll * zoomSpeed;
        distance = Mathf.Clamp(distance, minDistance, maxDistance);

        Quaternion rotation = Quaternion.Euler(pitch, yaw, 0);

        Vector3 offset = rotation * new Vector3(0, 0, -distance);

        transform.position = targetPosition + offset;

        transform.LookAt(targetPosition);
    }
}