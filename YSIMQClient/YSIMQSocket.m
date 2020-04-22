//
//  YSIMQSocket.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSIMQSocket.h"
#import "YSAsyncSocket.h"
#import "YSUtilities.h"
#import "NSTimer+YSWeak.h"
#import "YSIMQError.h"
#import "YSSafeArray.h"

#define SYSTEM_SAVE_TAG 9999

@interface YSIMQSocketWriteHandler : NSObject

//毫秒值
@property(nonatomic,copy) NSString *timestamp;

@property (nonatomic,strong) NSData *data;

//固定tag
@property(nonatomic,assign) NSInteger writeTag;

//外部调用tag
@property(nonatomic,assign) NSInteger tag;

@property(nonatomic,copy) YSResultBlock result;

@property(nonatomic,assign) BOOL isWrite;

@end

@implementation YSIMQSocketWriteHandler

- (instancetype)initWithData:(NSData *)data
                         tag:(NSInteger)tag
                      result:(YSResultBlock)result{
    self = [super init];
    if (self) {
        _data = data;
        _tag = tag;
        _result = result;
        _timestamp = [self g_timestamp];
    }
    return self;
}

- (NSString *)g_timestamp{
    NSDate *date = [NSDate date];
    long long dateTs = [date timeIntervalSince1970] * 1000;
    return [NSString stringWithFormat:@"%lld",dateTs];
}

@end

@interface YSIMQSocket()<YSAsyncSocketDelegate>

@property (nonatomic,strong) YSAsyncSocket *socket;

//发送心跳
@property (nonatomic,strong) NSTimer *heartbeatTimer;

//重连
@property (nonatomic,strong) NSTimer *reconnectTimer;

//连接状态
@property(nonatomic,assign) YSIMQSocketConnectedStatus connectedStatus;

//写入队列
@property (nonatomic,strong) YSSafeArray *writeQueue;

//内部重连次数
@property(nonatomic,assign) NSInteger socket_reconnectTimes;

//连接IP
@property(nonatomic,copy) NSString *host;

//连接端口号
@property(nonatomic,assign) uint16_t port;

//连接url
@property(nonatomic,copy) NSString *connectURL;

@end

@implementation YSIMQSocket

- (instancetype)init{
    if (self = [super init]) {
        _reconnectTimes = -1;
        _reconnectDuration = 3;
        _heartbeatDuration = 60;
        _writeDataTimeoutIntervals = 30;
        _writeQueue = [[YSSafeArray alloc] init];
    }
    return self;
}

#pragma mark - connect

- (void)releaseSocket{
    //释放上一次的连接
    if(self.socket){
        self.socket.delegate = nil;
        [self.socket disconnect];
        self.socket = nil;
    }
    [self stopReconnectTimer];
    [self stopHeartbeatTimer];
    [self.writeQueue removeAllObjects];
    //未连接
    self.connectedStatus = YSIMQSocketStatusUnconnected;
}

