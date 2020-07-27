//
//  ImageFlipper.metal
//  NASATiles
//
//  Created by Stuart Rankin on 7/26/20.
//

#include <metal_stdlib>
using namespace metal;

kernel void ImageFlipVertical(texture2d<float, access::read> Source [[texture(0)]],
                              texture2d<float, access::write> Target [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]])
{

    float4 SourceColor = Source.read(gid);
    Target.write(SourceColor, uint2(gid.x, gid.y));
}

kernel void ImageFlipHorizontal(texture2d<float, access::read> Source [[texture(0)]],
                                texture2d<float, access::write> Target [[texture(1)]],
                                uint2 gid [[thread_position_in_grid]])
{
    int SourceHeight = Source.get_height();
    int SourceWidth = Source.get_width();
    float4 SourceColor = Source.read(gid);
    Target.write(SourceColor, uint2(SourceWidth - gid.x, SourceHeight - gid.y));
}


kernel void ImageFlipBoth(texture2d<float, access::read> Source [[texture(0)]],
                          texture2d<float, access::write> Target [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    int SourceWidth = Source.get_width();
    float4 SourceColor = Source.read(gid);
    Target.write(SourceColor, uint2(SourceWidth - gid.x, gid.y));
}
