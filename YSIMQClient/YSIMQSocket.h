//
//  YSIMQSocket.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSIMQClientDefine.h"

typedef void(^YSResultBlock)(id _Nullable json,NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@class YSIMQSocket;
@protocol YSIMQSocketDelegate <NSObject>

@optional

//开始连接
- (void)startConnectSocket:(YSIMQSocket *)socket;

//连接成功
- (void)didConnectSocket:(YSIMQSocket *)socket;

//连接断开
- (void)disconnectSocket:(YSIMQSocket *)socket occurError:(NSError *)error;

//开始重连
- (void)startReconnectSocket:(YSIMQSocket *)socket;

//重连成功
- (void)didReconnectSocket:(YSIMQSocket *)socket;

//连接状态变更
- (void)connectedStatusChanged:(YSIMQSocketConnectedStatus)status;

//询问心跳数据 不实现代理或返回nil不发心跳包
//可发送空data
- (NSData *)heartbeatWithSocket:(YSIMQSocket *)socket;

//读取数据
- (void)socket:(YSIMQSocket *)socket didReadData:(NSData *)data;

//发送成功  使用带有result的方法发送信息 不会收到代理回调
- (void)socket:(YSIMQSocket *)sock didWriteDataWithTag:(long)tag;

//发送失败  使用带有result的方法发送信息 不会收到代理回调
- (void)socket:(YSIMQSocket *)sock writeDataTag:(long)tag occurError:(NSError *)error;

@end

@interface YSIMQSocket : NSObject

//断线重连执行次数  默认-1重复执行
@property(nonatomic,assign) NSInteger reconnectTimes;

//重连间隔  默认3s
@property(nonatomic,assign) NSInteger reconnectDuration;

//心跳间隔  默认60s
@property(nonatomic,assign) NSInteger heartbeatDuration;

//发送数据超时时间 默认30s  如果想无限等待请设置为-1
@property(nonatomic,assign) NSInteger writeDataTimeoutIntervals;

//连接状态
@property(nonatomic,assign,readonly) YSIMQSocketConnectedStatus connectedStatus;

//代理
@property (nonatomic,weak) id<YSIMQSocketDelegate> delegate;

/// 连接
/// @param host 主机ip地址
/// @param port 开放端口号
- (NSError *)connectWithHost:(NSString *)host
                 onPort:(uint16_t)port;


/// 连接
/// @param urlString 登录url
- (NSError *)connectWithUrlString:(NSString *)urlString;

///强行断开连接
- (void)disconnectNone;

/// 断开连接
- (void)disconnect;


/// 接收信息完成后断开连接
- (void)disconnectAfterReading;


/// 发送信息完成后断开连接
- (void)disconnectAfterWriting;


/// 收发信息完成后断开连接
- (void)disconnectAfterReadingAndWriting;

/// 发送消息
/// @param data 无回调
- (void)writeMessageWithData:(NSData *)data;

/// 发送消息
/// @param data 消息流
/// @param tag 标识  delegate回调中返回用于标记  可用于数组等操作
- (void)writeMessageWithData:(NSData *)data tag:(NSInteger)tag;


/// 发送消息
/// @param data 消息流
/// @param result 回调blcok 此方法不会触发代理回调
- (void)writeMessageWithData:(NSData *)data
                      result:(YSResultBlock)result;

@end

NS_ASSUME_NONNULL_END
