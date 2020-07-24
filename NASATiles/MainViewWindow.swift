//
//  MainViewWindow.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/23/20.
//

import Foundation
import AppKit

class MainViewWindow: NSWindowController
{
    override func windowDidLoad()
    {
        super.windowDidLoad()
        MainStatus.minValue = 0.0
        MainStatus.maxValue = 100.0
        MainStatus.doubleValue = 0.0
    }
    
    func SetProgressColor(To Color: NSColor)
    {
        let MonoColor = CIFilter(name: "CIColorMonochrome", parameters: [kCIInputColorKey: CIColor(color: Color) as Any])
        MainStatus.contentFilters = [MonoColor!]
    }
    
    @IBOutlet weak var MainStatus: NSProgressIndicator!
}
