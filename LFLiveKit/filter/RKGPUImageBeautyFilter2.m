//
//  RKGPUImageBeautyFilter2.m
//  LFLiveKit
//
//  Created by Ken Sun on 2017/12/20.
//  Copyright © 2017年 admin. All rights reserved.
//

#import "RKGPUImageBeautyFilter2.h"

NSString *const kRKGPUImageBeauty2FragmentShaderString = SHADER_STRING
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
     vec3 centralColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     vec2 blurCoordinates[24];
     
     blurCoordinates[0] = textureCoordinate.xy + singleStepOffset * vec2(0.0, -10.0);
     blurCoordinates[1] = textureCoordinate.xy + singleStepOffset * vec2(0.0, 10.0);
     blurCoordinates[2] = textureCoordinate.xy + singleStepOffset * vec2(-10.0, 0.0);
     blurCoordinates[3] = textureCoordinate.xy + singleStepOffset * vec2(10.0, 0.0);
     blurCoordinates[4] = textureCoordinate.xy + singleStepOffset * vec2(5.0, -8.0);
     blurCoordinates[5] = textureCoordinate.xy + singleStepOffset * vec2(5.0, 8.0);
     blurCoordinates[6] = textureCoordinate.xy + singleStepOffset * vec2(-5.0, 8.0);
     blurCoordinates[7] = textureCoordinate.xy + singleStepOffset * vec2(-5.0, -8.0);
     blurCoordinates[8] = textureCoordinate.xy + singleStepOffset * vec2(8.0, -5.0);
     blurCoordinates[9] = textureCoordinate.xy + singleStepOffset * vec2(8.0, 5.0);
     blurCoordinates[10] = textureCoordinate.xy + singleStepOffset * vec2(-8.0, 5.0);
     blurCoordinates[11] = textureCoordinate.xy + singleStepOffset * vec2(-8.0, -5.0);
     blurCoordinates[12] = textureCoordinate.xy + singleStepOffset * vec2(0.0, -6.0);
     blurCoordinates[13] = textureCoordinate.xy + singleStepOffset * vec2(0.0, 6.0);
     blurCoordinates[14] = textureCoordinate.xy + singleStepOffset * vec2(6.0, 0.0);
     blurCoordinates[15] = textureCoordinate.xy + singleStepOffset * vec2(-6.0, 0.0);
     blurCoordinates[16] = textureCoordinate.xy + singleStepOffset * vec2(-4.0, -4.0);
     blurCoordinates[17] = textureCoordinate.xy + singleStepOffset * vec2(-4.0, 4.0);
     blurCoordinates[18] = textureCoordinate.xy + singleStepOffset * vec2(4.0, -4.0);
     blurCoordinates[19] = textureCoordinate.xy + singleStepOffset * vec2(4.0, 4.0);
     blurCoordinates[20] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, -2.0);
     blurCoordinates[21] = textureCoordinate.xy + singleStepOffset * vec2(-2.0, 2.0);
     blurCoordinates[22] = textureCoordinate.xy + singleStepOffset * vec2(2.0, -2.0);
     blurCoordinates[23] = textureCoordinate.xy + singleStepOffset * vec2(2.0, 2.0);
     
     float weight = 0.0;
     float totalWeight = 0.0;
     float sampleColor = 0.0;
     float tmpColor = 0.0;
     
     float originColor = centralColor.g;
     
     weight = 22.0;
     totalWeight += weight;
     sampleColor += originColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[0]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[1]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[2]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[3]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[4]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[5]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[6]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[7]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[8]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[9]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[10]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[11]).g;
     weight = (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[12]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[13]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[14]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[15]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[16]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[17]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[18]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[19]).g;
     weight = 2.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[20]).g;
     weight = 3.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[21]).g;
     weight = 3.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[22]).g;
     weight = 3.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     tmpColor = texture2D(inputImageTexture, blurCoordinates[23]).g;
     weight = 3.0 * (1.0 - abs(originColor - tmpColor));
     totalWeight += weight;
     sampleColor += tmpColor * weight;
     
     
     sampleColor = sampleColor / totalWeight;
     
     float highpass = originColor - sampleColor + 0.5;
     
     for(int i = 0; i < 5; i++) {
         highpass = hardlight(highpass);
     }
     float lumance = dot(centralColor, W);
     
     float alpha = pow(lumance, params.r);
     
     vec3 smoothColor = centralColor + (centralColor-vec3(highpass))*alpha*0.1;
     
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

@implementation RKGPUImageBeautyFilter2

- (instancetype)init {
    if (self = [super initWithFragmentShaderFromString:kRKGPUImageBeauty2FragmentShaderString]) {
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

- (void)setY:(float)y {
    [self setFloat:y forUniformName:@"threshold"];
}

@end
