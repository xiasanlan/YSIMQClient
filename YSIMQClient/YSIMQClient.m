//
//  YSIMQClient.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSIMQClient.h"
#import "YSIMQSocket.h"
#import "YSCustomInformation.h"
#import "YSIMQError.h"
#import "YSSendBody.pbobjc.h"
#import "YSMessage.pbobjc.h"
#import "YSReplyBody.pbobjc.h"
#import "YSUtilities.h"
#import "YSMessageList.pbobjc.h"
#import "YSMessageManager.h"
#import "YSMessageManager+YSCallBack.h"

typedef NS_ENUM(NSInteger, YSIMQMessageType) {
    YSIMQMessageType_C_H_RS = 0,  //客户端心跳响应
    YSIMQMessageType_S_H_RQ,      //服务端心跳请求
    YSIMQMessageType_MESSAGE,     //服务端推送的消息
    YSIMQMessageType_SENT_BODY,   //客户端发送的sendBody请求
    YSIMQMessageType_REPLY_BODY,  //sentBody请求的异步响应replyBody
};

@interface YSIMQClient()<YSIMQSocketDelegate>

@property(nonatomic,copy) NSString *appCode;

@property(nonatomic,copy) NSString *productId;

@property (nonatomic,strong) YSIMQSocket *clientSocket;

@property(nonatomic,copy) NSString *groupId;

@property(nonatomic,copy) NSString *groupName;

@property(nonatomic,copy) NSString *userId;

@property(nonatomic,copy) NSString *userName;

@property(nonatomic,copy) NSString *token;

@property(nonatomic,copy) void(^enterRoomResult)(id _Nullable json,NSError * _Nullable error);

@property(nonatomic,copy) void(^loginResult)(id _Nullable json,NSError * _Nullable error);

@property(nonatomic,copy) void(^leaveRoomResult)(id _Nullable json,NSError * _Nullable error);

@end

static YSIMQClient *_client = nil;
static dispatch_once_t onceToken;

@implementation YSIMQClient

+ (instancetype)shareClient{
    dispatch_once(&onceToken, ^{
        _client = [[YSIMQClient alloc] initClient];
    });
    return _client;
}

- (instancetype)initClient{
    if(self = [super init]){
        _clientSocket = [[YSIMQSocket alloc] init];
        _clientSocket.delegate = self;
    }
    return self;
}

#pragma mark - mmL

+ (YSIMQSocketConnectedStatus)connectedStatus{
    return _client.clientSocket.connectedStatus;
}

+ (BOOL)isConnected{
    return _client.clientSocket.connectedStatus == YSIMQSocketStatusConnected || _client.clientSocket.connectedStatus == YSIMQSocketStatusReconnected;
}

#pragma mark - register

+ (void)registerClientWithAPPCode:(NSString *)appCode productId:(NSString *)productId{
    if(_client != nil){
        //解除绑定
        [YSIMQClient unRegisterClient];
    }
    _client = [YSIMQClient shareClient];
    _client.appCode = appCode;
    _client.productId = productId;
    //隐式获取信息
    [[YSCustomInformation defaultInformation] collectionInformation];
}

+ (void)changeAPPCode:(NSString *)appCode productId:(NSString *)productId{
    _client.appCode = appCode;
    _client.productId = productId;
    //隐式获取信息
    [[YSCustomInformation defaultInformation] collectionInformation];
}

+ (void)unRegisterClient{
    [self quit];
    _client = nil;
    onceToken = 0;
}

#pragma mark - connect

+ (void)loginWithUserId:(NSString *)userId
               userName:(NSString *)userName
                  token:(NSString *)token{
    [self loginWithUserId:userId userName:userName token:token result:nil];
}

