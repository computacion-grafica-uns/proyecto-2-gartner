Shader "Custom/ToonNormalMapping"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1, 1, 1, 1)
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)
        _MaterialKa ("Material Ka", Vector) = (0.2, 0.2, 0.2, 1)
        _MaterialKd ("Material Kd", Vector) = (0.8, 0.8, 0.8, 1)
        _MaterialKs ("Material Ks", Vector) = (1, 1, 1, 1)
        _Shininess ("Shininess", Float) = 32
        _DiffuseBands ("Diffuse Bands", Range(2, 6)) = 3
        _SpecularThreshold ("Specular Threshold", Range(0.0, 1.0)) = 0.6
        _SpecularSmoothness ("Specular Smoothness", Range(0.001, 0.5)) = 0.05

        _MainTex ("Main Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0.0, 2.0)) = 1.0

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalStrength;

            fixed4 _MaterialColor;
            fixed4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float _Shininess;
            float _DiffuseBands;
            float _SpecularThreshold;
            float _SpecularSmoothness;

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
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct VertexToFragment
            {
                float4 position : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBitangent : TEXCOORD3;
                float2 uvMain : TEXCOORD4;
                float2 uvNormal : TEXCOORD5;
            };

            VertexToFragment vertexShader(VertexData v)
            {
                VertexToFragment output;

                output.position = UnityObjectToClipPos(v.position);
                output.worldPosition = mul(unity_ObjectToWorld, v.position).xyz;

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 worldBitangent = cross(worldNormal, worldTangent) * tangentSign;

                output.worldNormal = worldNormal;
                output.worldTangent = worldTangent;
                output.worldBitangent = worldBitangent;
                output.uvMain = TRANSFORM_TEX(v.uv, _MainTex);
                output.uvNormal = TRANSFORM_TEX(v.uv, _NormalMap);

                return output;
            }

            float3 GetWorldNormal(VertexToFragment i)
            {
                float3 tangentNormal = UnpackNormal(tex2D(_NormalMap, i.uvNormal));
                tangentNormal.xy *= _NormalStrength;
                tangentNormal = normalize(tangentNormal);

                float3 T = normalize(i.worldTangent);
                float3 B = normalize(i.worldBitangent);
                float3 N = normalize(i.worldNormal);

                float3x3 TBN = float3x3(T, B, N);
                return normalize(mul(tangentNormal, TBN));
            }


            float QuantizeDiffuse(float value, float bands)
            {
                bands = max(bands, 2.0);
                return floor(value * bands) / (bands - 1.0);
            }

            float3 ToonLight(
                float3 normal,
                float3 viewDir,
                float3 lightDir,
                float3 lightColor,
                float attenuation
            )
            {
                float NdotL = max(dot(normal, lightDir), 0.0);

                float toonDiffuseFactor = saturate(QuantizeDiffuse(NdotL, _DiffuseBands));

                float3 diffuse =
                    _MaterialKd.rgb *
                    lightColor *
                    toonDiffuseFactor;

                float3 H = normalize(lightDir + viewDir);

                float blinnSpecular = pow(
                    max(dot(normal, H), 0.0),
                    _Shininess
                );

                float toonSpecularFactor = smoothstep(
                    _SpecularThreshold,
                    _SpecularThreshold + _SpecularSmoothness,
                    blinnSpecular
                );

                float3 specular =
                    _MaterialKs.rgb *
                    lightColor *
                    toonSpecularFactor;

                return (diffuse + specular) * attenuation;
            }

            fixed4 fragmentShader(VertexToFragment i) : SV_Target
            {
                fixed4 albedo = tex2D(_MainTex, i.uvMain) * _MaterialColor;

                float3 N = GetWorldNormal(i);
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
                    ToonLight(
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
                    ToonLight(
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
                        ToonLight(
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

                finalColor *= albedo.rgb;

                return fixed4(finalColor, albedo.a);
            }

            ENDCG
        }
    }
}
