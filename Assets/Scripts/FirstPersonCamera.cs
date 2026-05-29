using UnityEngine;

public class FirstPersonCamera : MonoBehaviour
{
    public float moveSpeed = 5f;
    public float sprintSpeed = 10f;
    public float mouseSensitivity = 150f;

    private float pitch = 0f;
    private float yaw = 0f;

    void Start()
    {
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
        float speed = Input.GetKey(KeyCode.LeftShift)
            ? sprintSpeed
            : moveSpeed;

        Vector3 move =
            transform.forward * Input.GetAxis("Vertical") +
            transform.right * Input.GetAxis("Horizontal");

        transform.position += move * speed * Time.deltaTime;
    }
}