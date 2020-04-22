//
//  YSLocationManager.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/17.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSLocationModel : NSObject

@property(nonatomic,assign) CLLocationDegrees latitude;

@property(nonatomic,assign) CLLocationDegrees longitude;

@property(nonatomic,copy) NSString *location;

@property(nonatomic,assign) NSDate *updateTime;

@end

@protocol YSLocationManagerDelegate <NSObject>



@end

@interface YSLocationManager : NSObject

@property (nonatomic,weak) id<YSLocationManagerDelegate> delegate;

@property (nonatomic,strong,readonly) YSLocationModel *defaultLocation;

+ (instancetype)shareManager;

- (void)addDelegate:(id<YSLocationManagerDelegate>)delegate;

- (void)removeDelegate:(id<YSLocationManagerDelegate>)delegate;

- (void)startRequestLocation;

@end

NS_ASSUME_NONNULL_END
