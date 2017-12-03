//
//  RKReplayKitCapture.m
//  LFLiveKit
//
//  Created by Ken Sun on 2017/12/5.
//  Copyright © 2017年 admin. All rights reserved.
//

#import "RKReplayKitCapture.h"
#import "RKAudioMixSource.h"
#import "RKReplayKitGLContext.h"
#import "GPUImageRawDataInput.h"
#import "GPUImageFramebuffer.h"
#import "LFGPUImageEmptyFilter.h"
#import <ReplayKit/ReplayKit.h>

@interface RKReplayKitCapture ()

@property (nonatomic) BOOL appAudioReceived;

@property (nonatomic) BOOL micAudioOnly;

@property (nonatomic) NSUInteger startupVideoCount;

@property (nonatomic) AudioStreamBasicDescription appAudioFormat;

@property (nonatomic) AudioStreamBasicDescription micAudioFormat;

@property (strong, nonatomic) RKAudioDataMixSrc *micDataSrc;

@property (strong, nonatomic) RKReplayKitGLContext *glContext;

@property (strong, nonatomic) GPUImageRawDataInput *videoPipeInput;

@property (strong, nonatomic) GPUImageFilter *videoPipeOutput;

@end

@implementation RKReplayKitCapture

+ (AudioStreamBasicDescription)defaultAudioFormat {
    AudioStreamBasicDescription format = {0};
    format.mSampleRate = 44100;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    format.mChannelsPerFrame = 1;
    format.mFramesPerPacket = 1;
    format.mBitsPerChannel = 16;
    format.mBytesPerFrame = format.mBitsPerChannel / 8 * format.mChannelsPerFrame;
    format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket;
    return format;
}

- (instancetype)init {
    if (self = [super init]) {
        _micDataSrc = [[RKAudioDataMixSrc alloc] init];
        _startupVideoCount = 0;
    }
    return self;
}

- (void)pushVideoSample:(CMSampleBufferRef)sample {
    if (!_videoConfiguration) {
        _videoConfiguration = [LFLiveVideoConfiguration defaultConfigurationFromSampleBuffer:sample];
        
        if (@available(iOS 11.1, *)) {
            CFNumberRef orientationAttachment = CMGetAttachment(sample, (__bridge CFStringRef)RPVideoSampleOrientationKey, NULL);
            CGImagePropertyOrientation orientation = [(__bridge NSNumber*)orientationAttachment intValue];
            _videoConfiguration.videoSize = orientation <= kCGImagePropertyOrientationDownMirrored ? CGSizeMake(360, 640) : CGSizeMake(640, 360);
        }
        _glContext = [[RKReplayKitGLContext alloc] initWithCanvasSize:_videoConfiguration.videoSize];
    }
    
    [self processVideo:sample];
    //[_delegate replayKitCapture:self didCaptureVideo:CMSampleBufferGetImageBuffer(sample)];
    
    if (!_appAudioReceived && !_micAudioOnly) {
        _startupVideoCount++;
        if (_startupVideoCount > 30) {
            _micAudioOnly = YES;
        }
    }
}

- (void)processVideo:(CMSampleBufferRef)sample {
    if (@available(iOS 11.1, *)) {
        CFNumberRef orientationAttachment = CMGetAttachment(sample, (__bridge CFStringRef)RPVideoSampleOrientationKey, NULL);
        CGImagePropertyOrientation orientation = [(__bridge NSNumber*)orientationAttachment intValue];
        if (orientation == kCGImagePropertyOrientationUp) {
            [_glContext setRotation:90];
        } else if (orientation == kCGImagePropertyOrientationDown) {
            [_glContext setRotation:-90];
        } else if (orientation == kCGImagePropertyOrientationRight) {
            [_glContext setRotation:180];
        } else {
            [_glContext setRotation:0];
        }
    }
    [_glContext processPixelBuffer:CMSampleBufferGetImageBuffer(sample)];
    [_glContext render];
    CVPixelBufferRef output = _glContext.outputPixelBuffer;
    [_delegate replayKitCapture:self didCaptureVideo:output];
}

- (void)pushAppAudioSample:(CMSampleBufferRef)sample {
    if (!_appAudioReceived) {
        _appAudioReceived = YES;
    }
    _appAudioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sample));
    
    if (!_audioConfiguration) {
        _audioConfiguration = [LFLiveAudioConfiguration defaultConfigurationFromFormat:_appAudioFormat];
    }
    
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sample,
                                                            NULL,
                                                            &audioBufferList,
                                                            sizeof(audioBufferList),
                                                            NULL,
                                                            NULL,
                                                            0,
                                                            &blockBuffer);
    for (int i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        [self convertAudioBufferToNativeEndian:audioBuffer fromFormat:_appAudioFormat];
        [self mixMicAudioToAudioBuffer:audioBuffer];
        NSData *data = [NSData dataWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
        [_delegate replayKitCapture:self didCaptureAudio:data];
    }
    CFRelease(blockBuffer);
}

- (void)pushMicAudioSample:(CMSampleBufferRef)sample {
    _micAudioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sample));
    
    if (!_audioConfiguration) {
        _audioConfiguration = [LFLiveAudioConfiguration defaultConfigurationFromFormat:_micAudioFormat];
    }
    
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sample,
                                                            NULL,
                                                            &audioBufferList,
                                                            sizeof(audioBufferList),
                                                            NULL,
                                                            NULL,
                                                            0,
                                                            &blockBuffer);
    for (int i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        [self convertAudioBufferToNativeEndian:audioBuffer fromFormat:_micAudioFormat];
        NSData *data = [NSData dataWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
        [_micDataSrc pushData:data];
    }
    CFRelease(blockBuffer);
    
    if (_micAudioOnly) {
        [_delegate replayKitCapture:self didCaptureAudio:[_micDataSrc popData]];
    }
}

- (void)mixMicAudioToAudioBuffer:(AudioBuffer)audioBuffer {
    char *audioBytes = audioBuffer.mData;
    for (int i = 0; i < audioBuffer.mDataByteSize && _micDataSrc.hasNext; i += 2) {
        short a = (short)(((audioBytes[i + 1] & 0xFF) << 8) | (audioBytes[i] & 0xFF));
        short b = [_micDataSrc next];
        int mixed = (a + b) / 2;
        audioBytes[i] = mixed & 0xFF;
        audioBytes[i + 1] = (mixed >> 8) & 0xFF;
    }
}

- (void)startSlienceAudio {
    
}

- (void)stopSlienceAudio {
    
}

- (void)convertAudioBufferToNativeEndian:(AudioBuffer)buffer fromFormat:(AudioStreamBasicDescription)format {
    if (format.mFormatFlags & kAudioFormatFlagIsBigEndian) {
        int i = 0;
        char *ptr = buffer.mData;
        while (i < buffer.mDataByteSize) {
            SInt16 value = CFSwapInt16BigToHost(*((SInt16*)ptr));
            memcpy(ptr, &value, 2);
            i += 2;
            ptr += 2;
        }
    }
}

- (void)convertDataToNativeEndian:(NSMutableData *)data fromFormat:(AudioStreamBasicDescription)format {
    if (format.mFormatFlags & kAudioFormatFlagIsBigEndian) {
        const void *ptr = data.bytes;
        for (int i = 0; i < data.length; i += 2) {
            SInt16 endian = CFSwapInt16BigToHost(*((SInt16*)ptr));
            [data replaceBytesInRange:NSMakeRange(i, 2) withBytes:&endian];
            ptr += 2;
        }
    }
}

@end