+ (void)loginWithUserId:(NSString *)userId
               userName:(NSString *)userName
                  token:(NSString *)token
                 result:(void (^)(id _Nullable, NSError * _Nullable))result{
    _client.userId = userId;
    _client.userName = userName;
    _client.token = token;
    _client.loginResult = nil;
    [YSIMQClient getIPPotter:^(id  _Nullable json, NSError * _Nullable error) {
        if(error){
            if(result){
                result(nil,error);
            }
        }else{
            //链接节点
            NSString *ipor = [json[@"nodeList"] lastObject];
            NSArray *arr = [ipor componentsSeparatedByString:@":"];
            NSString *ip = [YSIMQClient getIporsWithArray:arr index:0];
            NSString *po = [YSIMQClient getIporsWithArray:arr index:1];
            NSInteger port = 0;
            if(po.length > 0){
                port = [po integerValue];
            }
            NSError *error = [_client.clientSocket connectWithHost:ip onPort:port];
            if(error){
                if(result){
                    result(nil,error);
                }
            }else{
                _client.loginResult = result;
            }
        }
    }];
}

+ (void)quit{
    YSSendMessage *sendBody = [[YSSendMessage alloc] init];
    sendBody.key = @"client_closed";
    sendBody.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSData *data = [YSIMQClient createSendData:sendBody.data type:(YSIMQMessageType_SENT_BODY)];
    [_client.clientSocket writeMessageWithData:data];
    [_client.clientSocket disconnectAfterWriting];
    _client.userId = nil;
    _client.userName = nil;
    _client.token = nil;
    _client.loginResult = nil;
    _client.groupId = nil;
    _client.groupName = nil;
    _client.enterRoomResult = nil;
}

#pragma mark - roomChat

+ (void)enterRoomWithGroupId:(NSString *)groupId
                   groupName:(NSString *)groupName{
    [self enterRoomWithGroupId:groupId groupName:groupName result:nil];
}

+ (void)enterRoomWithGroupId:(NSString *)groupId
                   groupName:(NSString *)groupName
                      result:(void(^)(id _Nullable json,NSError * _Nullable error))result{
    _client.groupId = groupId;
    _client.groupName = groupName;
    _client.enterRoomResult = nil;
    YSSendMessage *sendBody = [[YSSendMessage alloc] init];
    sendBody.key = @"join_group";
    [sendBody.data_p setValue:_client.groupId?:@"" forKey:@"groupId"];
    [sendBody.data_p setValue:_client.groupName?:@"" forKey:@"groupName"];
    sendBody.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    NSData *data = [YSIMQClient createSendData:sendBody.data type:(YSIMQMessageType_SENT_BODY)];
    [_client.clientSocket writeMessageWithData:data result:^(id  _Nullable json, NSError * _Nullable error) {
        if(error){
            if(result){
                result(nil, error);
            }
        }else{
            _client.enterRoomResult = result;
        }
    }];
}

+ (void)leaveRoomWithGroupId:(NSString *)groupId{
    [self leaveRoomWithGroupId:groupId result:nil];
}

+ (void)leaveRoomWithGroupId:(NSString *)groupId
                      result:(void (^)(id _Nullable, NSError * _Nullable))result{
    _client.leaveRoomResult = nil;
    YSSendMessage *sendBody = [[YSSendMessage alloc] init];
    sendBody.key = @"quit_group";
    [sendBody.data_p setValue:_client.groupId?:@"" forKey:@"groupId"];
    sendBody.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSData *data = [YSIMQClient createSendData:sendBody.data type:(YSIMQMessageType_SENT_BODY)];
    [_client.clientSocket writeMessageWithData:data result:^(id  _Nullable json, NSError * _Nullable error) {
        if(error){
            if(result){
                result(nil, error);
            }
        }else{
            _client.leaveRoomResult = result;
        }
    }];
}

