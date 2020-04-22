//
//  YSMessageManager.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/20.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSMessage.pbobjc.h"
#import "YSIMQClientDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YSMessageManagerDelegate <NSObject>

@optional

//发送信息成功的回调  使用带有result的方法并且result不为空时不会触发代理回调
- (void)didSendMessageWithTag:(NSInteger)tag error:(NSError *)error;

//并发过高同一时刻收到的消息是数组返回
- (void)didReveiveMessage:(YSMessage *)message;

//用户登录成功
- (void)didLoginWithUserId:(NSString *)userId userName:(NSString *)userName error:(NSError *)error;

//用户重登成功 断线重连 SDK自行处理
- (void)didReLoginWithUserId:(NSString *)userId userName:(NSString *)userName error:(NSError *)error;

//用户进入房间
- (void)didEnterRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError *)error;

//重新进入房间 断线重连 SDK自行处理
- (void)didReEnterRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError *)error;

//用户离开房间
- (void)didLeaveRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError *)error;

//连接状态变更
- (void)connectStatusChanged:(YSIMQSocketConnectedStatus)status;

@end

@class YSMessageList;

@interface YSMessageManager : NSObject

//单例代理
@property (nonatomic,weak) id<YSMessageManagerDelegate> delegate;

+ (instancetype)shareManager;

//以下两个方法成对出现

//一般在控制器创建视图加载viewDidLoad中添加自身
- (void)addDelegate:(id<YSMessageManagerDelegate>)delegate;

//一般在控制器销毁remove自身 内部做了weak处理 不写这句也没事
- (void)removeDelegate:(id<YSMessageManagerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
