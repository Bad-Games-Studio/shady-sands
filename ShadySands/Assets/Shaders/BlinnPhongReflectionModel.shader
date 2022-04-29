// Got an idea from here:
// https://github.com/GilFerraz/Unity-Shaders-Introduction/blob/master/Assets/Shaders/9.%20Diffuse%20Ambient%20Specular%20Pixel%20Texture%20(Blinn-Phong).shader

Shader "Blinn–Phong reflection model"
{
    Properties
    {
        [MainTexture]
        _BaseMap("Texture", 2D) = "white" {}
        _TintColor("Tint Color", Color) = (1, 1, 1, 1)
        _HighlightColor("Highlight Color", Color) = (1, 1, 1, 1)
        _Shininess("Shininess", Range(64.0, 1024.0)) = 0.5
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
            
            CBUFFER_START(UnityPerMaterial)

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST; // xy - tiling, zw - offset.
            float4 _TintColor;
            float4 _HighlightColor;
            float _Shininess;
            
            CBUFFER_END


            struct vertex_input
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct vertex_output
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal_world_space : TEXCOORD1;
                float3 view_direction : TEXCOORD2;
            };
            
            
            vertex_output vertex_shader_main(vertex_input v)
            {
                vertex_output result;
                result.vertex = TransformObjectToHClip(v.position.xyz);
                result.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                
                
                result.normal_world_space = normalize(TransformObjectToWorldNormal(v.normal));

                float3 object_pos = mul(unity_ObjectToWorld, v.position).xyz;
                result.view_direction = normalize(_WorldSpaceCameraPos - object_pos);
                
                return result;
            }
            
            
            float4 fragment_shader_main(vertex_output i) : SV_Target
            {
                float4 texture_pixel = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float4 ambient_color = texture_pixel * _TintColor;

                Light light = GetMainLight();
                float4 light_color = float4(light.color, 1);
                float3 light_direction = normalize(light.direction);

                float light_intensity = dot(i.normal_world_space, light.direction);
                float4 diffuse_color = light_intensity * light_color;;
                
                float specular_intensity = 0;
                light_intensity = max(light_intensity, 0);
                if (light_intensity > 0)
                {
                    float3 halfway_vector = normalize(light_direction + i.view_direction);
                    float t = dot(i.normal_world_space, halfway_vector);
                    specular_intensity = pow(max(t, 0), _Shininess);
                }
                
                return max(ambient_color * light_intensity + specular_intensity * _HighlightColor, ambient_color * diffuse_color);
            }
            
            ENDHLSL
        }
    }
}
