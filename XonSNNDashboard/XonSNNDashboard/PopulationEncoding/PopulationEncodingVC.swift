//
//  PopulationEncodingVC.swift
//  XonSNNDashboard
//
//  Created by  Igor Peric on 28/03/2020.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import UIKit
import Foundation
import XonSNNCore
import MetalKit

class PopulationEncodingVC: UIViewController {
    
    var computePipeline: XonPipeline!
    
    @IBOutlet weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        computePipeline = XonPipeline.init()
        
        // create compute graph
        let myLayer = XonLayer.init(withNeuronModel: "grayscaleKernel", onComputePipeline: computePipeline)
        computePipeline.addLayer(myLayer)
        
        // define visualization
        myLayer.setRenderTarget(mtkView)
        
        computePipeline.run()
        
//        computePipeline.stop()
    }
    
}
