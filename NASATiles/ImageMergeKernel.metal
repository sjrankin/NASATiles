//
//  ImageMergeKernel.metal
//  NASATiles
//
//  Created by Stuart Rankin on 7/24/20.
//

#include <metal_stdlib>
using namespace metal;

struct ImageMergeParameters
{
    uint ImageCount;
    uint XOffset;
    uint YOffset;
};

kernel void ImageMergeKernel(texture2d<float, access::read> SourceTexture [[texture(0)]],
                             texture2d<float, access::write> Background [[texture(1)]],
                             constant ImageMergeParameters &Offsets [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]])
{
    float4 SourceColor = SourceTexture.read(gid);
    uint2 BGgid = uint2(gid.x + Offsets.XOffset, gid.y + Offsets.YOffset);
    Background.write(SourceColor, BGgid);
}
