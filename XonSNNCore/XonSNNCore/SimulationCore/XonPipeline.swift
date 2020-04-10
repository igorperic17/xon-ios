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


public enum SimulationState {
    case stopped
    case paused
    case running
    case preparingForRun
}


@objcMembers
public class XonPipeline: NSObject {
    
    // The device (aka GPU) being used to process images.
    public var device: MTLDevice!
    
//    private var computePipelineState: MTLComputePipelineState!
//    private var renderPipelineState: MTLRenderPipelineState!
    
    public var commandQueue: MTLCommandQueue!
    public var commandQueueRender: MTLCommandQueue!
    public var commandBuffer: MTLCommandBuffer!
    public var commandBufferRender: MTLCommandBuffer!

    public var neuronPopulations = [XonLayer]()
    public var state: SimulationState = .stopped
    
    // backround thread on which infinite loop operations are queued
    // and waited for
    public let operationQueue = OperationQueue.init()
    
    // list of layers which need rendering
    public var renderableLayers = [XonLayer]()
    
    public let fence: MTLFence!
    
    public override init() {
        operationQueue.maxConcurrentOperationCount = 1
        device = MTLCreateSystemDefaultDevice()
        fence = device.makeFence()
    }
    
    public func run() {
        state = .running
        
        // run this forever on a background thread
        let runner = BlockOperation()
        commandQueue = device?.makeCommandQueue()
        commandQueueRender = device?.makeCommandQueue()
        runner.addExecutionBlock() {
            while (true) {
                if runner.isCancelled { return }

                // Queue up the chain of commands based on the compute graph
                self.commandBuffer = self.commandQueue!.makeCommandBuffer()!
                self.commandBuffer.label = "MyCommand"
                
                // TODO: perform topological sorting to figure out the order
                for layer in self.neuronPopulations {
                    layer.computeLayer()
                }
                
//                for layer in self.renderableLayers {
//                    layer.renderLayer()
//                }

                self.commandBuffer.commit()
                
                self.commandBuffer.waitUntilCompleted()

                if self.state == .stopped { return }
            }
        }
        operationQueue.addOperation(runner)
    }
    
    public func stop() {
        state = .stopped
    }
    
    public func addLayer(_ layer: XonLayer) {
        layer.parentXonPipeline = self
        neuronPopulations.append(layer)
    }
}
