//
//  RKGPUImageBeautyFilter.m
//  LFLiveKit
//
//  Created by Ken Sun on 2017/12/19.
//  Copyright © 2017年 admin. All rights reserved.
//

#import "RKGPUImageBeautyFilter.h"

NSString *const kRKGPUImageBeautyFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 uniform vec2 singleStepOffset;
 uniform highp vec4 params;
 
 uniform float threshold;
 
 varying highp vec2 textureCoordinate;
 
 const highp vec3 W = vec3(0.299,0.587,0.114);
 const mat3 saturateMatrix = mat3(
                                  1.1102,-0.0598,-0.061,
                                  -0.0774,1.0826,-0.1186,
                                  -0.0228,-0.0228,1.1772);
 
 float hardlight(float color) {
    if(color <= 0.5) {
        color = color * color * 2.0;
    } else {
        color = 1.0 - ((1.0 - color)*(1.0 - color) * 2.0);
    }
    return color;
 }
 
 void main() {
     vec2 blurCoordinates[25];
     
     blurCoordinates[0] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, -2.0);
     blurCoordinates[1] = textureCoordinate.xy + singleStepOffset * vec2(-1.0, -2.0);
     blurCoordinates[2] = textureCoordinate.xy + singleStepOffset * vec2(0.0, -2.0);
     blurCoordinates[3] = textureCoordinate.xy + singleStepOffset * vec2(1.0, -2.0);
     blurCoordinates[4] = textureCoordinate.xy + singleStepOffset * vec2(2.0, -2.0);

     blurCoordinates[5] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, -1.0);
     blurCoordinates[6] = textureCoordinate.xy + singleStepOffset * vec2(-1.0, -1.0);
     blurCoordinates[7] = textureCoordinate.xy + singleStepOffset * vec2(0.0, -1.0);
     blurCoordinates[8] = textureCoordinate.xy + singleStepOffset * vec2(1.0, -1.0);
     blurCoordinates[9] = textureCoordinate.xy + singleStepOffset * vec2(2.0, -1.0);

     blurCoordinates[10] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, 0.0);
     blurCoordinates[11] = textureCoordinate.xy + singleStepOffset * vec2(-1.0, 0.0);
     blurCoordinates[12] = textureCoordinate.xy + singleStepOffset * vec2(0.0, 0.0);
     blurCoordinates[13] = textureCoordinate.xy + singleStepOffset * vec2(1.0, 0.0);
     blurCoordinates[14] = textureCoordinate.xy + singleStepOffset * vec2(2.0, 0.0);

     blurCoordinates[15] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, 1.0);
     blurCoordinates[16] = textureCoordinate.xy + singleStepOffset * vec2(-1.0, 1.0);
     blurCoordinates[17] = textureCoordinate.xy + singleStepOffset * vec2(0.0, 1.0);
     blurCoordinates[18] = textureCoordinate.xy + singleStepOffset * vec2(1.0, 1.0);
     blurCoordinates[19] = textureCoordinate.xy + singleStepOffset * vec2(2.0, 1.0);

     blurCoordinates[20] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, 2.0);
     blurCoordinates[21] = textureCoordinate.xy + singleStepOffset * vec2(-1.0, 2.0);
     blurCoordinates[22] = textureCoordinate.xy + singleStepOffset * vec2(0.0, 2.0);
     blurCoordinates[23] = textureCoordinate.xy + singleStepOffset * vec2(1.0, 2.0);
     blurCoordinates[24] = textureCoordinate.xy + singleStepOffset * vec2(2.0, 2.0);
     
     vec3 centralColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     float x1 = centralColor.g;
     float a = 0.0;
     float b = 0.0;
     for (int i = 0; i < 25; i++) {
         float xi = texture2D(inputImageTexture, blurCoordinates[i]).g;
         a += (1.0 - abs(xi - x1) / (2.5 * threshold)) * xi;
         b += 1.0 - abs(xi - x1) / (2.5 * threshold);
     }
     float sampleColor = a / b;

     float highpass = x1 - sampleColor + 0.5;

     for(int i = 0; i < 5; i++) {
         highpass = hardlight(highpass);
     }
     
