Shader "HDRenderPipeline/Lit"
{
    Properties
    {
        // Following set of parameters represent the parameters node inside the MaterialGraph.
        // They are use to fill a SurfaceData. With a MaterialGraph this should not exist.

        // Reminder. Color here are in linear but the UI (color picker) do the conversion sRGB to linear
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _BaseColorMap("BaseColorMap", 2D) = "white" {}

        _Metallic("_Metallic", Range(0.0, 1.0)) = 0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 1.0
        _MaskMap("MaskMap", 2D) = "white" {}

        _SpecularOcclusionMap("SpecularOcclusion", 2D) = "white" {}

        _NormalMap("NormalMap", 2D) = "bump" {}
        _NormalScale("_NormalScale", Range(0.0, 2.0)) = 1

        _HeightMap("HeightMap", 2D) = "black" {}
        _HeightAmplitude("Height Amplitude", Float) = 0.01 // In world units
        _HeightCenter("Height Center", Float) = 0.5 // In texture space

        _DetailMap("DetailMap", 2D) = "black" {}
        _DetailMask("DetailMask", 2D) = "white" {}
        _DetailAlbedoScale("_DetailAlbedoScale", Range(-2.0, 2.0)) = 1
        _DetailNormalScale("_DetailNormalScale", Range(0.0, 2.0)) = 1
        _DetailSmoothnessScale("_DetailSmoothnessScale", Range(-2.0, 2.0)) = 1

        _TangentMap("TangentMap", 2D) = "bump" {}
        _Anisotropy("Anisotropy", Range(0.0, 1.0)) = 0
        _AnisotropyMap("AnisotropyMap", 2D) = "white" {}

        [Enum(Standard, 0, Subsurface Scattering, 1, Clear Coat, 2, Specular Color, 3)] _MaterialID("MaterialId", Int) = 0
        _SubsurfaceProfile("Subsurface Profile", Int) = 0
        _SubsurfaceRadius("Subsurface Radius", Range(0.004, 1.0)) = 1.0
        _SubsurfaceRadiusMap("Subsurface Radius Map", 2D) = "white" {}
        _Thickness("Thickness", Range(0.004, 1.0)) = 0.5
        _ThicknessMap("Thickness Map", 2D) = "white" {}

        //_CoatCoverage("CoatCoverage", Range(0.0, 1.0)) = 0
        //_CoatCoverageMap("CoatCoverageMapMap", 2D) = "white" {}

        //_CoatRoughness("CoatRoughness", Range(0.0, 1.0)) = 0
        //_CoatRoughnessMap("CoatRoughnessMap", 2D) = "white" {}

        _DistortionVectorMap("DistortionVectorMap", 2D) = "black" {}

        // Following options are for the GUI inspector and different from the input parameters above
        // These option below will cause different compilation flag.

        _EmissiveColor("EmissiveColor", Color) = (0, 0, 0)
        _EmissiveColorMap("EmissiveColorMap", 2D) = "white" {}
        _EmissiveIntensity("EmissiveIntensity", Float) = 0

        [ToggleOff] _DistortionEnable("Enable Distortion", Float) = 0.0
        [ToggleOff] _DistortionOnly("Distortion Only", Float) = 0.0
        [ToggleOff] _DistortionDepthTest("Distortion Depth Test Enable", Float) = 0.0
        [ToggleOff] _DepthOffsetEnable("Depth Offset View space", Float) = 0.0

        [ToggleOff]  _AlphaCutoffEnable("Alpha Cutoff Enable", Float) = 0.0
        _AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _HorizonFade("Horizon fade", Range(0.0, 5.0)) = 1.0

        // Stencil state
        [HideInInspector] _StencilRef("_StencilRef", Int) = 0

        // Blending state
        [HideInInspector] _SurfaceType("__surfacetype", Float) = 0.0
        [HideInInspector] _BlendMode("__blendmode", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _CullMode("__cullmode", Float) = 2.0
        [HideInInspector] _ZTestMode("_ZTestMode", Int) = 8

        // Material Id
        [HideInInspector] _MaterialId("_MaterialId", FLoat) = 0

        [ToggleOff] _DoubleSidedEnable("Double sided enable", Float) = 0.0

        [Enum(UV0, 0, Planar, 1, TriPlanar, 2)] _UVBase("UV Set for base", Float) = 0
        _TexWorldScale("Scale to apply on world coordinate", Float) = 1.0
        [HideInInspector] _UVMappingMask("_UVMappingMask", Color) = (1, 0, 0, 0)
        [HideInInspector] _UVMappingPlanar("_UVMappingPlanar", Float) = 0
        [Enum(TangentSpace, 0, ObjectSpace, 1)] _NormalMapSpace("NormalMap space", Float) = 0
        [ToggleOff]  _EnablePerPixelDisplacement("Enable per pixel displacement", Float) = 0.0
        _PPDMinSamples("Min sample for POM", Range(1.0, 64.0)) = 5
        _PPDMaxSamples("Max sample for POM", Range(1.0, 64.0)) = 15
        _PPDLodThreshold("Start lod to fade out the POM effect", Range(0.0, 16.0)) = 5
        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _UVDetail("UV Set for detail", Float) = 0
        [HideInInspector] _UVDetailsMappingMask("_UVDetailsMappingMask", Color) = (1, 0, 0, 0)
        [Enum(Use Emissive Color, 0, Use Emissive Mask, 1)] _EmissiveColorMode("Emissive color mode", Float) = 1        
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 ps4 metal // TEMP: until we go futher in dev

    //-------------------------------------------------------------------------------------
    // Variant
    //-------------------------------------------------------------------------------------

    #pragma shader_feature _ALPHATEST_ON
    #pragma shader_feature _DISTORTION_ON
    #pragma shader_feature _DEPTHOFFSET_ON
    #pragma shader_feature _DOUBLESIDED_ON

    #pragma shader_feature _MAPPING_TRIPLANAR
    #pragma shader_feature _NORMALMAP_TANGENT_SPACE
    #pragma shader_feature _PER_PIXEL_DISPLACEMENT
    #pragma shader_feature _ _REQUIRE_UV2 _REQUIRE_UV3
    #pragma shader_feature _EMISSIVE_COLOR

    #pragma shader_feature _NORMALMAP  
    #pragma shader_feature _MASKMAP
    #pragma shader_feature _SPECULAROCCLUSIONMAP
    #pragma shader_feature _EMISSIVE_COLOR_MAP
    #pragma shader_feature _HEIGHTMAP
    #pragma shader_feature _TANGENTMAP
    #pragma shader_feature _ANISOTROPYMAP
    #pragma shader_feature _DETAIL_MAP
    #pragma shader_feature _SUBSURFACE_RADIUS_MAP
    #pragma shader_feature _THICKNESS_MAP

    #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
    #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED
    #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
    // TODO: We should have this keyword only if VelocityInGBuffer is enable, how to do that ?
    //#pragma multi_compile VELOCITYOUTPUT_OFF VELOCITYOUTPUT_ON

    //-------------------------------------------------------------------------------------
    // Define
    //-------------------------------------------------------------------------------------

    #define UNITY_MATERIAL_LIT // Need to be define before including Material.hlsl

    //-------------------------------------------------------------------------------------
    // Include
    //-------------------------------------------------------------------------------------

    #include "ShaderLibrary/common.hlsl"
    #include "HDRenderPipeline/ShaderConfig.cs.hlsl"
    #include "HDRenderPipeline/ShaderVariables.hlsl"
    #include "HDRenderPipeline/ShaderPass/FragInputs.hlsl"
    #include "HDRenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

    //-------------------------------------------------------------------------------------
    // variable declaration
    //-------------------------------------------------------------------------------------

    #include "HDRenderPipeline/Material/Lit/LitProperties.hlsl"

    // All our shaders use same name for entry point
    #pragma vertex Vert
    #pragma fragment Frag

    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 300

        Pass
        {
            Name "GBuffer"  // Name is not used
            Tags { "LightMode" = "GBuffer" } // This will be only for opaque object based on the RenderQueue index

            Cull  [_CullMode]

            Stencil
            {
                Ref  [_StencilRef]
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_GBUFFER
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitSharePass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassGBuffer.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "GBufferDebugLighting"  // Name is not used
            Tags{ "LightMode" = "GBufferDebugLighting" } // This will be only for opaque object based on the RenderQueue index

            Cull[_CullMode]

                Stencil
            {
                Ref[_StencilRef]
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM

            #define LIGHTING_DEBUG
            #define SHADERPASS SHADERPASS_GBUFFER
            #include "HDRenderPipeline/Debug/HDRenderPipelineDebug.cs.hlsl"
            #include "HDRenderPipeline/Debug/DebugLighting.hlsl"
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitSharePass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassGBuffer.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Debug"
            Tags { "LightMode" = "DebugViewMaterial" }

            Cull[_CullMode]

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DEBUG_VIEW_MATERIAL
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitSharePass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassDebugViewMaterial.hlsl"

            ENDHLSL
        }

        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM

            // Lightmap memo
            // DYNAMICLIGHTMAP_ON is used when we have an "enlighten lightmap" ie a lightmap updated at runtime by enlighten.This lightmap contain indirect lighting from realtime lights and realtime emissive material.Offline baked lighting(from baked material / light, 
            // both direct and indirect lighting) will hand up in the "regular" lightmap->LIGHTMAP_ON.

            #define SHADERPASS SHADERPASS_LIGHT_TRANSPORT
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitMetaPass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassLightTransport.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            Cull[_CullMode]

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #include "../../Material/Material.hlsl"            
            #include "ShaderPass/LitDepthPass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassDepthOnly.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{ "LightMode" = "DepthOnly" }

            Cull[_CullMode]

            ZWrite On

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitDepthPass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassDepthOnly.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Motion Vectors"
            Tags{ "LightMode" = "MotionVectors" } // Caution, this need to be call like this to setup the correct parameters by C++ (legacy Unity)

            Cull[_CullMode]

            ZWrite Off // TODO: Test Z equal here.

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_VELOCITY
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitVelocityPass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassVelocity.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Distortion" // Name is not used
            Tags { "LightMode" = "DistortionVectors" } // This will be only for transparent object based on the RenderQueue index

            Blend One One
            ZTest [_ZTestMode]
            ZWrite off
            Cull [_CullMode]

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DISTORTION
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/LitDistortionPass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassDistortion.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Forward" // Name is not used
            Tags { "LightMode" = "Forward" } // This will be only for transparent object based on the RenderQueue index

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_FORWARD
            #include "../../Lighting/Forward.hlsl"
            // TEMP until pragma work in include
            #pragma multi_compile LIGHTLOOP_SINGLE_PASS LIGHTLOOP_TILE_PASS

            #include "../../Lighting/Lighting.hlsl"
            #include "ShaderPass/LitSharePass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassForward.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ForwardDebugLighting" // Name is not used
            Tags{ "LightMode" = "ForwardDebugLighting" } // This will be only for transparent object based on the RenderQueue index

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_CullMode]

            HLSLPROGRAM

            #define LIGHTING_DEBUG
            #define SHADERPASS SHADERPASS_FORWARD
            #include "../../Lighting/Forward.hlsl"
            #include "HDRenderPipeline/Debug/HDRenderPipelineDebug.cs.hlsl"
            #include "HDRenderPipeline/Debug/DebugLighting.hlsl"

            // TEMP until pragma work in include
            #pragma multi_compile LIGHTLOOP_SINGLE_PASS LIGHTLOOP_TILE_PASS

            #include "../../Lighting/Lighting.hlsl"
            #include "ShaderPass/LitSharePass.hlsl"
            #include "LitData.hlsl"
            #include "../../ShaderPass/ShaderPassForward.hlsl"

            ENDHLSL
        }

    }

    CustomEditor "Experimental.Rendering.HDPipeline.LitGUI"
}
