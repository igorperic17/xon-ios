//
//  XonPipeline.swift
//  XonSNNCore
//
//  Created by  Igor Peric on 28/03/2020.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import Foundation
import Metal
import MetalKit

@objcMembers
public class XonPipeline: NSObject {
    
    // The device (aka GPU) being used to process images.
    private var device: MTLDevice!
    
    private var computePipelineState: MTLComputePipelineState!
    private var renderPipelineState: MTLRenderPipelineState!
    
    private var commandQueue: MTLCommandQueue!
        
    // Texture object which serves as the source for image processing
    private var inputTexture: MTLTexture!

    // Texture object which serves as the output for image processing
    private var outputTexture: MTLTexture!

    // The current size of the viewport, used in the render pipeline.
    private var viewportSize = vector_uint2.init(x: 0, y: 0)

    // Compute kernel dispatch parameters
    private var threadgroupSize = MTLSize()
    private var threadgroupCount = MTLSize()
    
    public convenience init(withMetalKitView mtkView: MTKView) {
        self.init()
        device = mtkView.device
        mtkView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        
        // Load all the shader files with a .metal file extension in the project.
        let frameworkBundle = Bundle.init(for: type(of: self))
        if let defaultLibrary = try? device.makeDefaultLibrary(bundle: frameworkBundle) {
        
            // Load the image processing function from the library and create a pipeline from it.
            if let kernelFunction = defaultLibrary.makeFunction(name: "grayscaleKernel") {
                computePipelineState = try? device.makeComputePipelineState(function: kernelFunction)
                
                // Load the vertex and fragment functions, and use them to configure a render pipeline.
                let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
                let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader")
                
                let pipelineStateDescriptor = MTLRenderPipelineDescriptor.init()
                pipelineStateDescriptor.label = "Simple Render Pipeline"
                pipelineStateDescriptor.vertexFunction = vertexFunction
                pipelineStateDescriptor.fragmentFunction = fragmentFunction
                pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
                
                renderPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
                
                // load image
                let imageFileLocation = frameworkBundle.url(forResource: "initial-neuron-noise-2", withExtension: "tga")!
                guard let image = AAPLImage.init(tgaFileAtLocation: imageFileLocation) else { return }
                
                let textureDescriptor = MTLTextureDescriptor.init()
                textureDescriptor.textureType = MTLTextureType.type2D
                // Indicate that each pixel has a Blue, Green, Red, and Alpha channel,
                //   each in an 8 bit unnormalized value (0 maps 0.0 while 255 maps to 1.0)
                textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
                textureDescriptor.width = Int(image.width)
                textureDescriptor.height = Int(image.height)
                

                // The image kernel only needs to read the incoming image data.
                textureDescriptor.usage = MTLTextureUsage.shaderRead
                inputTexture = device.makeTexture(descriptor: textureDescriptor)

                // The output texture needs to be written by the image kernel, and sampled
                // by the rendering code.
                textureDescriptor.usage = [ .shaderRead, .shaderWrite ]
                outputTexture = device.makeTexture(descriptor: textureDescriptor)
                
                let region = MTLRegion.init(origin: MTLOrigin.init(x: 0, y: 0, z: 0), size: MTLSize.init(width: textureDescriptor.width, height: textureDescriptor.height, depth: 1))

                // size of each texel * the width of the textures
                let bytesPerRow = 4 * textureDescriptor.width
                
                // Copy the bytes from our data object into the texture
                try? image.data.withUnsafeBytes {
                    outputTexture?.replace(region: region, mipmapLevel: 0, withBytes: $0, bytesPerRow: bytesPerRow)
                }
                
                // Set the compute kernel's threadgroup size to 16x16
                threadgroupSize = MTLSize.init(width: 16, height: 16, depth: 1)

                // Calculate the number of rows and columns of threadgroups given the width of the input image
                // Ensure that you cover the entire image (or more) so you process every pixel
                threadgroupCount.width  = (inputTexture!.width  + threadgroupSize.width -  1) / threadgroupSize.width;
                threadgroupCount.height = (inputTexture!.height + threadgroupSize.height - 1) / threadgroupSize.height;

                // The image data is 2D, so set depth to 1
                threadgroupCount.depth = 1;

                // Create the command queue
                commandQueue = device?.makeCommandQueue()
            }
        }
    }
}

extension XonPipeline: MTKViewDelegate {
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Save the size of the drawable to pass to the render pipeline.
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
    }
    
    public func draw(in view: MTKView) {
        let VIEW_SIZE = Float(500.0)
        let quadVertices: [Float] = [
            // Pixel positions, Texture coordinates
              VIEW_SIZE,  -VIEW_SIZE, 1.0, 1.0,
             -VIEW_SIZE,  -VIEW_SIZE, 0.0, 1.0,
             -VIEW_SIZE,   VIEW_SIZE, 0.0, 0.0,
    
              VIEW_SIZE,  -VIEW_SIZE, 1.0, 1.0,
             -VIEW_SIZE,   VIEW_SIZE, 0.0, 0.0,
              VIEW_SIZE,   VIEW_SIZE, 1.0, 0.0,
        ]
        
        // Create a new command buffer for each frame.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "MyCommand"

        // Process the input image.
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setComputePipelineState(computePipelineState!)
        computeEncoder.setTexture(outputTexture, index: Int(XonTextureIndexInput.rawValue))
        computeEncoder.setTexture(outputTexture, index: Int(XonTextureIndexOutput.rawValue))
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()


        // Use the output image to draw to the view's drawable texture.
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.label = "MyRenderEncoder"
            
            renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
            renderEncoder.setRenderPipelineState(renderPipelineState!)
            
            //  Encode the vertex data.
            quadVertices.withUnsafeBytes() {
                renderEncoder.setVertexBytes($0.baseAddress!, length: quadVertices.count * MemoryLayout<Float>.stride, index: Int(XonVertexInputIndexVertices.rawValue))
            }
            renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout.size(ofValue: viewportSize), index: Int(XonVertexInputIndexViewportSize.rawValue))
            
            // Encode the output texture from the previous stage.
            renderEncoder.setFragmentTexture(outputTexture, index: Int(XonTextureIndexOutput.rawValue))

            // Draw the quad.
            renderEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()

            // Schedule a present once the framebuffer is complete using the current drawable
            commandBuffer.present(view.currentDrawable!)
        }
        commandBuffer.commit()
    }
    
}
