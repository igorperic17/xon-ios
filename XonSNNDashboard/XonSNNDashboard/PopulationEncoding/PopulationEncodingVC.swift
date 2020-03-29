//
//  PopulationEncodingVC.swift
//  XonSNNDashboard
//
//  Created by  Igor Peric on 28/03/2020.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import Foundation
import XonSNNCore
import MetalKit

class PopulationEncodingVC: UIViewController {
    
    var renderer: XonPipeline?
    
    var mtkView: MTKView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.device = MTLCreateSystemDefaultDevice()
//        
//        renderer = XonPipeline.init(withMetalKitView: view)
    }
}

//@implementation AAPLViewController
//{
//    __weak IBOutlet MTKView *_view;
//
//    AAPLRenderer *_renderer;
//}

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//
//    _view.device = MTLCreateSystemDefaultDevice();
//
//    NSAssert(_view.device, @"Metal is not supported on this device");
//
//    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];
//    _renderer = [[XonPipeline alloc]
//
//    NSAssert(_renderer, @"Renderer failed initialization");
//
//    // Initialize our renderer with the view size
//    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
//
//    _view.delegate = _renderer;
//}

