//
//  YSWeakObject.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSWeakObject.h"

@implementation YSWeakObject

- (instancetype)initWithWeakObject:(NSObject *)object{
    if(self = [super init]){
        _weakObject = object;
    }
    return self;
}

@end
