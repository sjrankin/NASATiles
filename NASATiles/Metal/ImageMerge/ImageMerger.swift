//
//  ImageMerger.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/24/20.
//

import Foundation
import AppKit
import MetalKit
import Metal
import CoreGraphics

class ImageMerger
{
    private let ImageDevice = MTLCreateSystemDefaultDevice()
    private var ImageComputePipelineState: MTLComputePipelineState? = nil
    private lazy var ImageCommandQueue: MTLCommandQueue? =
        {
            return self.ImageDevice?.makeCommandQueue()
        }()
    
    init()
    {
        let DefaultLibrary = ImageDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "ImageMergeKernel")
        do
        {
            ImageComputePipelineState = try ImageDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Error creating pipeline state: \(error.localizedDescription)")
        }
    }
    
    /// Merge a smaller image with a larger image.
    /// - Parameter Tile: The smaller image to place on top of the larger image.
    /// - Parameter At: Tuple (X, Y) that tells where to place the smaller image on the larger image.
    /// - Parameter With: The larger image.
    /// - Returns: Merged image on success, nil on error.
    func Merge(Tile: NSImage, At: (X: Int, Y: Int), With Background: NSImage) -> NSImage?
    {
        let TargetTexture = MetalLibrary.MakeEmptyTexture(Size: Background.size,
                                                          ImageDevice: ImageDevice!,
                                                          ForWriting: true)
        var AdjustedTile: CGImage? = nil
        let TileTexture = MetalLibrary.MakeTexture(From: Tile, ImageDevice: ImageDevice!, AsCG: &AdjustedTile)
        var AdjustedBG: CGImage? = nil
        let BGTexture = MetalLibrary.MakeTexture(From: Background, ForWriting: true,
                                                 ImageDevice: ImageDevice!, AsCG: &AdjustedBG)
        
        let Parameter = ImageMergeParameters(ImageCount: 1,
                                             XOffset: simd_uint1(At.X),
                                             YOffset: simd_uint1(At.Y),
                                             TileWidth: simd_uint1(TileTexture!.width),
                                             TileHeight: simd_uint1(TileTexture!.height),
                                             BackgroundWidth: simd_uint1(BGTexture!.width),
                                             BackgroundHeight: simd_uint1(BGTexture!.height))
        print("Parameter=\(Parameter)")
        let Parameters = [Parameter]
        let ParameterBuffer = ImageDevice!.makeBuffer(length: MemoryLayout<ImageMergeParameters>.stride, options: [])
        memcpy(ParameterBuffer!.contents(), Parameters, MemoryLayout<ImageMergeParameters>.stride)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(BGTexture, index: 0)
        CommandEncoder?.setTexture(TileTexture, index: 1)
        CommandEncoder?.setBuffer(ParameterBuffer, offset: 0, index: 0)
        
        let w = ImageComputePipelineState!.threadExecutionWidth
        let h = ImageComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadGroupCount = MTLSizeMake(w, h, 1)
        let ThreadGroups = MTLSize(width: BGTexture!.width, height: BGTexture!.height, depth: 1)
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        CommandEncoder?.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder?.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        let ImageSize = CGSize(width: BGTexture!.width, height: BGTexture!.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = (AdjustedBG?.bytesPerRow)!
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        TargetTexture!.getBytes(&ImageBytes, bytesPerRow: BytesPerRow, from: ORegion, mipmapLevel: 0)
        
        let CIOptions = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                         CIContextOption.outputPremultiplied: true,
                         CIContextOption.useSoftwareRenderer: false] as! [CIImageOption: Any]
        let CImg = CIImage(mtlTexture: BGTexture!, options: CIOptions)
        let CImgRep = NSCIImageRep(ciImage: CImg!)
        let Final = NSImage(size: ImageSize)
        Final.addRepresentation(CImgRep)
        return Final
    }

    /// Merge a smaller image with a larger image.
    /// - Parameter Tile: The smaller image to place on top of the larger image.
    /// - Parameter At: Tuple (X, Y) that tells where to place the smaller image on the larger image.
    /// - Parameter With: The larger image.
    /// - Returns: Merged image on success, nil on error.
    func Merge(Tiles: [PlottingTile], Background: NSImage) -> NSImage?
    {
        #if false
        let TargetTexture = MetalLibrary.MakeEmptyTexture(Size: Background.size,
                                                          ImageDevice: ImageDevice!,
                                                          ForWriting: true)
        var AdjustedTile: CGImage? = nil
        let TileTexture = MetalLibrary.MakeTexture(From: Tile, ImageDevice: ImageDevice!, AsCG: &AdjustedTile)
        var AdjustedBG: CGImage? = nil
        let BGTexture = MetalLibrary.MakeTexture(From: Background, ForWriting: false,
                                                 ImageDevice: ImageDevice!, AsCG: &AdjustedBG)
        
        let Parameter = ImageMergeParameters(ImageCount: 1,
                                             XOffset: simd_uint1(At.X),
                                             YOffset: simd_uint1(At.Y),
                                             TileWidth: simd_uint1(TileTexture!.width),
                                             TileHeight: simd_uint1(TileTexture!.height),
                                             BackgroundWidth: simd_uint1(BGTexture!.width),
                                             BackgroundHeight: simd_uint1(BGTexture!.height))
        print("Parameter=\(Parameter)")
        let Parameters = [Parameter]
        let ParameterBuffer = ImageDevice!.makeBuffer(length: MemoryLayout<ImageMergeParameters>.stride, options: [])
        memcpy(ParameterBuffer!.contents(), Parameters, MemoryLayout<ImageMergeParameters>.stride)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(BGTexture, index: 0)
        CommandEncoder?.setTexture(TileTexture, index: 1)
        CommandEncoder?.setTexture(TargetTexture, index: 2)
        CommandEncoder?.setBuffer(ParameterBuffer, offset: 0, index: 0)
        
        let ThreadGroupCount = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(BGTexture!.width / ThreadGroupCount.width,
                                       BGTexture!.height / ThreadGroupCount.height,
                                       1)
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        CommandEncoder?.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder?.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        let ImageSize = CGSize(width: TargetTexture!.width, height: TargetTexture!.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = (AdjustedBG?.bytesPerRow)!
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        TargetTexture!.getBytes(&ImageBytes, bytesPerRow: BytesPerRow, from: ORegion, mipmapLevel: 0)
        
        let CIOptions = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                         CIContextOption.outputPremultiplied: true,
                         CIContextOption.useSoftwareRenderer: false] as! [CIImageOption: Any]
        let CImg = CIImage(mtlTexture: TargetTexture!, options: CIOptions)
        let CImgRep = NSCIImageRep(ciImage: CImg!)
        let Final = NSImage(size: ImageSize)
        Final.addRepresentation(CImgRep)
        return Final
        #else
        return nil
        #endif
    }
}

class PlottingTile
{
    init(_ X: Int, _ Y: Int, Tile: NSImage)
    {
        self.X = X
        self.Y = Y
        self.Tile = Tile
    }
    
    var X: Int = 0
    var Y: Int = 0
    var Tile: NSImage = NSImage()
}
