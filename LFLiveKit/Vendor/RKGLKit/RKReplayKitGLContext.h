//
//  RKReplayKitGLContext.h
//  LFLiveKit
//
//  Created by Ken Sun on 2017/12/12.
//  Copyright © 2017年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface RKReplayKitGLContext : NSObject

@property (nonatomic, readonly) CVPixelBufferRef outputPixelBuffer;

@property (nonatomic, readonly) CGSize canvasSize;

- (instancetype)initWithCanvasSize:(CGSize)canvasSize;

- (void)setRotation:(float)degrees;

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)render;

@end
