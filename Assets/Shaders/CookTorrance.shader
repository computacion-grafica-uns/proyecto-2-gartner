Shader "Custom/CookTorrance"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1, 1, 1, 1)

        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)
        _MaterialKa ("Material Ka", Vector) = (0.2, 0.2, 0.2, 1)
        _MaterialKd ("Material Kd", Vector) = (0.8, 0.8, 0.8, 1)

        // Cook-Torrance
        _F0 ("F0 / Fresnel Reflectance", Color) = (0.04, 0.04, 0.04, 1)
        _Roughness ("Roughness", Range(0.02, 1.0)) = 0.35

        // Render state. Opaque materials use One/Zero + ZWrite On.
        // Semi-transparent materials use SrcAlpha/OneMinusSrcAlpha + ZWrite Off.
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Float) = 0
        [Enum(Off,0,On,1)] _ZWrite ("ZWrite", Float) = 1

        // Luz direccional
        _DirLightDirection ("Directional Light Direction", Vector) = (1, -1, 1, 0)
        _DirLightColor ("Directional Light Color", Color) = (1, 1, 1, 1)

        // Luz puntual
        _PointLightPosition ("Point Light Position", Vector) = (0, 2, -2, 1)
        _PointLightColor ("Point Light Color", Color) = (1, 0, 0, 1)
        _PointLightIntensity ("Point Light Intensity", Float) = 1
        _PointLightAttenuation ("Point Light Attenuation", Float) = 0.2

        // Luz spot
        _SpotLightPosition ("Spot Light Position", Vector) = (2, 3, -2, 1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (-1, -1, 1, 0)
        _SpotLightColor ("Spot Light Color", Color) = (0, 0, 1, 1)
        _SpotLightIntensity ("Spot Light Intensity", Float) = 1
        _SpotLightAttenuation ("Spot Light Attenuation", Float) = 0.2
        _Apertura ("Apertura", Range(0.0, 90.0)) = 30
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM

            #pragma vertex vertexShader
            #pragma fragment fragmentShader

            #include "UnityCG.cginc"

            #define PI 3.14159265359

            fixed4 _MaterialColor;

            fixed4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;

            fixed4 _F0;
            float _Roughness;

            float4 _DirLightDirection;
            fixed4 _DirLightColor;

            float4 _PointLightPosition;
            fixed4 _PointLightColor;
            float _PointLightIntensity;
            float _PointLightAttenuation;

            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            fixed4 _SpotLightColor;
            float _SpotLightIntensity;
            float _SpotLightAttenuation;
            float _Apertura;

            struct VertexData
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
            };

            struct VertexToFragment
            {
                float4 position : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            VertexToFragment vertexShader(VertexData v)
            {
                VertexToFragment output;

                output.position = UnityObjectToClipPos(v.position);
                output.worldPosition = mul(unity_ObjectToWorld, v.position).xyz;
                output.worldNormal = UnityObjectToWorldNormal(v.normal);

                return output;
            }

            float3 FresnelSchlick(float VdotH, float3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float alpha)
            {
                float alpha2 = alpha * alpha;
                float denominator = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
                return alpha2 / max(PI * denominator * denominator, 0.0001);
            }

            float GeometrySchlickGGX(float NdotX, float alpha)
            {
                // Aproximacion de Schlick para GGX: k = alpha / 2
                float k = alpha * 0.5;
                return NdotX / max(NdotX * (1.0 - k) + k, 0.0001);
            }

            float GeometrySmith(float NdotL, float NdotV, float alpha)
            {
                float gLight = GeometrySchlickGGX(NdotL, alpha);
                float gView = GeometrySchlickGGX(NdotV, alpha);
                return gLight * gView;
            }

            float3 CookTorranceLight(
                float3 normal,
                float3 viewDir,
                float3 lightDir,
                float3 lightColor,
                float attenuation
            )
            {
                float3 N = normalize(normal);
                float3 V = normalize(viewDir);
                float3 L = normalize(lightDir);
                float3 H = normalize(L + V);

                float NdotL = max(dot(N, L), 0.0);
                float NdotV = max(dot(N, V), 0.0);
                float NdotH = max(dot(N, H), 0.0);
                float VdotH = max(dot(V, H), 0.0);

                if (NdotL <= 0.0 || NdotV <= 0.0)
                {
                    return float3(0.0, 0.0, 0.0);
                }

                // En la actividad: alpha = roughness^2
                float roughness = max(_Roughness, 0.02);
                float alpha = roughness * roughness;

                float3 F = FresnelSchlick(VdotH, _F0.rgb);
                float D = DistributionGGX(NdotH, alpha);
                float G = GeometrySmith(NdotL, NdotV, alpha);

                float3 specularBRDF = (F * D * G) / max(4.0 * NdotL * NdotV, 0.0001);

                // Parte difusa del BRDF de Cook-Torrance: rho_d / PI
                float3 diffuseBRDF = _MaterialKd.rgb / PI;

                return (diffuseBRDF + specularBRDF) * lightColor * NdotL * attenuation;
            }

            fixed4 fragmentShader(VertexToFragment i) : SV_Target
            {
                float3 N = normalize(i.worldNormal);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition);

                // -------------------------
                // Ambiental
                // -------------------------
                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // -------------------------
                // Luz direccional
                // -------------------------
                float3 L1 = normalize(-_DirLightDirection.xyz);

                float3 directional =
                    CookTorranceLight(
                        N,
                        V,
                        L1,
                        _DirLightColor.rgb,
                        1.0
                    );

                // -------------------------
                // Luz puntual
                // -------------------------
                float3 toPointLight =
                    _PointLightPosition.xyz - i.worldPosition;

                float distanceToPoint = length(toPointLight);
                float3 L2 = normalize(toPointLight);

                float attenuationPoint =
                    1.0 / (1.0 + _PointLightAttenuation * distanceToPoint * distanceToPoint);

                float3 pointLightResult =
                    CookTorranceLight(
                        N,
                        V,
                        L2,
                        _PointLightColor.rgb * _PointLightIntensity,
                        attenuationPoint
                    );

                // -------------------------
                // Luz spot
                // -------------------------
                float3 toSpotLight =
                    _SpotLightPosition.xyz - i.worldPosition;

                float distanceToSpot = length(toSpotLight);
                float3 L3 = normalize(toSpotLight);

                float3 spotDir = normalize(-_SpotLightDirection.xyz);
                float angle = acos(dot(L3, spotDir));

                float3 spot = float3(0.0, 0.0, 0.0);

                if (angle < radians(_Apertura))
                {
                    float attenuationSpot =
                        1.0 / (1.0 + _SpotLightAttenuation * distanceToSpot * distanceToSpot);

                    spot =
                        CookTorranceLight(
                            N,
                            V,
                            L3,
                            _SpotLightColor.rgb * _SpotLightIntensity,
                            attenuationSpot
                        );
                }

                // -------------------------
                // Resultado final
                // -------------------------
                float3 finalColor =
                    ambient +
                    directional +
                    pointLightResult +
                    spot;

                finalColor *= _MaterialColor.rgb;

                return fixed4(finalColor, _MaterialColor.a);
            }

            ENDCG
        }
    }
}