- (void)clientBlind{
    YSCustomInformation *information = [YSCustomInformation defaultInformation];
    YSSendMessage *sendBody = [[YSSendMessage alloc] init];
    sendBody.key = @"client_bind";
    [sendBody.data_p setValue:_client.appCode?:@"" forKey:@"appCode"];
    [sendBody.data_p setValue:_client.productId?:@"" forKey:@"companyId"];
    [sendBody.data_p setValue:_client.userId?:@"" forKey:@"userId"];
    [sendBody.data_p setValue:_client.userName forKey:@"userName"];
    [sendBody.data_p setValue:_client.token?:@"" forKey:@"token"];
    [sendBody.data_p setValue:information.deviceId?:@"" forKey:@"deviceId"];
    [sendBody.data_p setValue:information.channel?:@"" forKey:@"channel"];
    [sendBody.data_p setValue:information.deviceModel?:@"" forKey:@"deviceModel"];
    [sendBody.data_p setValue:information.clientVersion?:@"" forKey:@"clientVersion"];
    [sendBody.data_p setValue:information.systemVersion?:@"" forKey:@"systemVersion"];
    
    //经纬度
    NSString *longitude = [NSString stringWithFormat:@"%lf",information.longitude];
    NSString *latitude = [NSString stringWithFormat:@"%lf",information.latitude];
    [sendBody.data_p setValue:latitude?:@"" forKey:@"latitude"];
    [sendBody.data_p setValue:longitude?:@"" forKey:@"longitude"];
    [sendBody.data_p setValue:information.location?:@"" forKey:@"location"];
    sendBody.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    NSData *data = [YSIMQClient createSendData:sendBody.data type:(YSIMQMessageType_SENT_BODY)];
    [_client.clientSocket writeMessageWithData:data result:^(id  _Nullable json, NSError * _Nullable error) {
        if(error){
            if(_client.loginResult){
                _client.loginResult(nil, error);
                _client.loginResult = nil;
            }
        }
    }];
}

+ (void)sendGroupMessageWithMessageId:(NSString *)messageId
                              groupId:(NSString *)groupId
                               action:(NSString *)action
                                title:(NSString *)title
                              content:(NSString *)content
                               format:(NSString *)format
                               sender:(NSString *)sender
                                extra:(NSString *)extra
                               result:(void(^)(id _Nullable json,NSError * _Nullable error))result{
    [self sendGroupMessageWithMessageId:messageId groupId:groupId action:action title:title content:content format:format sender:sender extra:extra tag:0 result:result];
}

+ (void)sendGroupMessageWithMessageId:(NSString *)messageId
                              groupId:(NSString *)groupId
                               action:(NSString *)action
                                title:(NSString *)title
                              content:(NSString *)content
                               format:(NSString *)format
                               sender:(NSString *)sender
                                extra:(NSString *)extra
                                  tag:(NSInteger)tag{
    [self sendGroupMessageWithMessageId:messageId groupId:groupId action:action title:title content:content format:format sender:sender extra:extra tag:tag result:nil];
}

+ (void)sendGroupMessageWithMessageId:(NSString *)messageId
                              groupId:(NSString *)groupId
                               action:(NSString *)action
                                title:(NSString *)title
                              content:(NSString *)content
                               format:(NSString *)format
                               sender:(NSString *)sender
                                extra:(NSString *)extra
                                  tag:(NSInteger)tag
                               result:(void(^)(id _Nullable json,NSError * _Nullable error))result{
    YSSendMessage *sendBody = [[YSSendMessage alloc] init];
    sendBody.key = @"message";
    sendBody.message.messageId = messageId;
    sendBody.message.groupId = groupId;
    sendBody.message.action = action;
    sendBody.message.title = title;
    sendBody.message.content = content;
    sendBody.message.format = format;
    sendBody.message.sender = sender;
    sendBody.message.extra = extra;
    sendBody.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSData *data = [YSIMQClient createSendData:sendBody.data type:(YSIMQMessageType_SENT_BODY)];
    if(result){
        [_client.clientSocket writeMessageWithData:data result:result];
    }else{
        [_client.clientSocket writeMessageWithData:data tag:tag];
    }
}

#pragma mark - unititles

