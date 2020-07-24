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

class ImageMerger
{
    private let ImageDevice = MTLCreateSystemDefaultDevice()
    private var ComputePipelineState: MTLComputePipelineState? = nil
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
            ComputePipelineState = try ImageDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Error creating pipeline state: \(error.localizedDescription)")
        }
    }
    
    func Merge(Tiles: [(Tile: NSImage, X: Int, Y: Int)], Background: NSImage) -> NSImage?
    {
        var TextureList = [MTLTexture]()
        for (Tile, X, Y) in Tiles
        {
            let ConvertedTile = AdjustColorSpace(For: Tile)
            let ImageWidth: Int = (ConvertedTile?.width)!
            let ImageHeight: Int = (ConvertedTile?.height)!
            var RawData = [UInt8](repeating: 0, count: Int(ImageWidth * ImageHeight * 4))
            let RGBColorSpace = CGColorSpaceCreateDeviceRGB()
            let BitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
            let Context = CGContext(data: &RawData, width: ImageWidth, height: ImageHeight,
                                    bitsPerComponent: (ConvertedTile?.bitsPerComponent)!,
                                    bytesPerRow: (ConvertedTile?.bytesPerRow)!, space: RGBColorSpace,
                                    bitmapInfo: BitmapInfo.rawValue)
            let TextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                             width: Int(ImageWidth),
                                                                             height: Int(ImageHeight),
                                                                             mipmapped: true)
            guard let Texture = ImageDevice?.makeTexture(descriptor: TextureDescriptor) else
            {
                return nil
            }
            let Region = MTLRegionMake2D(X, Y, Int(ImageWidth), Int(ImageHeight))
            Texture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData, bytesPerRow: Int((ConvertedTile?.bytesPerRow)!))
            TextureList.append(Texture)
        }
        
        let BGTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: TextureList[0].pixelFormat,
                                                                       width: TextureList[0].width,
                                                                       height: TextureList[0].height,
                                                                       mipmapped: true)
        BGTextureDescriptor.usage = MTLTextureUsage.shaderWrite
        let BGTexture = ImageDevice?.makeTexture(descriptor: BGTextureDescriptor)
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        
        return nil
    }
    
    func AdjustColorSpace(For Tile: NSImage) -> CGImage?
    {
        let CgImage = Tile.cgImage(forProposedRect: nil, context: nil, hints: nil)
        if var CGI = CgImage
        {
            if CGI.colorSpace?.model == CGColorSpaceModel.monochrome
            {
                let NewColorSpace = CGColorSpaceCreateDeviceRGB()
                let NewBMInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
                let IWidth = Int(CGI.width)
                let IHeight = Int(CGI.height)
                var RawData = [UInt8](repeating: 0, count: Int(IWidth * IHeight * 4))
                let GContext = CGContext(data: &RawData, width: IWidth, height: IHeight,
                                         bitsPerComponent: 8, bytesPerRow: 4 * IWidth,
                                         space: NewColorSpace, bitmapInfo: NewBMInfo.rawValue)
                let ImageRect = CGRect(origin: .zero, size: CGSize(width: IWidth, height: IHeight))
                GContext!.draw(CGI, in: ImageRect)
                CGI = GContext!.makeImage()!
                return CGI
            }
            else
            {
                return CGI
            }
        }
        return nil
    }
}
