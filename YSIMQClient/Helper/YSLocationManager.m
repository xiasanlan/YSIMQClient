//
//  YSLocationManager.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/17.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSLocationManager.h"
#import "YSWeakObject.h"
#import "YSLocationConverter.h"

@implementation YSLocationModel

@end

@interface YSLocationManager()<CLLocationManagerDelegate>

@property(nonatomic,strong) CLLocationManager *locationManager;

@property (nonatomic,strong) CLGeocoder *Geocoder;

@property (nonatomic,strong) YSLocationModel *defaultLocation;

@property (nonatomic,strong) NSMutableArray<YSWeakObject *> *delegateArray;

@end

@implementation YSLocationManager

+ (instancetype)shareManager{
    static YSLocationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [YSLocationManager new];
    });
    return manager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _delegateArray = [NSMutableArray array];
        _defaultLocation = [YSLocationModel new];
    }
    return self;
}

- (void)startRequestLocation{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status || kCLAuthorizationStatusNotDetermined == status){
        return;
    }
    self.locationManager.delegate = self;
    self.locationManager.activityType = CLActivityTypeOther;
    //每隔多少米定位一次（这里的设置为任何的移动）
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    //设置定位的精准度，一般精准度越高，越耗电（这里设置为精准度最高的，适用于导航应用）
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //开始定位用户的位置
    [self.locationManager startUpdatingLocation];
}

- (void)reverseGeocodeLocation{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status || kCLAuthorizationStatusNotDetermined == status){
        return;
    }
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.defaultLocation.latitude longitude:self.defaultLocation.longitude];
    
    __weak typeof(self) weak_self = self;
    [self.Geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        __strong typeof(self) strong_self = weak_self;
        if ([placemarks count] > 0) {
            //这个是定位上的地标，还有对应的是地图上的地标
            CLPlacemark *placemark = placemarks[0];
            NSString *country = placemark.country?:@"";//国家
            NSString *administrativeArea = placemark.administrativeArea?:@"";//省份
            NSString *city = placemark.locality?:@"";//城市
            NSString *subLocality = placemark.subLocality?:@"";//区域
            NSString *thoroughfare = placemark.thoroughfare?:@"";//街道
            NSString *subThoroughfare = placemark.subThoroughfare?:@"";//子街道
            NSString *name = placemark.name?:@"";//详细名称
            NSString *str = [NSString stringWithFormat:@"%@%@%@%@%@%@%@",country,administrativeArea,city,subLocality,thoroughfare,subThoroughfare,name];
            strong_self.defaultLocation.location = str;
        }
    }];
}

#pragma mark - authen

#pragma mark - getter

- (CLLocationManager *)locationManager{
    if(_locationManager == nil){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;   //10米 精度
    }
    return _locationManager;
}

- (CLGeocoder *)Geocoder{
    if(_Geocoder == nil){
        _Geocoder = [[CLGeocoder alloc] init];
    }
    return _Geocoder;
}

#pragma mark - delegete

- (void)addDelegate:(id<YSLocationManagerDelegate>)delegate{
    [self removeEmptyDelegate];
    if([self containsDelegate:delegate]){
        return;
    }
    YSWeakObject *weakObject = [[YSWeakObject alloc] initWithWeakObject:delegate];
    [self.delegateArray addObject:weakObject];
}

- (void)removeDelegate:(id<YSLocationManagerDelegate>)delegate{
    [self removeEmptyDelegate];
    YSWeakObject *weakObject = [self weakObjectByDelegate:delegate];
    if(weakObject != nil){
        [self.delegateArray removeObject:weakObject];
    }
}

#pragma mark - common

//判断包含delegate
- (BOOL)containsDelegate:(id<YSLocationManagerDelegate>)delegate{
    BOOL isContains = NO;
    for (YSWeakObject *weakObject in self.delegateArray) {
        if(weakObject.weakObject && weakObject.weakObject == delegate){
            isContains = YES;
            break;
        }
    }
    return isContains;
}

//返回包含delegate的weakObject
- (YSWeakObject *)weakObjectByDelegate:(id<YSLocationManagerDelegate>)delegate{
    YSWeakObject *result = nil;
    for (YSWeakObject *weakObject in self.delegateArray) {
        if(weakObject.weakObject && weakObject.weakObject == delegate){
            result = weakObject;
            break;
        }
    }
    return result;
}

//移除空的delegate
- (void)removeEmptyDelegate{
    for (YSWeakObject *weakObject in self.delegateArray.copy) {
        if(weakObject.weakObject == nil){
            [self.delegateArray removeObject:weakObject];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

/**
 *  当定位到用户的位置时，就会调用（调用的频率比较频繁）
*/
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    manager.delegate = nil;
    //locations数组里边存放的是CLLocation对象，一个CLLocation对象就代表着一个位置
    CLLocation *loc = [locations lastObject];
    //坐标系转换
    CLLocationCoordinate2D coordinate = [YSLocationConverter wgs84ToGcj02:loc.coordinate];
    self.defaultLocation.latitude = coordinate.latitude;
    self.defaultLocation.longitude = coordinate.longitude;
    [self.locationManager stopUpdatingLocation];
    //逆地理编码
    [self reverseGeocodeLocation];
}


- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error{
    
}

@end