+ (void)getIPPotter:(void(^)(id _Nullable json,NSError * _Nullable error))result{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:YSSocketIPPotter]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:20];
    
    NSData *emptyData = [@" " dataUsingEncoding:NSUTF8StringEncoding];
    // 设置请求体
    [request setHTTPBody:emptyData];
        
    // 设置本次请求的提交数据格式
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // 设置本次请求请求体的长度(因为服务器会根据你这个设定的长度去解析你的请求体中的参数内容)
    [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)emptyData.length] forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                if(result){
                    result(dic,nil);
                }
            }else{
                if(result){
                    result(nil,error);
                }
            }
        });
    }];
    [task resume];
}

+ (YSIMQError *)generateErrorWithErrorCode:(YSIMQSocketErrorCode)errorCode{
    YSIMQError *error = [[YSIMQError alloc] initWithErrorCode:errorCode message:YSIMQErrorQuery(errorCode)];
    return error;
}

+ (NSString *)getIporsWithArray:(NSArray *)array index:(NSInteger)index{
    if(index < 0 || index > array.count - 1){
        return @"";
    }
    return [array objectAtIndex:index];
}

/*
 创建data 服务器需求小端序
 */
+ (NSData *)createSendData:(NSData *)data type:(YSIMQMessageType)type{
    NSMutableData *resultData = [NSMutableData data];
    NSInteger bodyLength = data.length;
    Byte byteData[2] = {};
    byteData[0] =(Byte)((bodyLength & 0xFF00)>>8);
    byteData[1] =(Byte)((bodyLength & 0x00FF));
    
    Byte bytes[3] = {};
    bytes[0] = type;
    bytes[1] = byteData[1];
    bytes[2] = byteData[0];
    
    [resultData appendBytes:bytes length:3];
    [resultData appendData:data];
    return resultData;
}


#pragma mark - YSIMQSocketDelegate

//开始连接
- (void)startConnectSocket:(YSIMQSocket *)socket{
    
}

//连接成功
- (void)didConnectSocket:(YSIMQSocket *)socket{
    //注册用户
    [_client clientBlind];
}

//连接断开
- (void)disconnectSocket:(YSIMQSocket *)socket occurError:(NSError *)error{
    
}

//开始重连
- (void)startReconnectSocket:(YSIMQSocket *)socket{
    
}

//重连成功
- (void)didReconnectSocket:(YSIMQSocket *)socket{
    //发送绑定消息
    [_client clientBlind];
}

//连接状态变更
- (void)connectedStatusChanged:(YSIMQSocketConnectedStatus)status{
    [[YSMessageManager shareManager] connectStatusChanged:status];
}

//询问心跳数据 不实现代理或返回nil不发心跳包
//可发送空data
- (NSData *)heartbeatWithSocket:(YSIMQSocket *)socket{
    return nil;
}

