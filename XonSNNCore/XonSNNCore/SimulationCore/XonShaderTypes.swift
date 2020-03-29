//
//  XonShaderTypes.swift
//  XonSNNCore
//
//  Created by  Igor Peric on 28/03/2020.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import Foundation


// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
public enum XonVertexInputIndex: Int {
    case vertices = 0
    case viewPortSize = 1
}

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
public enum XonTextureIndex: Int {
    case input = 0
    case output = 1
}

//  This structure defines the layout of each vertex in the array of vertices set as an input to our
//    Metal vertex shader.  Since this header is shared between the .metal shader and C code,
//    the layout of the vertex array in the code matches the layout that the vertex shader expects
public class XonVertex: NSObject {
    // Positions in pixel space (i.e. a value of 100 indicates 100 pixels from the origin/center)
    var position: vector_float2!
    // 2D texture coordinate
    var textureCoordinate: vector_float2!
}
