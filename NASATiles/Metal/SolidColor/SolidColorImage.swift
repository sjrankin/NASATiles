//
//  SolidColorImage.swift
//  NASATiles
//
//  Created by Stuart Rankin on 7/25/20.
//

import Foundation
import AppKit
import simd
import Metal
import MetalKit
import CoreImage

class SolidColorImage
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
        let KernelFunction = DefaultLibrary?.makeFunction(name: "SolidColorKernel")
        do
        {
            ImageComputePipelineState = try ImageDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Error creating pipeline state: \(error.localizedDescription)")
        }
    }
    
    func Fill(Width: Int, Height: Int, With Color: NSColor) -> NSImage?
    {
        return DoFill(With: Color, Size: NSSize(width: Width, height: Height))
    }
    
    private func DoFill(With Color: NSColor, Size: NSSize) -> NSImage?
    {
        let Parameter = SolidColorParameters(Fill: MetalLibrary.ToFloat4(Color))
        let Parameters = [Parameter]
        let ParameterBuffer = ImageDevice!.makeBuffer(length: /*MemoryLayout<ImageMergeParameters>.stride*/16, options: [])
        memcpy(ParameterBuffer!.contents(), Parameters, /*MemoryLayout<ImageMergeParameters>.stride*/16)
        
        let AdjustedTexture = MetalLibrary.MakeEmptyTexture(Size: Size, ImageDevice: ImageDevice!)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(AdjustedTexture, index: 0)
        CommandEncoder?.setBuffer(ParameterBuffer, offset: 0, index: 0)
        #if true
        let w = ImageComputePipelineState!.threadExecutionWidth
        let h = ImageComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadGroupCount = MTLSizeMake(w, h, 1)
        let ThreadGroups = MTLSize(width: Int(Size.width), height: Int(Size.height), depth: 1)
        #else
        let ThreadGroupCount = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(AdjustedTexture!.width / ThreadGroupCount.width,
                                       AdjustedTexture!.height / ThreadGroupCount.height,
                                       1)
        #endif
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        CommandEncoder?.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder?.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        let ImageSize = CGSize(width: AdjustedTexture!.width, height: AdjustedTexture!.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = Int(Size.width * 4)
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        AdjustedTexture!.getBytes(&ImageBytes, bytesPerRow: BytesPerRow, from: ORegion, mipmapLevel: 0)
        
        //https://stackoverflow.com/questions/49713008/pixel-colors-change-as-i-save-mtltexture-to-cgimage
        let kciop = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                     CIContextOption.outputPremultiplied: true,
                     CIContextOption.useSoftwareRenderer: false] as! [CIImageOption: Any]
        let test = CIImage(mtlTexture: AdjustedTexture!, options: kciop)
        let rep = NSCIImageRep(ciImage: test!)
        let test2 = NSImage(size: ImageSize)
        test2.addRepresentation(rep)
        return test2
    }
}

