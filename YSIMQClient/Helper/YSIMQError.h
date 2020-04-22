//
//  YSIMQError.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/8.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSIMQClientDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSIMQError : NSError

- (instancetype)initWithErrorCode:(YSIMQSocketErrorCode)code message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
