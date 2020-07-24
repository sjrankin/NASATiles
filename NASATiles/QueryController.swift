//
//  QueryController.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/21/20.
//

import Foundation
import AppKit

class QueryController: NSViewController, NSTextViewDelegate, NSTextFieldDelegate
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        QueryTextBox.stringValue = ""
        ReturnedInfo.string = ""
        
        MapStatus.minValue = 0.0
        MapStatus.maxValue = 100.0
        MapStatus.doubleValue = 0.0
        
        HorizontalTileCount.stringValue = "20"
        VerticalTileCount.stringValue = "10"
        
        TileMatrixSetCombo.removeAllItems()
        TileMatrixSetCombo.addItem(withObjectValue: "15.125m")
        TileMatrixSetCombo.addItem(withObjectValue: "31.25m")
        TileMatrixSetCombo.addItem(withObjectValue: "250m")
        TileMatrixSetCombo.addItem(withObjectValue: "500m")
        TileMatrixSetCombo.addItem(withObjectValue: "750m")
        TileMatrixSetCombo.addItem(withObjectValue: "1km")
        TileMatrixSetCombo.addItem(withObjectValue: "2km")
        TileMatrixSetCombo.addItem(withObjectValue: "GoogleMapsCompatible_Level6")
        TileMatrixSetCombo.addItem(withObjectValue: "GoogleMapsCompatible_Level7")
        TileMatrixSetCombo.addItem(withObjectValue: "GoogleMapsCompatible_Level8")
        TileMatrixSetCombo.addItem(withObjectValue: "GoogleMapsCompatible_Level9")
        TileMatrixSetCombo.addItem(withObjectValue: "GoogleMapsCompatible_Level12")
        TileMatrixSetCombo.addItem(withObjectValue: "GoogleMapsCompatible_Level13")
        TileMatrixSetCombo.selectItem(at: 2)
        
        ZoomCombo.removeAllItems()
        ZoomCombo.addItem(withObjectValue: "3")
        ZoomCombo.addItem(withObjectValue: "4")
        ZoomCombo.addItem(withObjectValue: "5")
        ZoomCombo.addItem(withObjectValue: "6")
        ZoomCombo.addItem(withObjectValue: "7")
        ZoomCombo.addItem(withObjectValue: "8")
        ZoomCombo.addItem(withObjectValue: "9")
        ZoomCombo.addItem(withObjectValue: "12")
        ZoomCombo.addItem(withObjectValue: "13")
        ZoomCombo.selectItem(at: 0)
        
        LayerCombo.removeAllItems()
        LayerCombo.addItem(withObjectValue: "MODIS_Terra_CorrectedReflectance_TrueColor")
        LayerCombo.addItem(withObjectValue: "MODIS_Terra_CorrectedReflectance_Bands721")
        LayerCombo.addItem(withObjectValue: "MODIS_Terra_CorrectedReflectance_Bands367")
        LayerCombo.addItem(withObjectValue: "MODIS_Terra_SurfaceReflectance_Bands143")
        LayerCombo.addItem(withObjectValue: "MODIS_Aqua_CorrectedReflectance_TrueColor")
        LayerCombo.addItem(withObjectValue: "MODIS_Aqua_CorrectedReflectance_Bands721")
        LayerCombo.addItem(withObjectValue: "VIIRS_SNPP_CorrectedReflectance_TrueColor")
        LayerCombo.addItem(withObjectValue: "VIIRS_SNPP_CorrectedReflectance_BandsM11-I2-I1")
        LayerCombo.addItem(withObjectValue: "VIIRS_SNPP_CorrectedReflectance_BandsM3-I3-M11")
        LayerCombo.addItem(withObjectValue: "VIIRS_NOAA20_CorrectedReflectance_TrueColor")
        LayerCombo.addItem(withObjectValue: "VIIRS_NOAA20_CorrectedReflectance_BandsM11-I2-I1")
        LayerCombo.addItem(withObjectValue: "VIIRS_NOAA20_CorrectedReflectance_BandsM3-I3-M11")
        LayerCombo.addItem(withObjectValue: "VIIRS_SNPP_DayNightBand_ENCC")
        LayerCombo.selectItem(at: 0)
        
        HorizontalTileCount.stringValue = "20"
        VerticalTileCount.stringValue = "10"
        RowTextBox.stringValue = "0"
        RowStepper.integerValue = 0
        ColumnTextBox.stringValue = "0"
        ColumnStepper.integerValue = 0
        TypeSegment.selectedSegment = 0
        
        var DayComponent = DateComponents()
        DayComponent.day = -1
        let Cal = Calendar.current
        let Yesterday = Cal.date(byAdding: DayComponent, to: Date())
        DatePicker.dateValue = Yesterday!
        GenerateQuery()
    }
    
    @discardableResult func GenerateQuery(WithRow: Int? = nil, WithColumn: Int? = nil) -> String
    {
        var TileURL = "https://gibs.earthdata.nasa.gov/"
        
        switch ServiceSegment.selectedSegment
        {
            case 0:
                TileURL.append("wmts")
                
            case 1:
                TileURL.append("wms")
                
            case 2:
                TileURL.append("twms")
                
            default:
                TileURL.append("wmts")
        }
        TileURL.append("/")
        
        TileURL.append("epsg")
        switch EPSGSegment.selectedSegment
        {
            case 0:
                TileURL.append("4326")
                
            case 1:
                TileURL.append("3857")
                
            case 2:
                TileURL.append("3413")
                
            default:
                TileURL.append("4326")
        }
        TileURL.append("/")
        
        switch TypeSegment.selectedSegment
        {
            case 0:
                TileURL.append("best")
                
            case 1:
                TileURL.append("std")
                
            case 2:
                TileURL.append("nrt")
                
            case 3:
                TileURL.append("all")
                
            default:
                TileURL.append("best")
        }
        TileURL.append("/")
        
        let Layer = LayerCombo.objectValueOfSelectedItem as! String
        TileURL.append(Layer)
        TileURL.append("/")
        
        let TileDate = DatePicker.dateValue
        let Cal = Calendar.current
        let Year = Cal.component(.year, from: TileDate)
        let Month = Cal.component(.month, from: TileDate)
        var SMonth = "\(Month)"
        if Month < 10
        {
            SMonth = "0\(Month)"
        }
        let Day = Cal.component(.day, from: TileDate)
        var SDay = "\(Day)"
        if Day < 10
        {
            SDay = "0\(Day)"
        }
        let FinalDate = "default/\(Year)-\(SMonth)-\(SDay)/"
        TileURL.append(FinalDate)
        
        let Resolution = TileMatrixSetCombo.objectValueOfSelectedItem as! String
        TileURL.append(Resolution)
        TileURL.append("/")
        
        let Zoom = ZoomCombo.objectValueOfSelectedItem as! String
        TileURL.append(Zoom)
        TileURL.append("/")
        
        if let OtherRow = WithRow
        {
            TileURL.append("\(OtherRow)")
        }
        else
        {
            let RowVal = RowTextBox.stringValue
            TileURL.append(RowVal)
        }
        TileURL.append("/")
        
        if let OtherColumn = WithColumn
        {
            TileURL.append("\(OtherColumn)")
        }
        else
        {
            let ColVal = ColumnTextBox.stringValue
            TileURL.append(ColVal)
        }
        
        switch FormatSegment.selectedSegment
        {
            case 0:
                TileURL.append(".jpg")
                
            case 1:
                TileURL.append(".png")
                
            default:
                TileURL.append(".jpg")
        }
        
        QueryTextBox.stringValue = TileURL
        return TileURL
    }
    
    @IBAction func HandleRunQuery(_ sender: Any)
    {
        TileView.image = nil
        let QuerySource = QueryTextBox.stringValue
        ReturnedInfo.string = ""
        if let FinalURL = URL(string: QuerySource)
        {
            DispatchQueue.global(qos: .background).async
            {
                do
            {
                let Start = CACurrentMediaTime()
                let ImageData = try Data(contentsOf: FinalURL)
                let End = CACurrentMediaTime() - Start
                if let Image = NSImage(data: ImageData)
                {
                    OperationQueue.main.addOperation
                    {
                        self.TileView.image = Image
                        let Size = "\(Int(Image.size.width))x\(Int(Image.size.height))"
                        let TotalTime = Double(Int(End * 1000.0)) / 1000.0
                        let Results = "Loaded image in \(TotalTime) seconds. Image size is \(Size)"
                        self.ReturnedInfo.string = Results
                    }
                }
                else
                {
                    OperationQueue.main.addOperation
                    {
                        self.ReturnedInfo.string = "Error converting received data to image."
                    }
                }
            }
                catch
                {
                    OperationQueue.main.addOperation
                    {
                        self.ReturnedInfo.string = error.localizedDescription
                    }
                }
            }
        }
        else
        {
            ReturnedInfo.string = "Error creating URL from \(QuerySource)"
        }
    }
    
    @IBAction func HandleClosePressed(_ sender: Any)
    {
        self.view.window?.close()
    }
    
    @IBAction func HandleLayerComboChanged(_ sender: Any)
    {
        if let _ = sender as? NSComboBox
        {
            GenerateQuery()
        }
    }
    
    @IBAction func HandleTileMatrixChanged(_ sender: Any)
    {
        if let _ = sender as? NSComboBox
        {
            GenerateQuery()
        }
    }
    
    @IBAction func HandleZoomComboChanged(_ sender: Any)
    {
        if let _ = sender as? NSComboBox
        {
            GenerateQuery()
        }
    }
    
    @IBAction func HandleStepperAction(_ sender: Any)
    {
        if let Stepper = sender as? NSStepper
        {
            let StepperValue = Stepper.integerValue
            switch Stepper
            {
                case ColumnStepper:
                    ColumnTextBox.stringValue = "\(StepperValue)"
                    GenerateQuery()
                    break
                    
                case RowStepper:
                    RowTextBox.stringValue = "\(StepperValue)"
                    GenerateQuery()
                    
                default:
                    break
            }
        }
    }
    
    @IBAction func HandleDatePickerChanged(_ sender: Any)
    {
        if let _ = sender as? NSDatePicker
        {
            GenerateQuery()
        }
    }
    
    func GetIntFrom(_ Field: NSTextField, Default: Int = 0) -> Int
    {
        if let Value = Int(Field.stringValue)
        {
            return Value
        }
        return Default
    }
    
    func controlTextDidEndEditing(_ obj: Notification)
    {
        if let TextField = obj.object as? NSTextField
        {
            switch TextField
            {
                case ColumnTextBox:
                    GenerateQuery()
                    
                case RowTextBox:
                    GenerateQuery()
                    
                case QueryTextBox:
                    break
                    
                default:
                    break
            }
        }
    }
    
    @IBAction func HandleTypeSegmentChanged(_ sender: Any)
    {
        if let _ = sender as? NSSegmentedControl
        {
            GenerateQuery()
        }
    }
    
    @IBAction func HandleServiceSegmentChanged(_ sender: Any)
    {
        if let _ = sender as? NSSegmentedControl
        {
            GenerateQuery()
        }
    }
    
    @IBAction func HandleEPSGChanged(_ sender: Any)
    {
        if let _ = sender as? NSSegmentedControl
        {
            GenerateQuery()
        }
    }
    
    @IBAction func HandleFormatChanged(_ sender: Any)
    {
        if let _ = sender as? NSSegmentedControl
        {
            GenerateQuery()
        }
    }
    
    @IBAction func CreateMap(_ sender: Any)
    {
        MapStatus.doubleValue = 0.0
        DownloadCount = 0
        Results.removeAll()
        TileMap.removeAll()
        
        SetProgressIndicatorColor(To: NSColor.systemBlue)
        DownloadTiles()
        
        SetProgressIndicatorColor(To: NSColor.systemGreen)
    }
    
    var IsLocked: NSObject = NSObject()
    var Results = [(Row: Int, Column: Int, ID: UUID, Image: NSImage)]()
    var TileMap = [UUID: (Int, Int)]()
    var DownloadCount = 0
    
    func DownloadTiles()
    {
        let TilesX = GetIntFrom(HorizontalTileCount, Default: 20)
        let TilesY = GetIntFrom(VerticalTileCount, Default: 10)
        MapStatus.maxValue = Double(TilesY * TilesX)
        
        var TileURLs = [String]()
        for Row in 0 ..< TilesY
        {
            for Column in 0 ..< TilesX
            {
                let TileURL = GenerateQuery(WithRow: Row, WithColumn: Column)
                TileURLs.append(TileURL)
            }
        }
        
        DispatchQueue.global(qos: .background).async
        {
            var Index = 0
            for Row in 0 ..< TilesY
            {
                for Column in 0 ..< TilesX
                {
                    let QueryString = TileURLs[Index]
                    Index = Index + 1
                    if let Final = URL(string: QueryString)
                    {
                        self.GetTile(From: Final, Row: Row, Column: Column,
                                     TotalExpected: TilesX * TilesY,
                                     MaxRows: TilesY, MaxColumns: TilesX)
                    }
                }
            }
        }
    }
    
    func GetTile(From TileURL: URL, Row: Int, Column: Int, TotalExpected: Int,
                 MaxRows: Int, MaxColumns: Int)
    {
        DispatchQueue.global(qos: .background).async
        {
            do
            {
                let ImageData = try Data(contentsOf: TileURL)
                if let Image = NSImage(data: ImageData)
                {
                    objc_sync_enter(self.IsLocked)
                    defer{objc_sync_exit(self.IsLocked)}
                    let ID = UUID()
                    self.Results.append((Row, Column, ID, Image))
                    self.TileMap[ID] = (Row, Column)
                    self.DownloadCount = self.DownloadCount + 1
                    OperationQueue.main.addOperation
                    {
                        self.MapStatus.doubleValue = Double(self.DownloadCount)
                    }
                    //print("Downloaded: \(self.DownloadCount) of \(TotalExpected)")
                    if self.DownloadCount == TotalExpected
                    {
                        print("Received expected number (\(TotalExpected)) of tiles.")
                        self.CreateMapFromTiles(TilesX: MaxColumns, TilesY: MaxRows)
                    }
                }
            }
            catch
            {
                print("Error returned for row \(Row), column \(Column): \(error)")
            }
        }
    }
    
    func CreateMapFromTiles(TilesX: Int, TilesY: Int)
    {
        print("Map size: \(TilesX)x\(TilesY)")
        SetProgressIndicatorColor(To: NSColor.systemGreen)
        OperationQueue.main.addOperation
        {
            self.MapStatus.doubleValue = 0.0
        }
        
        for Result in Results
        {
            if let _ = TileMap[Result.ID]
            {
                TileMap.removeValue(forKey: Result.ID)
            }
        }
        if TileMap.count > 0
        {
            for (_, (Row, Column)) in TileMap
            {
                print("Missing tile at row \(Row), column \(Column)")
            }
        }

        DispatchQueue.global(qos: .background).async
        {
            var Count = 0
            let TileSize = 128
            let BackgroundHeight = TilesY * TileSize
            let BackgroundWidth = TilesX * TileSize
            var Background = NSImage(size: NSSize(width: BackgroundWidth / 2, height: BackgroundHeight / 2))
            Background.lockFocus()
            NSColor.systemYellow.drawSwatch(in: NSRect(origin: .zero, size: Background.size))
            Background.unlockFocus()
            Background = self.ResizeImage(Image: Background, Longest: CGFloat(TilesX * TileSize))
            autoreleasepool
            {
                for (Row, Column, _, Tile) in self.Results
                {
                    let FinalTileY = (TilesY - Row) - 1
                    let Point = NSPoint(x: Column * TileSize, y: FinalTileY * TileSize)
                    let ReducedTile = self.ResizeImage(Image: Tile, Longest: CGFloat(TileSize))
                    Background = self.BlitImage(ReducedTile, On: Background, At: Point)!
                    Count = Count + 1
                        OperationQueue.main.addOperation
                        {
                            self.MapStatus.doubleValue = Double(Count)
                        }
                }
            }
            OperationQueue.main.addOperation
            {
                self.MapStatus.doubleValue = 0.0
                let Storyboard = NSStoryboard(name: "Main", bundle: nil)
                if let WindowController = Storyboard.instantiateController(withIdentifier: "MapViewWindow") as? MapViewWindow
                {
                    if let Controller = WindowController.contentViewController as? MapViewController
                    {
                        Controller.ShowImage(Background)
                        WindowController.showWindow(nil)
                    }
                }
            }
        }
    }
    
    func BlitImage(_ Tile: NSImage, On Background: NSImage, At Point: NSPoint) -> NSImage?
    {
        autoreleasepool
        {
            let CIBGImg = Background.tiffRepresentation
            let BGImg = CIImage(data: CIBGImg!)
            let Offscreen = NSBitmapImageRep(ciImage: BGImg!)
            guard let Context = NSGraphicsContext(bitmapImageRep: Offscreen) else
            {
                return nil
            }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = Context
            Tile.draw(at: Point, from: NSRect(origin: .zero, size: Tile.size),
                      operation: .sourceAtop, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            let Final = NSImage(size: Background.size)
            Final.addRepresentation(Offscreen)
            return Final
        }
    }
    
    public func ResizeImage(Image: NSImage, Longest: CGFloat) -> NSImage
    {
        let ImageMax = max(Image.size.width, Image.size.height)
        if ImageMax <= Longest
        {
            return Image
        }
        let Ratio = Longest / ImageMax
        let NewSize = NSSize(width: Image.size.width * Ratio, height: Image.size.height * Ratio)
        let NewImage = NSImage(size: NewSize)
        NewImage.lockFocus()
        Image.draw(in: NSMakeRect(0, 0, NewSize.width, NewSize.height),
                   from: NSMakeRect(0, 0, Image.size.width, Image.size.height),
                   operation: NSCompositingOperation.sourceOver,
                   fraction: CGFloat(1))
        NewImage.unlockFocus()
        NewImage.size = NewSize
        return NewImage
    }
    
    func SetProgressIndicatorColor(To Color: NSColor)
    {
        OperationQueue.main.addOperation
        {
        let FinalColor = CIColor(color: Color)
        let MonoColor = CIFilter(name: "CIColorMonochrome", parameters: [kCIInputColorKey: FinalColor as Any])
            self.MapStatus.contentFilters = [MonoColor!]
        }
    }
    
    @IBOutlet weak var VerticalTileCount: NSTextField!
    @IBOutlet weak var HorizontalTileCount: NSTextField!
    @IBOutlet weak var FormatSegment: NSSegmentedControl!
    @IBOutlet weak var EPSGSegment: NSSegmentedControl!
    @IBOutlet weak var ServiceSegment: NSSegmentedControl!
    @IBOutlet weak var MapStatus: NSProgressIndicator!
    @IBOutlet weak var TypeSegment: NSSegmentedControl!
    @IBOutlet weak var ColumnStepper: NSStepper!
    @IBOutlet weak var DatePicker: NSDatePicker!
    @IBOutlet weak var ColumnTextBox: NSTextField!
    @IBOutlet weak var RowStepper: NSStepper!
    @IBOutlet weak var RowTextBox: NSTextField!
    @IBOutlet weak var ZoomCombo: NSComboBox!
    @IBOutlet weak var TileMatrixSetCombo: NSComboBox!
    @IBOutlet weak var LayerCombo: NSComboBox!
    @IBOutlet weak var QueryTextBox: NSTextField!
    @IBOutlet var ReturnedInfo: NSTextView!
    @IBOutlet weak var TileView: NSImageView!
}
