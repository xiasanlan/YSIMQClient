//
//  YSCustomInformation.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/17.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSCustomInformation : NSObject

@property (nonatomic,copy) NSString *deviceId;

@property (nonatomic,copy) NSString *channel;

@property(nonatomic,copy) NSString *deviceModel;

@property(nonatomic,copy) NSString *clientVersion;

@property(nonatomic,copy) NSString *systemVersion;

//定位信息

@property(nonatomic,assign) double longitude;

@property(nonatomic,assign) double latitude;

@property(nonatomic,copy) NSString *location;

+ (instancetype)defaultInformation;

- (void)collectionInformation;

@end

NS_ASSUME_NONNULL_END
