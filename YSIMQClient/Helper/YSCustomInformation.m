//
//  YSCustomInformation.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/17.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSCustomInformation.h"
#import "YSKeychain.h"
#import <UIKit/UIKit.h>
#import "YSLocationManager.h"

#define YSCustomInformationService @"ys_information_key"
#define YSDeviceIdKey @"ys_device_key"

@implementation YSCustomInformation

+ (instancetype)defaultInformation{
    static YSCustomInformation *information = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        information = [[YSCustomInformation alloc] init];
    });
    return information;
}

- (void)collectionInformation{
    _channel = @"ios";
    //存入设备ID
    NSString *deviceId = [YSKeychain passwordForService:YSCustomInformationService account:YSDeviceIdKey];
    if(deviceId.length == 0){
        deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [YSKeychain setPassword:deviceId forService:YSCustomInformationService account:YSDeviceIdKey];
    }
    _deviceId = deviceId;
    //short version
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    _clientVersion = app_Version;
    //系统版本
    _systemVersion = [[UIDevice currentDevice] systemVersion];
    
    [[YSLocationManager shareManager] startRequestLocation];
    //判断有没有定位权限，获取定位
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.latitude = [YSLocationManager shareManager].defaultLocation.latitude;
        self.longitude = [YSLocationManager shareManager].defaultLocation.longitude;
        self.location = [YSLocationManager shareManager].defaultLocation.location;
    });
}

- (void)collectInformation{
    
}

@end
