//
//  RKLinkedList.h
//  LFLiveKit
//
//  Created by Ken Sun on 2017/12/6.
//  Copyright © 2017年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKLinkedList : NSObject

@property (nonatomic, readonly) id _Nullable head;
@property (nonatomic, readonly) id _Nullable tail;
@property (nonatomic, readonly) NSUInteger length;

- (void)pushHead:(nonnull id)obj;

- (nullable id)popHead;

- (void)pushTail:(nonnull id)obj;

- (nullable id)popTail;

@end
