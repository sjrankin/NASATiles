//
//  ViewController.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/21/20.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        StatusLabel.stringValue = ""
        LoadedTiles = Array(repeating: Array(repeating: TileClass(), count: Columns), count: Rows)
    }
    
    override func viewDidLayout()
    {
        MainWindow = view.window?.windowController as? MainViewWindow
    }
    
    var MainWindow: MainViewWindow? = nil
    
    var TileMap = [UUID: (Int, Int)]()
    
    let Rows = 10//5
    let Columns = 20//10
    
    var LoadedTiles = [[TileClass]]()
    
    func TileDownloaded(Done: Bool, Row: Int, Column: Int, Image: NSImage?, TileURL: URL?)
    {
        if let Tile = Image
        {
            Results.append((Row, Column, UUID(), Tile))
            LoadedTiles[Row][Column].WasLoaded = true
            LoadedTiles[Row][Column].TileURL = TileURL
        }
        OperationQueue.main.addOperation
        {
            if let Main = self.MainWindow
            {
                let OldValue = Main.MainStatus.doubleValue
                let NewValue = OldValue + 1.0
                Main.MainStatus.doubleValue = NewValue
            }
//            self.ReloadTable()
        }
        if Done
        {
            print("Done called")
            OperationQueue.main.addOperation
            {
                self.ReloadTable()
            }
        }
    }
    
    override var representedObject: Any?
    {
        didSet
        {
            // Update the view, if already loaded.
        }
    }
    
    var Results = [(Row: Int, Column: Int, ID: UUID, Image: NSImage)]()
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return Results.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 98.0
    }
    
    func ReloadTable()
    {
        ItemIndex = 0
        ResultTable.reloadData()
    }
    
    var ItemIndex = 0
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        var CellContents = ""
        var CellIdentifier = ""
        
        if tableColumn == tableView.tableColumns[0]
        {
            CellIdentifier = "ItemColumn"
            CellContents = "\(row)"
        }
        if tableColumn == tableView.tableColumns[1]
        {
            CellIdentifier = "RowColumn"
            CellContents = "\(Results[row].Row)"
        }
        if tableColumn == tableView.tableColumns[2]
        {
            CellIdentifier = "ColumnColumn"
            CellContents = "\(Results[row].Column)"
        }
        if tableColumn == tableView.tableColumns[4]
        {
            let IView = NSImageView(frame: NSRect(x: 1, y: 1, width: 96, height: 96))
            IView.image = Results[row].Image
            return IView
        }
        
        let Cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CellIdentifier), owner: self) as? NSTableCellView
        Cell?.textField?.stringValue = CellContents
        return Cell
    }
    
    var StartTime: Double = 0
    
    /// Download tiles for the specified satellite and date.
    /// - Note: Control returns immediately as the tiles are downloaded in the background.
    /// - Parameter For: Determines the satellite and wavelengths.
    /// - Parameter ForDate: The date for which the tiles are desired.
    /// - Parameter Completed: Completion handler. Called when each tile is downloaded and when all tiles are
    ///                        downloaded. Parameters are All downloaded (true if all downloaded, false if not),
    ///                        Tile row, Tile column, Tile image. The Tile image is set to nil if all tiles
    ///                        have been downloaded. When completed the Tile Row is set to the expected row count and
    ///                        the Tile Column is set to the expected column count.
    func DownloadTiles(ForDate: Date, Completed: ((Bool, Int, Int, NSImage?, URL?) -> ())? = nil)
    {
        DownloadCount = 0
        if MainWindow == nil
        {
            print("MainWindow is nil")
        }
        MainWindow?.MainStatus.minValue = 0.0
        MainWindow?.MainStatus.maxValue = Double(Rows * Columns - 1)
        MainWindow?.SetProgressColor(To: NSColor.systemBlue)
        DispatchQueue.global(qos: .background).async
        {
            self.DownloadCompletionHandler = Completed
            //max column is 79
            //max row is 39
            self.StartTime = CACurrentMediaTime()
            for Row in 0 ..< self.Rows
            {
                for Column in 0 ..< self.Columns
                {
                    var TileURL = "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/"
                    
                    TileURL.append("MODIS_Terra_CorrectedReflectance_TrueColor")
//                    TileURL.append("VIIRS_SNPP_DayNightBand_ENCC")
                    let EarthDate = "2020-07-17"//self.MakeEarthDate(From: ForDate)
                    let TileMatrix = "4"
                    let TileRow = "\(Row)"
                    let TileColumn = "\(Column)"
                    TileURL.append("/default/\(EarthDate)/250m/\(TileMatrix)/\(TileRow)/\(TileColumn).jpg")
                    if let FinalURL = URL(string: TileURL)
                    {
                        OperationQueue.main.addOperation
                        {
                            self.StatusLabel.stringValue = "Getting tile at \(FinalURL.path)"
                        }
                        self.GetTile(From: FinalURL, Row: Row, Column: Column, TotalExpected: (self.Rows) * (self.Columns),
                                     MaxRows: self.Rows, MaxColumns: self.Columns)
                    }
                }
            }
        }
    }
    
    var DownloadCount: Int = 0
    var IsLocked: NSObject = NSObject()
    
    /// Get a single image tile at the specificed URL.
    /// - Parameter From: The URL of the tile to retrieve.
    /// - Parameter Row: The row index of the tile.
    /// - Parameter Column: The column index of the tile.
    /// - Parameter TotalExpected: The number of expected tiles to receive.
    /// - Parameter MaxRows: The maximum number of rows.
    /// - Parameter MaxColumns: The maximum number of columns.
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
                    #if true
                    objc_sync_enter(self.IsLocked)
                    defer{objc_sync_exit(self.IsLocked)}
                    let ID = UUID()
                    self.Results.append((Row, Column, ID, Image))
                    self.TileMap[ID] = (Row, Column)
                    self.DownloadCount = self.DownloadCount + 1
                    if let Main = self.MainWindow
                    {
                        OperationQueue.main.addOperation
                        {
                        Main.MainStatus.doubleValue = Double(self.DownloadCount)
                        }
                    }
                    if self.DownloadCount == TotalExpected
                    {
                        OperationQueue.main.addOperation
                        {
                            if let Main = self.MainWindow
                            {
                                Main.MainStatus.doubleValue = 0.0
                            }
                            self.ReloadTable()
                        }
                    }
                    #else
                    self.DownloadCount = self.DownloadCount + 1
                    //self.CurrentTiles.append(Image)
                    if let Handler = self.DownloadCompletionHandler
                    {
                        Handler(false, Row, Column, Image, TileURL)
                    }
                    if self.DownloadCount == TotalExpected
                    {
                        let LoadSeconds = CACurrentMediaTime() - self.StartTime
                        OperationQueue.main.addOperation
                        {
                            self.StatusLabel.stringValue = "Load time for all tiles: \(LoadSeconds) seconds"
                        }
                        if let Handler = self.DownloadCompletionHandler
                        {
                            Handler(true, MaxRows, MaxColumns, nil, nil)
                        }
                    }
                    #endif
                }
            }
            catch
            {
                print("Error returned for row \(Row), column \(Column): \(error)")
            }
        }
    }
    
    var DownloadCompletionHandler: ((Bool, Int, Int, NSImage?, URL?) -> ())? = nil
    
    /// Convert the passed `Date` into a calendar date to be used for returning Earth time data from NASA.
    /// - Parameter From: The `Date` to convert.
    /// - Returns: String in the format `YYYY-MM-DD`.
    public  func MakeEarthDate(From Raw: Date) -> String
    {
        let Cal = Calendar.current
        let Year = Cal.component(.year, from: Raw)
        let Month = Cal.component(.month, from: Raw)
        let Day  = Cal.component(.day, from: Raw)
        let YearS = "\(Year)"
        var MonthS = "\(Month)"
        if MonthS.count == 1
        {
            MonthS = "0" + MonthS
        }
        var DayS = "\(Day)"
        if DayS.count == 1
        {
            DayS = "0" + DayS
        }
        return "\(YearS)-\(MonthS)-\(DayS)"
    }
    
    @IBAction func StartDownloadSet(_ sender: Any)
    {
        TileMap.removeAll()
        DownloadCount = 0
        MainWindow?.MainStatus.doubleValue = 0.0
        LoadedTiles = Array(repeating: Array(repeating: TileClass(), count: Columns), count: Rows)
        Results.removeAll()
        ResultTable.reloadData()
        DownloadTiles(ForDate: Date(), Completed: TileDownloaded(Done:Row:Column:Image:TileURL:))
    }
    
    @IBAction func RunQueryEditor(_ sender: Any)
    {
        let Storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let WindowController = Storyboard.instantiateController(withIdentifier: "QueryWindow") as? QueryWindow
        {
            WindowController.showWindow(nil)
        }
    }
    
    @IBAction func CreateMap(_ sender: Any)
    {
        if Results.count < 1
        {
            StatusLabel.stringValue = "No results available"
            return
        }
        MakeImageMap()
    }
    
    func MakeImageMap()
    {
        #if true
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
        #else
        for Y in 0 ..< Rows
        {
            for X in 0 ..< Columns
            {
                let TileLoadData = LoadedTiles[Y][X]
                if !TileLoadData.WasLoaded
                {
                    print("Tile at \(X),\(Y) not loaded.")
                }
            }
        }
        #endif
        MainWindow?.SetProgressColor(To: NSColor.green)
        MainWindow?.MainStatus.maxValue = Double(Results.count)
        DispatchQueue.global(qos: .background).async
        {
            var Count = 0
            let TileSize = 128
            let BackgroundHeight = self.Rows * TileSize
            let BackgroundWidth = self.Columns * TileSize
            var Background = NSImage(size: NSSize(width: BackgroundWidth / 2, height: BackgroundHeight / 2))
            Background.lockFocus()
            NSColor.systemYellow.drawSwatch(in: NSRect(origin: .zero, size: Background.size))
            Background.unlockFocus()
            Background = self.ResizeImage(Image: Background, Longest: CGFloat(self.Columns * TileSize))
            autoreleasepool
            {
                for (Row, Column, _, Tile) in self.Results
                {
                    //print("Adding tile at \(Column),\(Row)")
                    OperationQueue.main.addOperation
                    {
                        self.StatusLabel.stringValue = "Adding tile (\(Column),\(Row))"
                    }
                    let TileY = (self.Rows - Row) - 1
                    let Point = NSPoint(x: Column * TileSize, y: TileY * TileSize)
                    let ReducedTile = self.ResizeImage(Image: Tile, Longest: CGFloat(TileSize))
                    Background = self.BlitImage(ReducedTile, On: Background, At: Point)!
                    Count = Count + 1
                    if let Main = self.MainWindow
                    {
                        OperationQueue.main.addOperation
                        {
                    Main.MainStatus.doubleValue = Double(Count)
                        }
                    }
                }
            }
            OperationQueue.main.addOperation
            {
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
    
    /// Resizes an NSImage such that the longest dimension of the returned image is `Longest`. If the
    /// image is smaller than `Longest`, it is *not* resized.
    /// - Parameter Image: The image to resize.
    /// - Parameter Longest: The new longest dimension.
    /// - Returns: Resized image. If the longest dimension of the original image is less than `Longest`, the
    ///            original image is returned unchanged.
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
    
    @IBOutlet weak var StatusLabel: NSTextField!
    @IBOutlet weak var ResultTable: NSTableView!
}

class TileClass
{
    init()
    {
        TileURL = nil
        WasLoaded = false
    }
    
    init(_ TileURL: URL, WasLoaded: Bool)
    {
        self.TileURL = TileURL
        self.WasLoaded = WasLoaded
    }
    
    var TileURL: URL? = nil
    var WasLoaded: Bool = false
}
