//
//  YSMessageManager.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/20.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSMessageManager.h"
#import "YSWeakObject.h"
#import "YSMessageList.pbobjc.h"

@interface YSMessageManager()

@property (nonatomic,strong) NSMutableArray<YSWeakObject *> *delegateQueue;

@end

@implementation YSMessageManager

+ (instancetype)shareManager{
    static YSMessageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YSMessageManager alloc] init];
    });
    return manager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _delegateQueue = [NSMutableArray array];
    }
    return self;
}

- (void)addDelegate:(id<YSMessageManagerDelegate>)delegate{
    if(!delegate) return;
    if(![self containsDelegate:delegate]){
        YSWeakObject *wk = [[YSWeakObject alloc] initWithWeakObject:delegate];
        [self.delegateQueue addObject:wk];
    }
}

- (void)removeDelegate:(id<YSMessageManagerDelegate>)delegate{
    if(!delegate) return;
    YSWeakObject *wk = [self containsDelegate:delegate];
    if(wk){
        [self.delegateQueue removeObject:wk];
    }
}

- (YSWeakObject *)containsDelegate:(id<YSMessageManagerDelegate>)delegate{
    for (YSWeakObject *wk in self.delegateQueue) {
        if(wk.weakObject == delegate){
            return wk;
        }
    }
    return nil;
}

#pragma mark - callBack

- (void)didSendMessageWithTag:(NSInteger)tag error:(nonnull NSError *)error{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didSendMessageWithTag:error:)]){
            [delegate didSendMessageWithTag:tag error:error];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didSendMessageWithTag:error:)]){
        [self.delegate didSendMessageWithTag:tag error:error];
    }
}

- (void)didReveiveMessage:(YSMessage *)message{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didReveiveMessage:)]){
            [delegate didReveiveMessage:message];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didReveiveMessage:)]){
        [self.delegate didReveiveMessage:message];
    }
}

- (void)didLoginWithUserId:(NSString *)userId userName:(NSString *)userName error:(NSError *)error{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didLoginWithUserId:userName:error:)]){
            [delegate didLoginWithUserId:userId userName:userName error:error];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didLoginWithUserId:userName:error:)]){
        [self.delegate didLoginWithUserId:userId userName:userName error:error];
    }
}

- (void)didReLoginWithUserId:(NSString *)userId userName:(NSString *)userName error:(NSError *)error{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didReLoginWithUserId:userName:error:)]){
            [delegate didReLoginWithUserId:userId userName:userName error:error];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didReLoginWithUserId:userName:error:)]){
        [self.delegate didReLoginWithUserId:userId userName:userName error:error];
    }
}

//用户进入房间成功
- (void)didEnterRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError *)error{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didEnterRoomWithGroupId:groupName:error:)]){
            [delegate didEnterRoomWithGroupId:groupId groupName:groupName error:error];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didEnterRoomWithGroupId:groupName:error:)]){
        [self.delegate didEnterRoomWithGroupId:groupId groupName:groupName error:error];
    }
}

//用户进入房间成功
- (void)didReEnterRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError *)error{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didReEnterRoomWithGroupId:groupName:error:)]){
            [delegate didReEnterRoomWithGroupId:groupId groupName:groupName error:error];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didReEnterRoomWithGroupId:groupName:error:)]){
        [self.delegate didReEnterRoomWithGroupId:groupId groupName:groupName error:error];
    }
}

- (void)didLeaveRoomWithGroupId:(NSString *)groupId groupName:(NSString *)groupName error:(NSError * __nullable)error{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(didLeaveRoomWithGroupId:groupName:error:)]){
            [delegate didLeaveRoomWithGroupId:groupId groupName:groupName error:error];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didLeaveRoomWithGroupId:groupName:error:)]){
        [self.delegate didLeaveRoomWithGroupId:groupId groupName:groupName error:error];
    }
}

- (void)connectStatusChanged:(YSIMQSocketConnectedStatus)status{
    NSArray *array = self.delegateQueue.copy;
    for (YSWeakObject *object in array) {
        id<YSMessageManagerDelegate> delegate = object.weakObject;
        if(delegate && [delegate respondsToSelector:@selector(connectStatusChanged:)]){
            [delegate connectStatusChanged:status];
        }else{
            [self.delegateQueue removeObject:object];
        }
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(connectStatusChanged:)]){
        [self.delegate connectStatusChanged:status];
    }
}

@end
