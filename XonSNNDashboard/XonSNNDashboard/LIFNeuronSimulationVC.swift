//
//  FirstViewController.swift
//  XonSNNDashboard
//
//  Created by Igor Peric on 3/13/20.
//  Copyright © 2020 Xon.ai. All rights reserved.
//

import UIKit
import Charts
import XonSNNCore

class LIFNeuronSimulationVC: UIViewController {
    
    @IBOutlet weak var spikeChartView: LineChartView!
    @IBOutlet weak var voltageChartView: LineChartView!
    
    var spikeTimes = [Double]()
    var voltages = [(Double, Double)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // run simulation
        
        let engine = SimulationEngine()
        let neuron = LIFNeuron(inV: 100, outV: 50, V: 30, leakC: 0.05, spikeV: 70, restV: 30)
        engine.add(neuron)
        neuron.delegate = self
        
        for i in 0...100 {
            if i % 30 == 0 {
                neuron.injectSingleSpike()
            }
            engine.run(1)
            
            print(neuron.getV())
        }
        
        // plot voltage
        voltages = neuron.getVoltageHistory()
        var voltageDataEntry = [ChartDataEntry]()
        for voltageEntry in voltages {
            let timestamp = voltageEntry.0
            let voltage = voltageEntry.1
            voltageDataEntry.append(ChartDataEntry(x: timestamp, y: voltage))
        }
        let voltageDataset = LineChartDataSet(entries: voltageDataEntry, label: "Voltage")
        voltageDataset.drawIconsEnabled = true
        voltageDataset.setColor(.black)
        
        voltageDataset.drawIconsEnabled = false
        
//        voltageDataset.lineDashLengths = [5, 2.5]
        voltageDataset.highlightLineDashLengths = [5, 2.5]
        voltageDataset.setColor(.black)
        voltageDataset.setCircleColor(.black)
        voltageDataset.lineWidth = 1
        voltageDataset.circleRadius = 1
        voltageDataset.drawCircleHoleEnabled = false
//        voltageDataset.valueFont = .systemFont(ofSize: 9)
////        voltageDataset.formLineDashLengths = [5, 2.5]
//        voltageDataset.formLineWidth =
//        voltageDataset.formSize = 15
        
        let gradientColors = [ChartColorTemplates.colorFromString("#00ff0000").cgColor,
                              ChartColorTemplates.colorFromString("#ffff0000").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        voltageDataset.fillAlpha = 1
        voltageDataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        voltageDataset.drawFilledEnabled = false
        
        let voltageData = LineChartData(dataSet: voltageDataset)
        
        voltageChartView.data = voltageData
        
        
        // plot spikes
        var spikes = [ChartDataEntry]()
        for (_, spikeTime) in spikeTimes.enumerated() {
            spikes.append(ChartDataEntry(x: spikeTime, y: 1.0))
        }
        let scatterSpikes = ScatterChartDataSet(entries: spikes, label: "Spike times")
        scatterSpikes.drawIconsEnabled = true
        scatterSpikes.scatterShapeSize = 5
        scatterSpikes.setColor(.black)
        scatterSpikes.setScatterShape(.circle)
        let spikeData = ScatterChartData(dataSet: scatterSpikes)
        spikeData.setDrawValues(false)
        
        spikeChartView.data = spikeData
        
        spikeChartView.xAxis.axisRange = voltageChartView.xAxis.axisRange
    }
}

extension LIFNeuronSimulationVC: NeuronModelDelegate {
    func neuronSpiked(_ neuron: NeuronModelProtocol, atTimestamp timestamp: Double) {
        spikeTimes.append(timestamp)
    }
}