- (NSError *)connectWithHost:(NSString *)host onPort:(uint16_t)port{
    [self releaseSocket];
    self.socket = [[YSAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    return [self connectWithHost:host onPort:port urlString:nil];
}

- (NSError *)connectWithUrlString:(NSString *)urlString{
    [self releaseSocket];
    self.socket = [[YSAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    return [self connectWithHost:nil onPort:0 urlString:urlString];
}

//连接
- (NSError *)connectWithHost:(NSString *)host
                 onPort:(uint16_t)port
              urlString:(NSString *)urlString{
    if(host.length == 0 && urlString.length == 0){
        return [self generateErrorWithErrorCode:(YSIMQSocketErrorCodeParamsError)];
    }
    
    NSError *error = nil;
    //socket连接之前会尽一切检查 代理是否设置  端口是否为空  IP地址是否规范  对象是否提前释放等等
    BOOL isCheckPass = YES;
    if(host.length != 0){
        isCheckPass = [self.socket connectToHost:host onPort:port error:&error];
    }else{
        isCheckPass = [self.socket connectToUrl:[NSURL URLWithString:urlString] withTimeout:-1 error:&error];
    }
    
    if(error || !isCheckPass){
        if(error) return error;
        return [self generateErrorWithErrorCode:(YSIMQSocketErrorCodeUnknowError)];
    }
    
    
    _connectURL = urlString;
    _host = host;
    _port = port;
    
    //开始连接
    if(self.delegate && [self.delegate respondsToSelector:@selector(startConnectSocket:)]){
        [self.delegate startConnectSocket:self];
    }
    
    _connectedStatus = YSIMQSocketStatusConnecting;
    //连接中
    [self notifySetWithStatus:YSIMQSocketStatusConnecting];
    
    return nil;
}

//连接成功
- (void)didConnectSocket:(YSAsyncSocket *)socket{
    [self stopReconnectTimer];
    //重置重连次数
    self.socket_reconnectTimes = self.reconnectTimes;
    //首次连接
    if(self.connectedStatus == YSIMQSocketStatusConnecting){
        //已连接
        [self notifySetWithStatus:(YSIMQSocketStatusConnected)];
        [self callbackDidConnectSocket];
    }else{//断线重连成功
        [self.writeQueue removeAllObjects];
        //已连接
        [self notifySetWithStatus:(YSIMQSocketStatusReconnected)];
        [self callbackDidReconnectSocket];
    }
    [self startHeartbeatTimer];
}

//链接断开
- (void)didDisconnectSocket:(YSAsyncSocket *)sock withError:(NSError *)err{
    [self stopHeartbeatTimer];
    if(self.connectedStatus == YSIMQSocketStatusDisConnectByUser){
        [self notifySetWithStatus:(YSIMQSocketStatusDisConnectByUser)];
        [self releaseSocket];
    }else{
        [self notifySetWithStatus:(YSIMQSocketStatusDisConnectByOther)];
        [self startReconnectTimer];
    }
    [self callbackDisConnectSocket:err];
}

#pragma mark - disconnect

- (void)disconnectNone{
    [self.socket disconnect];
}

- (void)disconnect{
    self.connectedStatus = YSIMQSocketStatusDisConnectByUser;
    [self.socket disconnect];
}

- (void)disconnectAfterReading{
    self.connectedStatus = YSIMQSocketStatusDisConnectByUser;
    [self.socket disconnectAfterReading];
}

- (void)disconnectAfterWriting{
    self.connectedStatus = YSIMQSocketStatusDisConnectByUser;
    [self.socket disconnectAfterWriting];
}

- (void)disconnectAfterReadingAndWriting{
    self.connectedStatus = YSIMQSocketStatusDisConnectByUser;
    [self.socket disconnectAfterReadingAndWriting];
}

#pragma mark - timer methods

- (void)startHeartbeatTimer{
    if(_heartbeatTimer){
        [_heartbeatTimer invalidate];
        _heartbeatTimer = nil;
    }
    // init heartbeatTimer
    ys_weak(self);
    _heartbeatTimer = [NSTimer ys_scheduledTimerWithTimeInterval:self.heartbeatDuration block:^(NSTimer * _Nonnull timer) {
        ys_strong(self);
        [self heartbeatMethod];
    } repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_heartbeatTimer forMode:NSRunLoopCommonModes];
}

- (void)stopHeartbeatTimer{
    if(_heartbeatTimer){
        [_heartbeatTimer invalidate];
        _heartbeatTimer = nil;
    }
}

- (void)startReconnectTimer{
    if(_reconnectTimer){
        [_reconnectTimer invalidate];
        _reconnectTimer = nil;
    }
    // init heartbeatTimer
    ys_weak(self);
    _reconnectTimer = [NSTimer ys_scheduledTimerWithTimeInterval:self.reconnectDuration block:^(NSTimer * _Nonnull timer) {
        ys_strong(self);
        [self reconnectMethod];
    } repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_reconnectTimer forMode:NSRunLoopCommonModes];
}

- (void)stopReconnectTimer{
    if(_reconnectTimer){
        [_reconnectTimer invalidate];
        _reconnectTimer = nil;
    }
}

- (void)heartbeatMethod{
    if(self.delegate && [self.delegate respondsToSelector:@selector(heartbeatWithSocket:)]){
        NSData *data = [self.delegate heartbeatWithSocket:self];
        if(data){
            [self.socket writeData:data withTimeout:-1 tag:-1];
        }
    }
}

- (void)reconnectMethod{
    if(self.socket_reconnectTimes < 0){
        [self reconnect];
    }else{
        if(self.socket_reconnectTimes == 0){
            [self stopReconnectTimer];
            [self releaseSocket];
            self.socket_reconnectTimes = self.reconnectTimes;
        }else{
            self.socket_reconnectTimes--;
            [self reconnect];
        }
    }
}

- (void)reconnect{
    if(self.connectURL.length == 0 && self.host.length == 0){
        [self stopReconnectTimer];
        [self releaseSocket];
        self.socket_reconnectTimes = self.reconnectTimes;
        return;
    }
    
    NSError *error = nil;
    //socket连接之前会尽一切检查 代理是否设置  端口是否为空  IP地址是否规范  对象是否提前释放等等
    BOOL isCheckPass = YES;
    
    if(self.connectURL.length != 0){
        isCheckPass = [self.socket connectToUrl:[NSURL URLWithString:self.connectURL] withTimeout:-1 error:&error];
    }else if (self.host.length != 0){
        isCheckPass = [self.socket connectToHost:self.host onPort:self.port error:&error];
    }
    
    if(error || !isCheckPass){
        return;
    }
    
    //开始重新连接
    if(self.delegate && [self.delegate respondsToSelector:@selector(startReconnectSocket:)]){
        [self.delegate startReconnectSocket:self];
    }
    
    _connectedStatus = YSIMQSocketStatusReconnecting;
    //连接中
    [self notifySetWithStatus:YSIMQSocketStatusReconnecting];
}

#pragma mark - message methods

- (void)writeMessageWithData:(NSData *)data tag:(NSInteger)tag{
    [self writeMessageWithData:data tag:tag result:nil];
}

- (void)writeMessageWithData:(NSData *)data
                      result:(YSResultBlock)result{
    [self writeMessageWithData:data tag:0 result:result];
}

- (void)writeMessageWithData:(NSData *)data
                         tag:(NSInteger)tag
                      result:(YSResultBlock)result{
    if(!self.socket.isConnected){
        NSError *error = [NSError errorWithDomain:@"ys_socket_write" code:-1003 userInfo:@{@"message":@"socket暂未连接"}];
        if(result){
            result(nil,error);
        }else{
            if(self.delegate && [self.delegate respondsToSelector:@selector(socket:writeDataTag:occurError:)]){
                [self.delegate socket:self writeDataTag:tag occurError:error];
            }
        }
        return;
    }
    YSIMQSocketWriteHandler *writeHandler = [[YSIMQSocketWriteHandler alloc] initWithData:data tag:tag result:result];
    
    NSInteger writeTag = 0;
    BOOL flag = YES;
    do {
        writeTag = arc4random()%LONG_MAX;
        flag = [self containsTag:writeTag];
    } while (flag);
    
    writeHandler.writeTag = writeTag;
    [self.writeQueue addObject:writeHandler];
    [self maybeCanWriteData];
}

- (void)writeMessageWithData:(NSData *)data{
    if(!self.socket.isConnected){
        return;
    }
    [self.socket writeData:data withTimeout:self.writeDataTimeoutIntervals tag:SYSTEM_SAVE_TAG];
}

- (void)maybeCanWriteData{
    [self.writeQueue enumerateObjectsUsingBlock:^(YSIMQSocketWriteHandler *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(!obj.isWrite){
            obj.isWrite = YES;
            [self.socket writeData:obj.data withTimeout:self.writeDataTimeoutIntervals tag:obj.writeTag];
        }
    }];
}

#pragma mark - helper methods

- (YSIMQError *)generateErrorWithErrorCode:(YSIMQSocketErrorCode)errorCode{
    YSIMQError *error = [[YSIMQError alloc] initWithErrorCode:errorCode message:YSIMQErrorQuery(errorCode)];
    return error;
}

- (void)notifySetWithStatus:(YSIMQSocketConnectedStatus)status{
    _connectedStatus = status;
    if(self.delegate && [self.delegate respondsToSelector:@selector(connectedStatusChanged:)]){
        [self.delegate connectedStatusChanged:status];
    }
}

- (void)callbackDidConnectSocket{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didConnectSocket:)]){
        [self.delegate didConnectSocket:self];
    }
}

- (void)callbackDidReconnectSocket{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didReconnectSocket:)]){
        [self.delegate didReconnectSocket:self];
    }
}

