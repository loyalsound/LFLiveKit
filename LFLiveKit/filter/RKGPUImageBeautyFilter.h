//
//  RKGPUImageBeautyFilter.h
//  LFLiveKit
//
//  Created by Ken Sun on 2017/12/19.
//  Copyright © 2017年 admin. All rights reserved.
//

#import "GPUImageFilter.h"

typedef NS_ENUM(NSUInteger, RKBeautyFilterType) {
    RKBeautyFilterTypeGaussian,
    RKBeautyFilterTypeBilateral,
    RKBeautyFilterTypePS
};

@interface RKGPUImageBeautyFilter : GPUImageFilter

@end
