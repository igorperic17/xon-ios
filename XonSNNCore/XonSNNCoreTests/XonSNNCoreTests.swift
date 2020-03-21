//
//  XonSNNCoreTests.swift
//  XonSNNCoreTests
//
//  Created by Igor Peric on 3/13/20.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import XCTest
@testable import XonSNNCore

class XonSNNCoreTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        
        let engine = SimulationEngine()
        let neuron = LIFNeuron(inV: 30, outV: 50, V: 30, leakV: 1, spikeV: 70, restV: 30)
        engine.add(neuron)
        
        for _ in 1...100 {
            neuron.injectSingleSpike()
            engine.run(10)
            
            print(neuron.getV())
        }
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
