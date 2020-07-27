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
    uint TileWidth;
    uint TileHeight;
    uint BackgroundWidth;
    uint BackgroundHeight;
};

kernel void ImageMergeKernel(texture2d<float, access::write> Background [[texture(0)]],
                             texture2d<float, access::read> TileTexture [[texture(1)]],
                             constant ImageMergeParameters &MergeData [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= Background.get_width() || gid.y >= Background.get_height())
        {
        return;
        }
    //Get the index into the tile for the tile's color.
    int TileX = int(MergeData.XOffset - 1) - int(gid.x);
    int TileY = int(MergeData.YOffset - 1) - int(gid.y);
    //If the coordinant is outside of the tile, ignore it and return.
    if (TileX < 0)
        {
        return;
        }
    if (TileY < 0)
        {
        return;
        }
    if (TileX > int(MergeData.TileWidth))
        {
        return;
        }
    if (TileY > int(MergeData.TileHeight))
        {
        return;
        }
    float4 TileColor = TileTexture.read(uint2(uint(TileX), uint(TileY)));
    Background.write(TileColor, gid);
}
