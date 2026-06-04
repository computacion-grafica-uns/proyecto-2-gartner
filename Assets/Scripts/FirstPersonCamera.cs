using UnityEngine;

public class FirstPersonCamera : MonoBehaviour
{
    public float moveSpeed = 200f;
    public float mouseSensitivity = 150f;
    public float initialYaw = 180f;

    private float pitch = 0f;
    private float yaw = 0f;

    void Start()
    {
        Vector3 angles = transform.eulerAngles;

        pitch = angles.x;
        yaw = initialYaw;
        transform.rotation = Quaternion.Euler(pitch, yaw, 0f);

        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        //
        // Rotación
        //
        yaw += Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;

        pitch -= Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;
        pitch = Mathf.Clamp(pitch, -80f, 80f);

        transform.rotation = Quaternion.Euler(pitch, yaw, 0f);

        //
        // Movimiento
        //
        Vector3 move =
            transform.forward * Input.GetAxis("Vertical") +
            transform.right * Input.GetAxis("Horizontal");

        if (Input.GetKey(KeyCode.Space))
            move += Vector3.up;

        if (Input.GetKey(KeyCode.LeftShift))
            move += Vector3.down;

        transform.position += move * moveSpeed * Time.deltaTime;
    }
}
