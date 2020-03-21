//
//  LIFNeuron.swift
//  XonSNNCore
//
//  Created by Igor Peric on 3/13/20.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import Foundation

public class LIFNeuron {
    
    private var neuronDelegate: NeuronModelDelegate?
    
    private let inV: Double! // input spike strength in mV
    private let outV: Double! // output spike strength in mV
    private var V: Double! // current membrane action potential
    private let leakC: Double! // leak constant - the percentage of mV difference between restV and V which is leaked each ms
    private let spikeV: Double! // spike threashold - neuron will fire when it reaches this voltage
    private let restV: Double! // resting membrane potential
    
    private var voltageHistory = [(Double, Double)]()
    
    public func getV() -> Double {
        return V
    }
    
    public func getVoltageHistory() -> [(Double, Double)] {
        return voltageHistory
    }
    
    public init(inV: Double = 10, outV: Double = 50, V: Double = 30, leakC: Double = 0.1, spikeV: Double = 70, restV: Double = 30) {
        self.inV = inV
        self.outV = outV
        self.V = V
        self.leakC = leakC
        self.spikeV = spikeV
        self.restV = restV
    }
}

extension LIFNeuron: NeuronModelProtocol {
    
    
    public var delegate: NeuronModelDelegate? {
        get { return neuronDelegate }
        set { neuronDelegate = newValue }
    }
    
    public func step(_ length: Double, _ wallTime: Double) {
        // leak the voltage
        let leakAmount = leakC * (V - restV)
        V -= leakAmount * length
        
        // save the voltage for the historical overview
        voltageHistory.append((wallTime, V))
        
        if V >= spikeV {
            // dispatch spike
            delegate?.neuronSpiked(self, atTimestamp: wallTime)
            V = -restV
        }
    }
    
    public func injectSingleSpike() {
        V += inV // add fixed amount of 10 mV instantenously
    }
    
}
