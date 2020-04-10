//
//  SimulationEngine.swift
//  XonSNNCore
//
//  Created by Igor Peric on 3/13/20.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import Foundation

public protocol NeuronModelProtocol {
    var delegate: NeuronModelDelegate? { get set }
    
    func step(_ length: Double, _ wallTime: Double)
    func injectSingleSpike()
}

public protocol NeuronModelDelegate {
    func neuronSpiked(_ neuron: NeuronModelProtocol, atTimestamp timestamp: Double)
}

public class SimulationEngine {
    
    // Step size. Default value of 1 ms
    var dT: Double = 1
    
    // current simulation time
    var wallTime: Double = 0
    
    var state: SimulationState = .stopped
    
    private var simComponents = [NeuronModelProtocol]()
    let queue = OperationQueue()
    
    public init() {
        queue.maxConcurrentOperationCount = 1
    }
    
    public func run(_ length: Double = 1) {
        
        state = .running
        
        // support multiple run() calls - DO NOT reset time to 0
        
//        queue.addOperation {

            // determine number of steps
            let numOfSimulationSteps = Int64(length / self.dT)
            
            for _ in 1...numOfSimulationSteps {
                self.wallTime += self.dT
                for component in self.simComponents {
                    component.step(self.dT, self.wallTime)
                }
            }
            self.state = .stopped
//        }

    }
    
    public func add(_ simComponent: NeuronModelProtocol) {
        simComponents.append(simComponent)
    }
    
    public func reset() {
        // TODO: stop the ongoing simulations
        simComponents.removeAll()
        wallTime = 0
    }
    
}