//     vec3 x1 = centralColor;
//     vec3 a = vec3(0.0);
//     vec3 b = vec3(0.0);
//     for (int i = 0; i < 25; i++) {
//         vec3 xi = texture2D(inputImageTexture, blurCoordinates[i]).rgb;
//         a.r += (1.0 - abs(xi.r - x1.r) / (2.5 * threshold)) * xi.r;
//         b.r += 1.0 - abs(xi.r - x1.r) / (2.5 * threshold);
//         a.g += (1.0 - abs(xi.g - x1.g) / (2.5 * threshold)) * xi.g;
//         b.g += 1.0 - abs(xi.g - x1.g) / (2.5 * threshold);
//         a.b += (1.0 - abs(xi.b - x1.b) / (2.5 * threshold)) * xi.b;
//         b.b += 1.0 - abs(xi.b - x1.b) / (2.5 * threshold);
//     }
//     vec3 sampleColor = a / b;
//     vec3 highpass = x1 - sampleColor + 0.5;
//     for(int i = 0; i < 5; i++) {
//        highpass = vec3(hardlight(highpass.r), hardlight(highpass.g), hardlight(highpass.b));
//     }
     
     float lumance = dot(centralColor, W);
     
     float alpha = pow(lumance, params.r);
     
     vec3 smoothColor = centralColor + (centralColor-vec3(highpass))*alpha*0.1;
     //vec3 smoothColor = centralColor + (centralColor-highpass)*alpha*0.1;
     
     smoothColor.r = clamp(pow(smoothColor.r, params.g),0.0,1.0);
     smoothColor.g = clamp(pow(smoothColor.g, params.g),0.0,1.0);
     smoothColor.b = clamp(pow(smoothColor.b, params.g),0.0,1.0);
     
     vec3 lvse = vec3(1.0)-(vec3(1.0)-smoothColor)*(vec3(1.0)-centralColor);
     vec3 bianliang = max(smoothColor, centralColor);
     vec3 rouguang = 2.0*centralColor*smoothColor + centralColor*centralColor - 2.0*centralColor*centralColor*smoothColor;
     
     gl_FragColor = vec4(mix(centralColor, lvse, alpha), 1.0);
     gl_FragColor.rgb = mix(gl_FragColor.rgb, bianliang, alpha);
     gl_FragColor.rgb = mix(gl_FragColor.rgb, rouguang, params.b);
     
     vec3 satcolor = gl_FragColor.rgb * saturateMatrix;
     gl_FragColor.rgb = mix(gl_FragColor.rgb, satcolor, params.a);
 }
);

@implementation RKGPUImageBeautyFilter

- (instancetype)init {
    if (self = [super initWithFragmentShaderFromString:kRKGPUImageBeautyFragmentShaderString]) {
        [self setY:16.0];
        [self setParams:0.5 tone:0.5];
    }
    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [super setInputSize:newSize atIndex:textureIndex];
    inputTextureSize = newSize;
    
    CGPoint offset = CGPointMake(2.0f / inputTextureSize.width, 2.0 / inputTextureSize.height);
    [self setPoint:offset forUniformName:@"singleStepOffset"];
}

- (void)setParams:(CGFloat)beauty tone:(CGFloat)tone {
    GPUVector4 params = {0.33f, 0.63f, 0.4f, 0.35f};
//    params.one = 1.0 - 0.6 * beauty;
//    params.two = 1.0 - 0.3 * beauty;
//    params.three = 0.1 + 0.3 * tone;
//    params.four = 0.1 + 0.3 * tone;
    [self setFloatVec4:params forUniform:@"params"];
}

- (void)setR:(int)r {
    [self setInteger:r forUniformName:@"radius"];
}

- (void)setY:(float)y {
    [self setFloat:y forUniformName:@"threshold"];
}

@end