- (void)callbackDisConnectSocket:(NSError *)error{
    if(self.delegate && [self.delegate respondsToSelector:@selector(disconnectSocket:occurError:)]){
        [self.delegate disconnectSocket:self occurError:error];
    }
}

- (BOOL)containsTag:(long)writeTag{
    if(writeTag == SYSTEM_SAVE_TAG){
        return YES;
    }
    __block BOOL flag = NO;
    [self.writeQueue enumerateObjectsUsingBlock:^(YSIMQSocketWriteHandler *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.writeTag == writeTag){
            flag = YES;
            *stop = YES;
        }
    }];
    return flag;
}

- (YSIMQSocketWriteHandler *)writeHandlerByTag:(long)writeTag{
    __block YSIMQSocketWriteHandler *handler = nil;
    [self.writeQueue enumerateObjectsUsingBlock:^(YSIMQSocketWriteHandler *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.writeTag == writeTag){
            handler = obj;
            *stop = YES;
        }
    }];
    return handler;
}

#pragma mark - GCDAsyncSocketDelegate

//已连接
- (void)socket:(YSAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    [self didConnectSocket:sock];
    //监听读取数据
    [self.socket readDataWithTimeout:-1 tag:0];
}

//已连接
- (void)socket:(YSAsyncSocket *)sock didConnectToUrl:(NSURL *)url{
    YSLog(@"已连接");
    [self didConnectSocket:sock];
    //监听读取数据
    [self.socket readDataWithTimeout:-1 tag:0];
}

