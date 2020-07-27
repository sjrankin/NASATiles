//
//  ImageFlipper.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/26/20.
//

import Foundation
import AppKit
import simd
import Metal
import MetalKit
import CoreImage

class ImageFlipper
{
    private let ImageDevice = MTLCreateSystemDefaultDevice()
    private var ImageComputePipelineState: MTLComputePipelineState? = nil
    private lazy var ImageCommandQueue: MTLCommandQueue? =
        {
            return self.ImageDevice?.makeCommandQueue()
        }()
    
    func FlipVertically(Source: NSImage) -> NSImage?
    {
        return DoFlip(Source: Source, FunctionName: "ImageFlipVertical")
    }
    
    func FlipHorizontally(Source: NSImage) -> NSImage?
    {
        return DoFlip(Source: Source, FunctionName: "ImageFlipHorizontal")
    }
    
    func FlipBoth(Source: NSImage) -> NSImage?
    {
        return DoFlip(Source: Source, FunctionName: "ImageFlipBoth")
    }
    
    func DoFlip(Source: NSImage, FunctionName: String) -> NSImage?
    {
        let DefaultLibrary = ImageDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: FunctionName)
        do
        {
            ImageComputePipelineState = try ImageDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Error creating pipeline state: \(error.localizedDescription)")
        }
        
        let Target = MetalLibrary.MakeEmptyTexture(Size: Source.size, ImageDevice: ImageDevice!,
                                                   ForWriting: true)
        var AdjustedCG: CGImage? = nil
        let AdjustedSource = MetalLibrary.MakeTexture(From: Source, ForWriting: false, ImageDevice: ImageDevice!,
                                                      AsCG: &AdjustedCG)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(AdjustedSource, index: 0)
        CommandEncoder?.setTexture(Target, index: 1)
        
        let ThreadGroupCount = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(AdjustedSource!.width / ThreadGroupCount.width,
                                       AdjustedSource!.height / ThreadGroupCount.height,
                                       1)
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        CommandEncoder?.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder?.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        let ImageSize = CGSize(width: Target!.width, height: Target!.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = (AdjustedCG?.bytesPerRow)!
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        Target!.getBytes(&ImageBytes, bytesPerRow: BytesPerRow, from: ORegion, mipmapLevel: 0)
        
        let CIOptions = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                         CIImageOption.applyOrientationProperty: false,
                         CIContextOption.outputPremultiplied: true,
                         CIContextOption.useSoftwareRenderer: false] as! [CIImageOption: Any]
        let CImg = CIImage(mtlTexture: Target!, options: CIOptions)
        let CImgRep = NSCIImageRep(ciImage: CImg!)
        let Final = NSImage(size: ImageSize)
        Final.addRepresentation(CImgRep)
        return Final
    }
}