//读取数据
- (void)socket:(YSIMQSocket *)socket didReadData:(NSData *)data{
    Byte *byteArray = (Byte *)data.bytes;
    if(data.length < 3){
        return;
    }
    NSInteger type = byteArray[0];
    NSInteger length = ((byteArray[2] << 8) | byteArray[1]);
    if(length + 3 != data.length) return;
    NSData *subData = [data subdataWithRange:NSMakeRange(3, data.length - 3)];
    NSError *error = nil;
    if(type == YSIMQMessageType_S_H_RQ){
        YSLog(@"收到心跳");
        NSData *crData = [@"CR" dataUsingEncoding:NSUTF8StringEncoding];//字符串转化成 data
        NSData *responseData = [YSIMQClient createSendData:crData type:(YSIMQMessageType_C_H_RS)];
        [_client.clientSocket writeMessageWithData:responseData];
    }else if (type == YSIMQMessageType_MESSAGE){
        YSLog(@"收到消息");
        YSMessageList *bodys = [YSMessageList parseFromData:subData error:&error];
        for (YSMessage *message in bodys.msgListArray) {
            if([message.action isEqualToString:@"1"]){
                [socket disconnectNone];
                break;
            }
            [[YSMessageManager shareManager] didReveiveMessage:message];
        }
    }else if (type == YSIMQMessageType_REPLY_BODY){
        YSLog(@"收到系统回复");
        YSResponseMessage *body = [YSResponseMessage parseFromData:subData error:&error];
        if([body.key isEqualToString:@"client_bind"]){
            NSDictionary *dic = [YSUtilities generateResponseDicWithData:nil responseCode:body.code message:body.message];
            //绑定
            if([dic[@"code"] integerValue] == 200){
                if(_client.groupId.length != 0 && _client.clientSocket.connectedStatus == YSIMQSocketStatusReconnected){
                    [YSIMQClient enterRoomWithGroupId:_client.groupId groupName:_client.groupName result:nil];
                }
            }else{
                _client.userName = nil;
                _client.userId = nil;
                _client.token = nil;
            }
            
            if(_client.loginResult){
                _client.loginResult(dic, nil);
                _client.loginResult = nil;
            }else{
                NSError *error = nil;
                if([dic[@"code"] integerValue] != 200){
                    error = [NSError errorWithDomain:@"ys_socket_login" code:[dic[@"code"] integerValue] userInfo:@{@"message":dic[@"message"]?:@""}];
                }
                if(_client.clientSocket.connectedStatus == YSIMQSocketStatusConnected){
                    [[YSMessageManager shareManager] didLoginWithUserId:_client.userId userName:_client.userName error:error];
                }else{
                    [[YSMessageManager shareManager] didReLoginWithUserId:_client.userId userName:_client.userName error:error];
                }
            }
        }else if ([body.key isEqualToString:@"join_group"]){
            NSDictionary *dic = [YSUtilities generateResponseDicWithData:nil responseCode:body.code message:body.message];
            //执行进入直播间 断线重连 切换用户
            if([dic[@"code"] integerValue] != 200){
                _client.groupName = nil;
                _client.groupId = nil;
            }
            if(_client.enterRoomResult){
                _client.enterRoomResult(dic, nil);
                _client.enterRoomResult = nil;
            }else{
                NSError *error = nil;
                if([dic[@"code"] integerValue] != 200){
                    error = [NSError errorWithDomain:@"ys_socket_login" code:[dic[@"code"] integerValue] userInfo:@{@"message":dic[@"message"]?:@""}];
                }
                if(_client.clientSocket.connectedStatus == YSIMQSocketStatusConnected){
                    [[YSMessageManager shareManager] didEnterRoomWithGroupId:_client.groupId groupName:_client.groupName error:error];
                }else{
                    [[YSMessageManager shareManager] didReEnterRoomWithGroupId:_client.groupId groupName:_client.groupName error:error];
                }
            }
        }else if ([body.key isEqualToString:@"quit_group"]){
            NSDictionary *dic = [YSUtilities generateResponseDicWithData:nil responseCode:body.code message:body.message];
            if([dic[@"code"] integerValue] == 200){
                _client.groupName = nil;
                _client.groupId = nil;
            }
            if(_client.leaveRoomResult){
                _client.leaveRoomResult(dic, nil);
                _client.leaveRoomResult = nil;
            }else{
                NSError *error = nil;
                if([dic[@"code"] integerValue] != 200){
                    error = [NSError errorWithDomain:@"ys_socket_login" code:[dic[@"code"] integerValue] userInfo:@{@"message":dic[@"message"]?:@""}];
                }
                [[YSMessageManager shareManager] didLeaveRoomWithGroupId:_client.groupId groupName:_client.groupName error:error];
            }
        }
    }
}

//发送成功  使用带有result的方法发送信息 不会收到代理回调
- (void)socket:(YSIMQSocket *)sock didWriteDataWithTag:(long)tag{
    [[YSMessageManager shareManager] didSendMessageWithTag:tag error:nil];
}

//发送失败  使用带有result的方法发送信息 不会收到代理回调
- (void)socket:(YSIMQSocket *)sock writeDataTag:(long)tag occurError:(NSError *)error{
    [[YSMessageManager shareManager] didSendMessageWithTag:tag error:error];
}

@end
