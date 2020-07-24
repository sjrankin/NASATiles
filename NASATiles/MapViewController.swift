//
//  MapViewController.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/22/20.
//

import Foundation
import AppKit

class MapViewController: NSViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    func ShowImage(_ Image: NSImage)
    {
        ImageOut.image = Image
        GlobalImage = Image
    }
    
    var GlobalImage: NSImage? = nil
    {
        didSet
        {
            SaveButton.isEnabled = true
        }
    }
    
    @IBAction func HandleSaveButton(_ sender: Any)
    {
        let SavePanel = NSSavePanel()
        SavePanel.showsTagField = true
        SavePanel.title = "Save Map Image"
        SavePanel.allowedFileTypes = ["png", "jpg"]
        SavePanel.canCreateDirectories = true
        SavePanel.nameFieldStringValue = "Tile Map.png"
        SavePanel.level = .modalPanel
        if SavePanel.runModal() == .OK
        {
            if let FinalImage = GlobalImage
            {
                FinalImage.WritePNG(ToURL: SavePanel.url!)
            }
        }
    }
    
    @IBAction func HandleCloseButton(_ sender: Any)
    {
        self.view.window?.close()
    }
    
    @IBOutlet weak var SaveButton: NSButton!
    @IBOutlet weak var ImageOut: NSImageView!
}

extension NSImage
{
   @discardableResult public func WritePNG(ToURL: URL) -> Bool
    {
        guard let Data = tiffRepresentation,
              let Rep = NSBitmapImageRep(data: Data),
              let ImgData = Rep.representation(using: .png, properties: [.compressionFactor: NSNumber(floatLiteral: 1.0)]) else
        {
            print("Error getting data for image to save.")
            return false
        }
        do
        {
            try ImgData.write(to: ToURL)
        }
        catch
        {
            print("Error writing data: \(error.localizedDescription)")
            return false
        }
        return true
    }
}
