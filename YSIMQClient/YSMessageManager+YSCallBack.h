//
//  YSMessageManager+YSCallBack.h
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/21.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSMessageManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSMessageManager (YSCallBack)

- (void)didReveiveMessage:(YSMessage *)message;

- (void)didSendMessageWithTag:(NSInteger)tag error:(NSError * __nullable)error;

- (void)didLoginWithUserId:(NSString *)userId userName:(NSString *)userName error:(NSError * __nullable)error;

- (void)didReLoginWithUserId:(NSString *)userId userName:(NSString *)userName error:(NSError * __nullable)error;

- (void)didEnterRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError * __nullable)error;

- (void)didReEnterRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError * __nullable)error;

- (void)didLeaveRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError * __nullable)error;

- (void)connectStatusChanged:(YSIMQSocketConnectedStatus)status;

@end

NS_ASSUME_NONNULL_END
