/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC source
*/

#ifndef XonShaderTypes_h
#define XonShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum XonVertexInputIndex
{
    XonVertexInputIndexVertices     = 0,
    XonVertexInputIndexViewportSize = 1,
} XonVertexInputIndex;

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
typedef enum XonTextureIndex
{
    XonTextureIndexInput  = 0,
    XonTextureIndexOutput = 1,
} XonTextureIndex;

//  This structure defines the layout of each vertex in the array of vertices set as an input to our
//    Metal vertex shader.  Since this header is shared between the .metal shader and C code,
//    the layout of the vertex array in the code matches the layout that the vertex shader expects
typedef struct
{
    // Positions in pixel space (i.e. a value of 100 indicates 100 pixels from the origin/center)
    vector_float2 position;

    // 2D texture coordinate
    vector_float2 textureCoordinate;
} XonVertex;

#endif /* XonShaderTypes_h */
