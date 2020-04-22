//
//  NSTimer+YSWeak.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "NSTimer+YSWeak.h"

@implementation NSTimer (YSWeak)

+ (void)_ys_ExecBlock:(NSTimer *)timer {
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
}

+ (NSTimer *)ys_scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats {
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(_ys_ExecBlock:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)ys_timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats {
    return [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(_ys_ExecBlock:) userInfo:[block copy] repeats:repeats];
}

@end
