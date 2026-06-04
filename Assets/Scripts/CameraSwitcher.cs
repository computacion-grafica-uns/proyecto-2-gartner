using UnityEngine;

public class CameraSwitcher : MonoBehaviour
{
    public Camera orbitalCamera;
    public Camera fpsCamera;

    private bool usingOrbital = true;

    void Start()
    {
        SetCamera(true);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.C))
        {
            usingOrbital = !usingOrbital;
            SetCamera(usingOrbital);

            Debug.Log("Cámara actual: " + (usingOrbital ? "Orbital" : "FPS"));
        }
    }

    void SetCamera(bool orbital)
    {
        orbitalCamera.enabled = orbital;
        fpsCamera.enabled = !orbital;
    }
}