//
//  YSUtilities.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSUtilities.h"

@implementation YSUtilities

@end

@implementation YSUtilities(Generate)

+ (NSDictionary *)generateResponseDicWithData:(NSDictionary *)data responseCode:(NSString *)code message:(NSString *)message{
    NSMutableDictionary *responseDic = [[NSMutableDictionary alloc] initWithCapacity:3];
    [responseDic setValue:code?:@"1" forKey:@"code"];
    [responseDic setValue:data?:@{} forKey:@"data"];
    [responseDic setValue:message?:@"" forKey:@"message"];
    return responseDic;
}


@end
