Shader "Custom/ThreeLightsBlinnPhong"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1, 1, 1, 1)

        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)
        _MaterialKa ("Material Ka", Vector) = (0.2, 0.2, 0.2, 1)
        _MaterialKd ("Material Kd", Vector) = (0.8, 0.8, 0.8, 1)
        _MaterialKs ("Material Ks", Vector) = (1, 1, 1, 1)
        _Shininess ("Shininess", Float) = 32

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

            fixed4 _MaterialColor;

            fixed4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float _Shininess;

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

            float3 BlinnPhongLight(
                float3 normal,
                float3 viewDir,
                float3 lightDir,
                float3 lightColor,
                float attenuation
            )
            {
                float NdotL = max(dot(normal, lightDir), 0.0);

                float3 diffuse =
                    _MaterialKd.rgb *
                    lightColor *
                    NdotL;

                float3 H = normalize(lightDir + viewDir);

                float specularFactor = pow(
                    max(dot(normal, H), 0.0),
                    _Shininess
                );

                float3 specular =
                    _MaterialKs.rgb *
                    lightColor *
                    specularFactor;

                return (diffuse + specular) * attenuation;
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
                    BlinnPhongLight(
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

                float3 pointLightResult  =
                    BlinnPhongLight(
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

                float3 spot = float3(0, 0, 0);

                if (angle < radians(_Apertura))
                {
                    float attenuationSpot =
                        1.0 / (1.0 + _SpotLightAttenuation * distanceToSpot * distanceToSpot);

                    spot =
                        BlinnPhongLight(
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
                    pointLightResult  +
                    spot;

                finalColor *= _MaterialColor.rgb;

                return fixed4(finalColor, _MaterialColor.a);
            }

            ENDCG
        }
    }
}
