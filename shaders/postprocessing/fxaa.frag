#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

// https://github.com/kosua20/Rendu/blob/master/resources/common/shaders/screens/fxaa.frag

#define EDGE_THRESHOLD_MIN 0.0312
#define EDGE_THRESHOLD_MAX 0.125
#define ITERATIONS 12
#define SUBPIXEL_QUALITY 0.75
#define QUALITY(q) ((q) < 5 ? 1.0 : ((q) > 5 ? ((q) < 10 ? 2.0 : ((q) < 11 ? 4.0 : 8.0)) : 1.5))


vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec2 pixelSize = 1.0 / textureSize(tex, 0);
	vec3 colorCenter = texture(tex, texcoords).rgb;
	float lumaCenter = LuminanceGamma(colorCenter);
	
	// Luma at the four direct neighbours of the current fragment.
	float lumaDown 	= LuminanceGamma(textureOffset(tex, texcoords, ivec2( 0,-1)).rgb);
	float lumaUp 	= LuminanceGamma(textureOffset(tex, texcoords, ivec2( 0, 1)).rgb);
	float lumaLeft 	= LuminanceGamma(textureOffset(tex, texcoords, ivec2(-1, 0)).rgb);
	float lumaRight = LuminanceGamma(textureOffset(tex, texcoords, ivec2( 1, 0)).rgb);
	
	float lumaMin = min(lumaCenter, min(min(lumaDown, lumaUp), min(lumaLeft, lumaRight)));
	float lumaMax = max(lumaCenter, max(max(lumaDown, lumaUp), max(lumaLeft, lumaRight)));
	
	float lumaRange = lumaMax - lumaMin;
	
	// If the luma variation is lower that a threshold (or if we are in a really dark area), we are not on an edge, don't perform any AA.
	if(lumaRange < max(EDGE_THRESHOLD_MIN, lumaMax * EDGE_THRESHOLD_MAX)){
		return vec4(colorCenter, 1.0);
	}
	
	float lumaDownLeft 	= LuminanceGamma(textureOffset(tex, texcoords, ivec2(-1,-1)).rgb);
	float lumaUpRight 	= LuminanceGamma(textureOffset(tex, texcoords, ivec2( 1, 1)).rgb);
	float lumaUpLeft 	= LuminanceGamma(textureOffset(tex, texcoords, ivec2(-1, 1)).rgb);
	float lumaDownRight = LuminanceGamma(textureOffset(tex, texcoords, ivec2( 1,-1)).rgb);
	
	float lumaDownUp = lumaDown + lumaUp;
	float lumaLeftRight = lumaLeft + lumaRight;
	
	float lumaLeftCorners  = lumaDownLeft  + lumaUpLeft;
	float lumaDownCorners  = lumaDownLeft  + lumaDownRight;
	float lumaRightCorners = lumaDownRight + lumaUpRight;
	float lumaUpCorners    = lumaUpRight   + lumaUpLeft;
	
	// Compute an estimation of the gradient along the horizontal and vertical axis.
	float edgeHorizontal = abs(-2.0 * lumaLeft + lumaLeftCorners) + abs(-2.0 * lumaCenter + lumaDownUp )   * 2.0 + abs(-2.0 * lumaRight + lumaRightCorners);
	float edgeVertical   = abs(-2.0 * lumaUp + lumaUpCorners)     + abs(-2.0 * lumaCenter + lumaLeftRight) * 2.0 + abs(-2.0 * lumaDown + lumaDownCorners);
	
	bool isHorizontal = (edgeHorizontal >= edgeVertical);
	float stepLength = isHorizontal ? pixelSize.y : pixelSize.x;
	
	float luma1 = isHorizontal ? lumaDown : lumaLeft;
	float luma2 = isHorizontal ? lumaUp : lumaRight;
	float gradient1 = luma1 - lumaCenter;
	float gradient2 = luma2 - lumaCenter;
	
	bool is1Steepest = abs(gradient1) >= abs(gradient2);
	float gradientScaled = 0.25 * max(abs(gradient1),abs(gradient2));
	
	// Average luma in the correct direction.
	float lumaLocalAverage = 0.0;
	if(is1Steepest){
		stepLength = -stepLength;
		lumaLocalAverage = 0.5 * (luma1 + lumaCenter);
	}
	else {
		lumaLocalAverage = 0.5 * (luma2 + lumaCenter);
	}
	
	// Shift UV in the correct direction by half a pixel.
	vec2 currentUv = texcoords;
	if(isHorizontal){
		currentUv.y += stepLength * 0.5;
	} else {
		currentUv.x += stepLength * 0.5;
	}
	
	vec2 offset = isHorizontal ? vec2(pixelSize.x,0.0) : vec2(0.0,pixelSize.y);
	// Compute UVs to explore on each side of the edge, orthogonally. The QUALITY allows us to step faster.
	vec2 uv1 = currentUv - offset * QUALITY(0);
	vec2 uv2 = currentUv + offset * QUALITY(0);
	
	// Read the lumas at both current extremities of the exploration segment, and compute the delta wrt to the local average luma.
	float lumaEnd1 = LuminanceGamma(textureLod(tex, uv1, 0.0).rgb) - lumaLocalAverage;
	float lumaEnd2 = LuminanceGamma(textureLod(tex, uv2, 0.0).rgb) - lumaLocalAverage;
	
	// If the luma deltas at the current extremities is larger than the local gradient, we have reached the side of the edge.
	bool reached1 = abs(lumaEnd1) >= gradientScaled;
	bool reached2 = abs(lumaEnd2) >= gradientScaled;
	bool reachedBoth = reached1 && reached2;
	
	if(!reached1){
		uv1 -= offset * QUALITY(1);
	}
	if(!reached2){
		uv2 += offset * QUALITY(1);
	}
	
	if(!reachedBoth){
		for(int i = 2; i < ITERATIONS; i++){
			if(!reached1){
				lumaEnd1 = LuminanceGamma(textureLod(tex, uv1, 0.0).rgb) - lumaLocalAverage;
			}
			if(!reached2){
				lumaEnd2 = LuminanceGamma(textureLod(tex, uv2, 0.0).rgb) - lumaLocalAverage;
			}

			reached1 = abs(lumaEnd1) >= gradientScaled;
			reached2 = abs(lumaEnd2) >= gradientScaled;
			reachedBoth = reached1 && reached2;
			
			if(!reached1){
				uv1 -= offset * QUALITY(i);
			}
			if(!reached2){
				uv2 += offset * QUALITY(i);
			}
			
			if(reachedBoth)
				break;
		}
	}
	
	// Compute the distances to each side edge of the edge (!).
	float distance1 = isHorizontal ? (texcoords.x - uv1.x) : (texcoords.y - uv1.y);
	float distance2 = isHorizontal ? (uv2.x - texcoords.x) : (uv2.y - texcoords.y);
	
	// In which direction is the side of the edge closer ?
	bool isDirection1 = distance1 < distance2;
	float distanceFinal = min(distance1, distance2);
	
	float edgeThickness = (distance1 + distance2);
	bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;
	
	// If the luma at center is smaller than at its neighbour, the delta luma at each end should be positive (same variation).
	bool correctVariation1 = (lumaEnd1 < 0.0) != isLumaCenterSmaller;
	bool correctVariation2 = (lumaEnd2 < 0.0) != isLumaCenterSmaller;
	bool correctVariation = isDirection1 ? correctVariation1 : correctVariation2;

	float pixelOffset = - distanceFinal / edgeThickness + 0.5;
	float finalOffset = correctVariation ? pixelOffset : 0.0;
	
	// Sub-pixel shifting
	// Full weighted average of the luma over the 3x3 neighborhood.
	float lumaAverage = (1.0/12.0) * (2.0 * (lumaDownUp + lumaLeftRight) + lumaLeftCorners + lumaRightCorners);
	// Ratio of the delta between the global average and the center luma, over the luma range in the 3x3 neighborhood.
	float subPixelOffset1 = clamp(abs(lumaAverage - lumaCenter) / lumaRange, 0.0, 1.0);
	float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
	// Compute a sub-pixel offset based on this delta.
	float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * SUBPIXEL_QUALITY;
	
	finalOffset = max(finalOffset,subPixelOffsetFinal);

	vec2 finalUVOffset = isHorizontal ? vec2(0.0, finalOffset) : vec2(finalOffset, 0.0);
	finalUVOffset *= stepLength;

	vec3 finalColor = textureLod(tex, texcoords+finalUVOffset, 0.0).rgb;
	return vec4(finalColor, 1.0);
}