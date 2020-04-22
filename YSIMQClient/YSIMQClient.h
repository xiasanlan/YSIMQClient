//
//  YSIMQClient.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/7.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSIMQClientDefine.h"

NS_ASSUME_NONNULL_BEGIN

#define YSSocketIPPotter @"http://119.3.175.237:30200/api/machine/getAppNode"

@interface YSIMQClient : NSObject

/// 客户端注册 会生成client单例
/// @param appCode 应用标识
/// @param productId 租户ID
+ (void)registerClientWithAPPCode:(NSString *)appCode productId:(NSString *)productId;


/// 多租户切换
/// @param appCode 应用标识
/// @param productId 租户ID
+ (void)changeAPPCode:(NSString *)appCode productId:(NSString *)productId;


/// 客户端解绑 注销单例
+ (void)unRegisterClient;


#pragma mark - login


//用户id 用户名 token令牌未登录状态时自己生成 （游客登录）

/// 注册并登陆用户 或者用于切换用户 （直播间游客切真实用户）
/// @param userId 用户id
/// @param userName 用户昵称
/// @param token 登录颁发的token
/// @param result 回调
+ (void)loginWithUserId:(NSString *)userId
               userName:(NSString *)userName
                  token:(NSString *)token
                 result:(void(^)(id _Nullable json,NSError * _Nullable error))result;


/// 注册并登陆用户 或者用于切换用户 （直播间游客切真实用户）  代理回调
/// @param userId 用户id
/// @param userName 用户昵称
/// @param token 登录颁发的token
+ (void)loginWithUserId:(NSString *)userId
               userName:(NSString *)userName
                  token:(NSString *)token;


///退出登录 （清空存储信息userid groupid等信息,断开socket链接）
+ (void)quit;


//获取连接状态
+ (YSIMQSocketConnectedStatus)connectedStatus;


///是否连接成功
+ (BOOL)isConnected;


#pragma mark - live

/// 进入直播间/聊天室
/// @param groupId 直播间Id
/// @param groupName 直播间名称
/// @param result 回调
+ (void)enterRoomWithGroupId:(NSString *)groupId
                   groupName:(NSString *)groupName
                      result:(void(^)(id _Nullable json,NSError * _Nullable error))result;


/// 进入直播间/聊天室  代理回调
/// @param groupId 直播间Id
/// @param groupName 直播间名称
+ (void)enterRoomWithGroupId:(NSString *)groupId
                   groupName:(NSString *)groupName;



/// 离开直播间/聊天室
/// @param groupId 直播间Id
/// @param result 回调
+ (void)leaveRoomWithGroupId:(NSString *)groupId
                      result:(void(^)(id _Nullable json,NSError * _Nullable error))result;


/// 离开直播间/聊天室  代理回调
/// @param groupId 直播间Id
+ (void)leaveRoomWithGroupId:(NSString *)groupId;



/// 发送群组信息  用于用户自定义信息发送
/// @param messageId 平台掉接口获取 或者生成UUID
/// @param groupId 组id（直播间 群聊等）
/// @param action 动作标识 参见文档定义 也可与后端自定义
/// @param title 消息标题
/// @param content 消息体和format共用
/// @param format 定制content的格式text,json ,xml
/// @param sender 消息发送者（用户id 等）
/// @param extra 附加消息
/// @param result 信息发送成功的回调  result不为空时，代理不会执行
+ (void)sendGroupMessageWithMessageId:(NSString *)messageId
                              groupId:(NSString *)groupId
                               action:(NSString *)action
                                title:(NSString *)title
                              content:(NSString *)content
                               format:(NSString *)format
                               sender:(NSString *)sender
                                extra:(NSString *)extra
                               result:(void(^)(id _Nullable json,NSError * _Nullable error))result;


/// 发送群组信息  用于用户自定义信息发送
/// @param messageId 平台掉接口获取 或者生成UUID
/// @param groupId 组id（直播间 群聊等）
/// @param action 动作标识 参见文档定义 也可与后端自定义
/// @param title 消息标题
/// @param content 消息体和format共用
/// @param format 定制content的格式text,json ,xml
/// @param sender 消息发送者（用户id 等）
/// @param extra 附加消息
/// @param tag 回调标识 方便用户 例：数组下标等  didSendMessageWithTag:方法回调
+ (void)sendGroupMessageWithMessageId:(NSString *)messageId
                              groupId:(NSString *)groupId
                               action:(NSString *)action
                                title:(NSString *)title
                              content:(NSString *)content
                               format:(NSString *)format
                               sender:(NSString *)sender
                                extra:(NSString *)extra
                                  tag:(NSInteger)tag;


- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
