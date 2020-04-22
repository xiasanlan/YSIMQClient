//
//  YSIMQError.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/8.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSIMQError.h"

#define YSIMQDomain @"com.yunshi.imqclient.ErrorDomain"

@implementation YSIMQError

- (instancetype)initWithErrorCode:(YSIMQSocketErrorCode)code message:(NSString *)message {
    self = [super initWithDomain:YSIMQDomain code:code userInfo:@{NSLocalizedDescriptionKey:message?:@""}];
    return self;
}

@end
