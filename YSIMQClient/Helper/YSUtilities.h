//
//  YSUtilities.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSUtilities : NSObject

@end

@interface YSUtilities(Generate)


/// 构建三段式
/// @param data 数据
/// @param code 状态码  string(0,1)
/// @param message 描述
+ (NSDictionary *)generateResponseDicWithData:(NSDictionary * _Nullable)data responseCode:(NSString * _Nullable)code message:(NSString * _Nullable)message;

@end

NS_ASSUME_NONNULL_END
