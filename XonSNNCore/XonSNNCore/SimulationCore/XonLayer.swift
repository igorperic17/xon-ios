//
//  XonLayer.swift
//  XonSNNCore
//
//  Created by  Igor Peric on 30/03/2020.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import Foundation
import MetalKit

public class XonLayer: NSObject {
    
    // Texture object which serves as the numerical storage
    // and output as well
    public var inTexture: MTLTexture!
    
    // Texture object which serves as the numerical storage
    // and output as well
    public var outTexture: MTLTexture!
    
    // The current size of the viewport, used in the render pipeline.
    private var viewportSize = vector_uint2.init(x: 0, y: 0)
    
    private var renderView: MTKView!
    
    // Kernel dispatch parameters
    public var threadgroupSize = MTLSize()
    public var threadgroupCount = MTLSize()
    
    public var computePipelineState: MTLComputePipelineState!
    public var renderPipelineState: MTLRenderPipelineState!
    
    public var parentXonPipeline: XonPipeline?
    
    static let VIEW_SIZE = Float(500.0)
    let quadVertices: [Float] = [
        // Pixel positions, Texture coordinates
          VIEW_SIZE,  -VIEW_SIZE, 1.0, 1.0,
         -VIEW_SIZE,  -VIEW_SIZE, 0.0, 1.0,
         -VIEW_SIZE,   VIEW_SIZE, 0.0, 0.0,

          VIEW_SIZE,  -VIEW_SIZE, 1.0, 1.0,
         -VIEW_SIZE,   VIEW_SIZE, 0.0, 0.0,
          VIEW_SIZE,   VIEW_SIZE, 1.0, 0.0,
    ]
    
    public convenience init(withNeuronModel model: String, onComputePipeline pipeline: XonPipeline) {
        self.init()
        parentXonPipeline = pipeline
        
        // Load all the shader files with a .metal file extension in the project.
        let frameworkBundle = Bundle.init(for: type(of: self))
        if let defaultLibrary = try? parentXonPipeline?.device.makeDefaultLibrary(bundle: frameworkBundle) {
        
            // Load the image processing function from the library and create a pipeline from it.
            if let kernelFunction = defaultLibrary.makeFunction(name: model) {
                computePipelineState = try? parentXonPipeline?.device.makeComputePipelineState(function: kernelFunction)
                
                // Load the vertex and fragment functions, and use them to configure a render pipeline.
                let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
                let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader")
                
                let pipelineStateDescriptor = MTLRenderPipelineDescriptor.init()
                pipelineStateDescriptor.label = "Simple Render Pipeline"
                pipelineStateDescriptor.vertexFunction = vertexFunction
                pipelineStateDescriptor.fragmentFunction = fragmentFunction
                pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm_srgb
                
                renderPipelineState = try? parentXonPipeline?.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
                
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
                textureDescriptor.usage = [ .shaderRead, .shaderWrite ]
                inTexture = parentXonPipeline?.device.makeTexture(descriptor: textureDescriptor)

                // The output texture needs to be written by the image kernel, and sampled
                // by the rendering code.
                outTexture = parentXonPipeline?.device.makeTexture(descriptor: textureDescriptor)
                
                let region = MTLRegion.init(origin: MTLOrigin.init(x: 0, y: 0, z: 0), size: MTLSize.init(width: textureDescriptor.width, height: textureDescriptor.height, depth: 1))

                // size of each texel * the width of the textures
                let bytesPerRow = 4 * textureDescriptor.width
                
                // Copy the bytes from our data object into the texture
                try? image.data.withUnsafeBytes {
                    outTexture?.replace(region: region, mipmapLevel: 0, withBytes: $0, bytesPerRow: bytesPerRow)
                }
                
                // Set the compute kernel's threadgroup size to 16x16
                threadgroupSize = MTLSize.init(width: 16, height: 16, depth: 1)

                // Calculate the number of rows and columns of threadgroups given the width of the input image
                // Ensure that you cover the entire image (or more) so you process every pixel
                threadgroupCount.width  = (inTexture!.width  + threadgroupSize.width -  1) / threadgroupSize.width;
                threadgroupCount.height = (outTexture!.height + threadgroupSize.height - 1) / threadgroupSize.height;

                // The image data is 2D, so set depth to 1
                threadgroupCount.depth = 1;
            }
        }
    }
    
    public func setRenderTarget(_ view: MTKView) {
        view.delegate = self
        view.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        view.device = parentXonPipeline?.device
        renderView = view
        parentXonPipeline?.renderableLayers.append(self)
    }
    
    public func computeLayer() {
        let computeEncoder = parentXonPipeline!.commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(computePipelineState!)
        computeEncoder.setTexture(inTexture, index: Int(XonTextureIndexInput.rawValue))
        computeEncoder.setTexture(outTexture, index: Int(XonTextureIndexOutput.rawValue))
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
//        computeEncoder.updateFence(parentXonPipeline!.fence)
        computeEncoder.endEncoding()
    }
    
    public func renderLayer() {

        self.parentXonPipeline!.commandBufferRender = self.parentXonPipeline!.commandQueueRender!.makeCommandBuffer()!
        self.parentXonPipeline!.commandBufferRender.label = "MyCommandRender"
        
        // Use the output image to draw to the view's drawable texture.
        if let renderPassDescriptor = self.renderView.currentRenderPassDescriptor {
            
            let renderEncoder = self.parentXonPipeline!.commandBufferRender.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.label = "MyRenderEncoder"

            renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(self.viewportSize.x), height: Double(self.viewportSize.y), znear: -1.0, zfar: 1.0))
            renderEncoder.setRenderPipelineState(self.renderPipelineState!)

            //  Encode the vertex data.
            self.quadVertices.withUnsafeBytes() {
                renderEncoder.setVertexBytes($0.baseAddress!, length: self.quadVertices.count * MemoryLayout<Float>.stride, index: Int(XonVertexInputIndexVertices.rawValue))
            }
            renderEncoder.setVertexBytes(&self.viewportSize, length: MemoryLayout.size(ofValue: self.viewportSize), index: Int(XonVertexInputIndexViewportSize.rawValue))

            // Encode the output texture from the previous stage.
            renderEncoder.setFragmentTexture(self.outTexture, index: Int(XonTextureIndexOutput.rawValue))

            // Draw the quad.
            renderEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 6)
//            renderEncoder.waitForFence(parentXonPipeline!.fence, before: .vertex)
            renderEncoder.endEncoding()

            // Schedule a present once the framebuffer is complete using the current drawable
            self.parentXonPipeline!.commandBufferRender.present(self.renderView.currentDrawable!)
            
            self.parentXonPipeline!.commandBufferRender.commit()
        }
    }
}

extension XonLayer: MTKViewDelegate {
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Save the size of the drawable to pass to the render pipeline.
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
    }
    
    public func draw(in view: MTKView) {
        renderLayer()
    }
}
