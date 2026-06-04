using UnityEngine;

public class CameraSwitcher : MonoBehaviour
{
    public Camera orbitalCamera;
    public Camera fpsCamera;
    public KeyCode switchKey = KeyCode.C;

    private bool usingOrbital = true;
    private OrbitalCamera orbitalController;
    private FirstPersonCamera fpsController;

    void Start()
    {
        if (orbitalCamera != null)
            orbitalController = orbitalCamera.GetComponent<OrbitalCamera>();

        if (fpsCamera != null)
            fpsController = fpsCamera.GetComponent<FirstPersonCamera>();

        SetCamera(usingOrbital);
    }

    void Update()
    {
        if (Input.GetKeyDown(switchKey))
        {
            usingOrbital = !usingOrbital;
            SetCamera(usingOrbital);

            Debug.Log("Cámara actual: " + (usingOrbital ? "Orbital" : "FPS"));
        }
    }

    void SetCamera(bool orbital)
    {
        if (orbitalCamera != null)
            orbitalCamera.enabled = orbital;

        if (fpsCamera != null)
            fpsCamera.enabled = !orbital;

        if (orbitalController != null)
            orbitalController.enabled = orbital;

        if (fpsController != null)
            fpsController.enabled = !orbital;

        Cursor.lockState = orbital ? CursorLockMode.None : CursorLockMode.Locked;
        Cursor.visible = orbital;
    }
}
