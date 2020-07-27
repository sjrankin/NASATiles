//
//  ImageResizer.swift
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
import MetalPerformanceShaders

//https://stackoverflow.com/questions/40970644/crop-and-scale-mtltexture
class ImageResizer
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
    
    func Resize(_ Image: NSImage, To NewSize: NSSize) -> NSImage?
    {
        guard let Device = MTLCreateSystemDefaultDevice() else
        {
            return nil
        }
        
        let Target = MetalLibrary.MakeEmptyTexture(Size: NewSize, ImageDevice: ImageDevice!)
        var CGSource: CGImage? = nil
        let Source = MetalLibrary.MakeTexture(From: Image, ForWriting: false, ImageDevice: ImageDevice!, AsCG: &CGSource)
        
        let ScaleX = NewSize.width / Image.size.width
        let ScaleY = NewSize.height / Image.size.height
        var Transform = MPSScaleTransform(scaleX: Double(ScaleX), scaleY: Double(ScaleY), translateX: 0.0, translateY: 0.0)
        let Sizer = MPSImageLanczosScale(device: Device)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        withUnsafePointer(to: &Transform)
        {
            (Ptr: UnsafePointer<MPSScaleTransform>) -> () in
            Sizer.scaleTransform = Ptr
            Sizer.encode(commandBuffer: CommandBuffer!, sourceTexture: Source!, destinationTexture: Target!)
        }
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()

        let ImageSize = CGSize(width: Target!.width, height: Target!.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = Target!.width * 4
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        Target!.getBytes(&ImageBytes, bytesPerRow: BytesPerRow, from: ORegion, mipmapLevel: 0)
        
        let CIOptions = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                         CIContextOption.outputPremultiplied: true,
                         CIContextOption.useSoftwareRenderer: false] as! [CIImageOption: Any]
        let CImg = CIImage(mtlTexture: Target!, options: CIOptions)
        let CImgRep = NSCIImageRep(ciImage: CImg!)
        let Final = NSImage(size: ImageSize)
        Final.addRepresentation(CImgRep)
        return Final
    }
}
