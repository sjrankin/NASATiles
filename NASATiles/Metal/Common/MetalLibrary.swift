//
//  MetalLibrary.swift
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

class MetalLibrary
{
    /// Convert an instance of a UIColor to a SIMD float4 structure.
    /// - Returns: SIMD float4 equivalent of the instance color.
    public static func ToFloat4(_ Color: NSColor) -> simd_float4
    {
        var FVals = [Float]()
        var Red: CGFloat = 0.0
        var Green: CGFloat = 0.0
        var Blue: CGFloat = 0.0
        var Alpha: CGFloat = 1.0
        Color.getRed(&Red, green: &Green, blue: &Blue, alpha: &Alpha)
        FVals.append(Float(Red))
        FVals.append(Float(Green))
        FVals.append(Float(Blue))
        FVals.append(Float(Alpha))
        let Result = simd_float4(FVals)
        return Result
    }
    
    /// Adjusts the colorspace of the passed image from monochrome to device RGB.
    /// - Parameter For: The image whose color space may potentially be changed.
    /// - Parameter ForceSize: If not nil, the size to force internal conversions to.
    /// - Returns: New image (in `CGImage` format). This image will *not* have a monochrome color space
    ///            (even if visually is looks monochromatic).
    public static func AdjustColorSpace(For Image: NSImage, ForceSize: NSSize? = nil) -> CGImage?
    {
        var CgImage: CGImage? = nil
        if let ImageSize = ForceSize
        {
            var Rect = NSRect(origin: .zero, size: ImageSize)
            CgImage = Image.cgImage(forProposedRect: &Rect, context: nil, hints: nil)
        }
        else
        {
         CgImage = Image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
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
    
    /// Convert an `NSImage` to a `MTLTexture` for use with Metal compute shaders.
    /// - Parameter From: The image to convert.
    /// - Parameter ForWriting: If true, the returned Metal texture will allow writing. Otherwise, it will
    ///                         only allow reading. Defaults to `false`.
    /// - Parameter ImageDevice: The `MTLDevice` where the Metal texture will be used.
    /// - Parameter AsCG: Upon exit, will contain the `CGImage` version of `From`.
    /// - Returns: Metal texture conversion of `From` on success, nil on failure.
    public static func MakeTexture(From: NSImage, ForWriting: Bool = false, ImageDevice: MTLDevice,
                                   AsCG: inout CGImage?) -> MTLTexture?
    {
        let ImageSize = From.size
        if let Adjusted = MetalLibrary.AdjustColorSpace(For: From, ForceSize: ImageSize)
        {
            AsCG = Adjusted
            let ImageWidth: Int = Adjusted.width
            let ImageHeight: Int = Adjusted.height
            var RawData = [UInt8](repeating: 0, count: Int(ImageWidth * ImageHeight * 4))
            let RGBColorSpace = CGColorSpaceCreateDeviceRGB()
            let BitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
            let BitsPerComponent = 8
            let BytesPerRow = Adjusted.bytesPerRow
            let Context = CGContext(data: &RawData,
                                    width: ImageWidth,
                                    height: ImageHeight,
                                    bitsPerComponent: BitsPerComponent,
                                    bytesPerRow: BytesPerRow,
                                    space: RGBColorSpace,
                                    bitmapInfo: BitmapInfo.rawValue)
            Context!.draw(Adjusted, in: CGRect(x: 0, y: 0, width: ImageWidth, height: ImageHeight))
            let TextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                             width: Int(ImageWidth),
                                                                             height: Int(ImageHeight),
                                                                             mipmapped: true)
            if ForWriting
            {
                TextureDescriptor.usage = [.shaderWrite, .shaderRead]
            }
            guard let TileTexture = ImageDevice.makeTexture(descriptor: TextureDescriptor) else
            {
                return nil
            }
            let Region = MTLRegionMake2D(0, 0, Int(ImageWidth), Int(ImageHeight))
            TileTexture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData,
                                bytesPerRow: BytesPerRow)
            
            return TileTexture
        }
        return nil
    }
    
    /// Creates an empty Metal texture intended to be used as a target for Metal compute shaders.
    /// - Parameter Size: The size of the Metal texture to return.
    /// - Parameter ImageDevice: The MTLDevice where the Metal texture will be used.
    /// - Parameter ForWriting: If true, the returned Metal texture will allow writing. Otherwise, it will
    ///                         only allow reading. Defaults to `false`.
    /// - Returns: Empty (all pixel values set to 0x0) Metal texture on success, nil on failure.
    public static func MakeEmptyTexture(Size: NSSize, ImageDevice: MTLDevice, ForWriting: Bool = false) -> MTLTexture?
    {
        let ImageWidth: Int = Int(Size.width)
        let ImageHeight: Int = Int(Size.height)
        var RawData = [UInt8](repeating: 0, count: Int(ImageWidth * ImageHeight * 4))
        let BytesPerRow = Int(Size.width * 4)
        let TextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: Int(ImageWidth),
                                                                         height: Int(ImageHeight),
                                                                         mipmapped: true)
        TextureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let TileTexture = ImageDevice.makeTexture(descriptor: TextureDescriptor) else
        {
            print("Error creating texture.")
            return nil
        }
        let Region = MTLRegionMake2D(0, 0, Int(ImageWidth), Int(ImageHeight))
        TileTexture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData,
                            bytesPerRow: BytesPerRow)
        
        return TileTexture
    }
}

/// UInt8 extensions.
extension UInt8
{
    /// Returns the layout size of a `UInt8` for an instance value.
    /// - Returns: Layout size of a `UInt8`.
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    /// Returns the layout size of a `UInt8` when used against the `UInt8` type.
    /// - Returns: Layout size of a `UInt8`.
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: UInt8(0))
    }
}

/// UInt extensions.
extension UInt
{
    /// Returns the layout size of a `UInt` for an instance value.
    /// - Returns: Layout size of a `UInt`.
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    /// Returns the layout size of a `UInt` when used against the `UInt` type.
    /// - Returns: Layout size of a `UInt`.
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: UInt(0))
    }
}

