using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class MaterialLightSynchronizer : MonoBehaviour
{
    [Header("Materiales")]
    public float materialRefreshInterval = 1f;

    [Header("Luz ambiente")]
    public Color ambientLight = new Color(0.1f, 0.1f, 0.1f, 1f);

    [Header("Luz direccional")]
    public Transform directionalLightObject;
    public Color directionalLightColor = Color.white;

    [Header("Luz puntual")]
    public Transform pointLightObject;
    public Color pointLightColor = Color.red;
    public float pointLightIntensity = 1f;
    public float pointLightAttenuation = 0.2f;

    [Header("Luz spot")]
    public Transform spotLightObject;
    public Color spotLightColor = Color.blue;
    public float spotLightIntensity = 1f;
    public float spotLightAttenuation = 0.2f;
    [Range(0f, 90f)] public float spotLightAperture = 30f;

    private static readonly int AmbientLightId = Shader.PropertyToID("_AmbientLight");
    private static readonly int DirLightDirectionId = Shader.PropertyToID("_DirLightDirection");
    private static readonly int DirLightColorId = Shader.PropertyToID("_DirLightColor");
    private static readonly int PointLightPositionId = Shader.PropertyToID("_PointLightPosition");
    private static readonly int PointLightColorId = Shader.PropertyToID("_PointLightColor");
    private static readonly int PointLightIntensityId = Shader.PropertyToID("_PointLightIntensity");
    private static readonly int PointLightAttenuationId = Shader.PropertyToID("_PointLightAttenuation");
    private static readonly int SpotLightPositionId = Shader.PropertyToID("_SpotLightPosition");
    private static readonly int SpotLightDirectionId = Shader.PropertyToID("_SpotLightDirection");
    private static readonly int SpotLightColorId = Shader.PropertyToID("_SpotLightColor");
    private static readonly int SpotLightIntensityId = Shader.PropertyToID("_SpotLightIntensity");
    private static readonly int SpotLightAttenuationId = Shader.PropertyToID("_SpotLightAttenuation");
    private static readonly int AperturaId = Shader.PropertyToID("_Apertura");

    private readonly HashSet<Material> materials = new HashSet<Material>();
    private float nextMaterialRefreshTime;

    private void OnEnable()
    {
        RefreshMaterials();
        ApplyLightsToMaterials();
    }

    private void Update()
    {
        if (ShouldRefreshMaterials())
        {
            RefreshMaterials();
        }

        ApplyLightsToMaterials();
    }

    private bool ShouldRefreshMaterials()
    {
        if (materialRefreshInterval <= 0f)
        {
            return false;
        }

        if (Application.isPlaying)
        {
            if (Time.time < nextMaterialRefreshTime)
            {
                return false;
            }

            nextMaterialRefreshTime = Time.time + materialRefreshInterval;
            return true;
        }

        if (Time.realtimeSinceStartup < nextMaterialRefreshTime)
        {
            return false;
        }

        nextMaterialRefreshTime = Time.realtimeSinceStartup + materialRefreshInterval;
        return true;
    }

    private void RefreshMaterials()
    {
        materials.Clear();

        Renderer[] renderers = FindObjectsOfType<Renderer>(true);

        foreach (Renderer renderer in renderers)
        {
            Material[] sharedMaterials = renderer.sharedMaterials;

            foreach (Material material in sharedMaterials)
            {
                if (material != null)
                {
                    materials.Add(material);
                }
            }
        }
    }

    private void ApplyLightsToMaterials()
    {
        foreach (Material material in materials)
        {
            if (material == null)
            {
                continue;
            }

            SetColorIfExists(material, AmbientLightId, ambientLight);

            if (directionalLightObject != null)
            {
                SetVectorIfExists(material, DirLightDirectionId, ToDirectionVector(directionalLightObject.forward));
                SetColorIfExists(material, DirLightColorId, directionalLightColor);
            }

            if (pointLightObject != null)
            {
                SetVectorIfExists(material, PointLightPositionId, ToPositionVector(pointLightObject.position));
                SetColorIfExists(material, PointLightColorId, pointLightColor);
                SetFloatIfExists(material, PointLightIntensityId, pointLightIntensity);
                SetFloatIfExists(material, PointLightAttenuationId, pointLightAttenuation);
            }

            if (spotLightObject != null)
            {
                SetVectorIfExists(material, SpotLightPositionId, ToPositionVector(spotLightObject.position));
                SetVectorIfExists(material, SpotLightDirectionId, ToDirectionVector(spotLightObject.forward));
                SetColorIfExists(material, SpotLightColorId, spotLightColor);
                SetFloatIfExists(material, SpotLightIntensityId, spotLightIntensity);
                SetFloatIfExists(material, SpotLightAttenuationId, spotLightAttenuation);
                SetFloatIfExists(material, AperturaId, spotLightAperture);
            }
        }
    }

    private static Vector4 ToPositionVector(Vector3 position)
    {
        return new Vector4(position.x, position.y, position.z, 1f);
    }

    private static Vector4 ToDirectionVector(Vector3 direction)
    {
        return new Vector4(direction.x, direction.y, direction.z, 0f);
    }

    private static void SetColorIfExists(Material material, int propertyId, Color value)
    {
        if (material.HasProperty(propertyId))
        {
            material.SetColor(propertyId, value);
        }
    }

    private static void SetVectorIfExists(Material material, int propertyId, Vector4 value)
    {
        if (material.HasProperty(propertyId))
        {
            material.SetVector(propertyId, value);
        }
    }

    private static void SetFloatIfExists(Material material, int propertyId, float value)
    {
        if (material.HasProperty(propertyId))
        {
            material.SetFloat(propertyId, value);
        }
    }
}