//断开连接
- (void)socketDidDisconnect:(YSAsyncSocket *)sock withError:(nullable NSError *)err{
    YSLog(@"断开连接");
    [self didDisconnectSocket:sock withError:err];
}

//读取数据
- (void)socket:(YSAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if(self.delegate && [self.delegate respondsToSelector:@selector(socket:didReadData:)]){
        [self.delegate socket:self didReadData:data];
    }
    // 读取到服务端数据值后,能再次读取
    [self.socket readDataWithTimeout:- 1 tag:0];
}

//发送成功
- (void)socket:(YSAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    YSIMQSocketWriteHandler *handler = [self writeHandlerByTag:tag];
    if(handler && handler.result){
        id json = [YSUtilities generateResponseDicWithData:nil responseCode:@"200" message:@"发送成功"];
        handler.result(json, nil);
    }else{
        if(tag != SYSTEM_SAVE_TAG && self.delegate && [self.delegate respondsToSelector:@selector(socket:didWriteDataWithTag:)]){
            [self.delegate socket:self didWriteDataWithTag:handler.tag];
        }
    }
    [self.writeQueue removeObject:handler];
}

//发送信息超时
- (NSTimeInterval)socket:(YSAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    id error = [self generateErrorWithErrorCode:(YSIMQSocketErrorCodeWriteTimeout)];
    YSIMQSocketWriteHandler *handler = [self writeHandlerByTag:tag];
    if(handler && handler.result){
        handler.result(nil, error);
    }else{
        if(self.delegate && [self.delegate respondsToSelector:@selector(socket:writeDataTag:occurError:)]){
            [self.delegate socket:self writeDataTag:handler.tag occurError:error];
        }
    }
    [self.writeQueue removeObject:handler];
    return 0;
}

//消息读取已被关闭
- (void)socketDidCloseReadStream:(YSAsyncSocket *)sock{
    
}

//在套接字成功完成SSL/TLS协议之后调用
- (void)socketDidSecure:(YSAsyncSocket *)sock{
    
}

//SSL/TSL证书信任成功
- (void)socket:(YSAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler{
    
}

@end
