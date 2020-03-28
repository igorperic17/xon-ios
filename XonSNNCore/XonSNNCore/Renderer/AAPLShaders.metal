/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "AAPLShaderTypes.h"

// Vertex shader outputs and per-fragment inputs.  Includes clip-space position and vertex outputs
//  interpolated by rasterizer and fed to each fragment generated by clip-space primitives.
typedef struct
{
    // The [[position]] attribute qualifier of this member indicates this value is the clip space
    //   position of the vertex wen this structure is returned from the vertex shader
    float4 clipSpacePosition [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer will
    //   interpolate its value with values of other vertices making up the triangle and
    //   pass that interpolated value to the fragment shader for each fragment in that triangle;
    float2 textureCoordinate;

} RasterizerData;

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant AAPLVertex *vertexArray [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(AAPLVertexInputIndexViewportSize) ]])

{

    RasterizerData out;

    // Index into the array of positions to get the current vertex
    // Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    // the origin)
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    float2 viewportSize = float2(*viewportSizePointer);

    // convert the pixel positions into normalized device coordinates.
    
    // The output position of every vertex shader is in clip space (also known as normalized device
    //   coordinate space, or NDC).   A value of (-1.0, -1.0) in clip-space represents the
    //   lower-left corner of the viewport whereas (1.0, 1.0) represents the upper-right corner of
    //   the viewport.

    // In order to convert from positions in pixel space to positions in clip space, divide the
    //   pixel coordinates by half the size of the viewport.
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.clipSpacePosition.z = 0.0;
    out.clipSpacePosition.w = 1.0;

    // Pass the input textureCoordinate straight to the output RasterizerData.  This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4 samplingShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(AAPLTextureIndexOutput) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture and return the color to colorSample
    const half4 colorSample = colorTexture.sample (textureSampler, in.textureCoordinate);
    return float4(colorSample);
}

// Rec. 709 luma values for grayscale image conversion
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

// Grayscale compute kernel
kernel void
grayscaleKernel(texture2d<half, access::read>  inTexture  [[texture(AAPLTextureIndexInput)]],
                texture2d<half, access::write> outTexture [[texture(AAPLTextureIndexOutput)]],
                uint2                          gid         [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

//    half4 inColor  = inTexture.read(gid);
//    half  gray     = dot(inColor.rgb, kRec709Luma);
    
    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, kRec709Luma);
    half  out    = gray;
    
    if (gid.x < 100) out = out + 0.005;
    
#define INH_RADIUS 20.0
    if (out >= 1.0) {
        out = 0.0;
        
        for (int i=-INH_RADIUS;i<INH_RADIUS;i++) {
            for (int j=0;j<INH_RADIUS;j++) {
                float d = sqrt(float(i*i) + j*j);
                float inh = 0.005 * (sqrt(INH_RADIUS * INH_RADIUS) / d);
                uint2 neighboarGid = uint2(gid.x + i, gid.y + j);
                half4 neighbor = inTexture.read(neighboarGid);
                half  neighborGray = dot(neighbor.rgb, kRec709Luma);
                half  neighborOut = neighborGray + inh; // strong inhibition
                outTexture.write(half4(neighborOut, neighborOut, neighborOut, 1.0), neighboarGid);
            }
        }
    }
    outTexture.write(half4(out, out, out, 1.0), gid);
}

