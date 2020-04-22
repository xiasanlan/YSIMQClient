//
//  YSWeakObject.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSWeakObject : NSObject

@property (nonatomic,weak) id weakObject;

- (instancetype)initWithWeakObject:(NSObject *)object;

@end

NS_ASSUME_NONNULL_END
