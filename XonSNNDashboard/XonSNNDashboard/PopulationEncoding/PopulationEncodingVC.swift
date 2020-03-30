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
    
    var renderer: XonPipeline?
    
    @IBOutlet weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        renderer = XonPipeline.init(withMetalKitView: mtkView)
        
        renderer?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        mtkView.delegate = renderer
    }
    
}
