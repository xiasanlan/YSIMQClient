//
//  YSIMQClientDefine.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/8.
//  Copyright © 2020 山楂树. All rights reserved.
//

#ifndef YSIMQClientDefine_h
#define YSIMQClientDefine_h

/*********************** enumeration *************************/

typedef NS_ENUM(NSInteger, YSIMQSocketConnectedStatus) {
    YSIMQSocketStatusUnconnected = 0,    //未连接
    YSIMQSocketStatusConnecting,         //连接中
    YSIMQSocketStatusConnected,          //已连接
    YSIMQSocketStatusDisConnectByUser,   //用户主动断开连接
    YSIMQSocketStatusDisConnectByOther,  //连接被迫断开
    YSIMQSocketStatusReconnecting,       //重连中
    YSIMQSocketStatusReconnected         //重连成功
};

typedef NS_ENUM(NSInteger, YSIMQSocketErrorCode) {
    YSIMQSocketErrorCodeUnknowError = 100000,   //未知错误
    YSIMQSocketErrorCodeParamsError = 100001,   //初始化参数错误
    YSIMQSocketErrorCodeWriteTimeout = 100002   //信息发送超时
};

static NSString *YSIMQSocketErrorDescription[4] = {
    @"code 100000 未知错误",
    @"code 100001 连接IP或域名不正确",
    @"code 100002 write message timeout"
};

//主域名 生产域名
static inline NSString * YSIMQErrorQuery(YSIMQSocketErrorCode errorCode){
    NSInteger i = errorCode - 100000;
    NSString *errorDes = YSIMQSocketErrorDescription[i];
    return errorDes;
}

/*********************** log *************************/

#ifdef DEBUG
# define YSLog(fmt, ...) NSLog((@"\nfile-->%s\n" "func-->%s\n" "line-->%d \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define YSLog(...);
#endif


/*********************** code blocks *************************/

#define ys_lock(sem) dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

#define ys_unlock(sem) dispatch_semaphore_signal(sem);

#define ys_weak(object) __weak typeof(object) weak##_##object = object

#define ys_strong(object) __strong typeof(weak##_##object) object = weak##_##object


#endif /* YSIMQClientDefine_h */
