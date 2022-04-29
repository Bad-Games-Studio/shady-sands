Shader "Custom/Epic shader"
{
    Properties
    {
        [MainTexture]
        _BaseMap("Texture", 2D) = "white" {}
        _TintColor("Tint Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertex_shader_main
            #pragma fragment fragment_shader_main

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct vertex2fragment
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal_world_space : TEXCOORD1;
            };

            
            CBUFFER_START(UnityPerMaterial)

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST; // xy - tiling, zw - offset.
            float4 _TintColor;
            
            CBUFFER_END

            
            vertex2fragment vertex_shader_main (appdata v)
            {
                vertex2fragment result;
                result.vertex = TransformObjectToHClip(v.position.xyz);
                result.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                result.normal_world_space = TransformObjectToWorldNormal(v.normal);
                return result;
            }

            
            float4 fragment_shader_main (vertex2fragment i) : SV_Target
            {
                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _TintColor;

                Light light = GetMainLight();
                float4 light_color = float4(light.color, 1);
                float normal_dot_light = dot(i.normal_world_space, light.direction);
                
                return normal_dot_light * light_color * albedo;
            }
            ENDHLSL
        }
    }
}

