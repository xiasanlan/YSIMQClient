//
//  YSSafeArray.m
//  IMQClient
//
//  Created by 何冰的Mac on 2020/4/10.
//  Copyright © 2020 山楂树. All rights reserved.
//

#import "YSSafeArray.h"

#define INIT(...) self = super.init; \
if (!self) return nil; \
__VA_ARGS__; \
if (!_arr) return nil; \
_lock = dispatch_semaphore_create(1); \
return self;


#define LOCK(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);


@implementation YSSafeArray {
    NSMutableArray *_arr;  //Subclass a class cluster...
    dispatch_semaphore_t _lock;
}

#pragma mark - init

- (instancetype)init {
    INIT(_arr = [[NSMutableArray alloc] init]);
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
    INIT(_arr = [[NSMutableArray alloc] initWithCapacity:numItems]);
}

- (instancetype)initWithArray:(NSArray *)array {
    INIT(_arr = [[NSMutableArray alloc] initWithArray:array]);
}

- (instancetype)initWithObjects:(const id[])objects count:(NSUInteger)cnt {
    INIT(_arr = [[NSMutableArray alloc] initWithObjects:objects count:cnt]);
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    INIT(_arr = [[NSMutableArray alloc] initWithContentsOfFile:path]);
}

- (instancetype)initWithContentsOfURL:(NSURL *)url {
    INIT(_arr = [[NSMutableArray alloc] initWithContentsOfURL:url]);
}

#pragma mark - method

- (NSUInteger)count {
    LOCK(NSUInteger count = _arr.count); return count;
}

- (id)objectAtIndex:(NSUInteger)index {
    LOCK(id obj = [_arr objectAtIndex:index]); return obj;
}

- (BOOL)containsObject:(id)anObject {
    LOCK(BOOL c = [_arr containsObject:anObject]); return c;
}

- (NSUInteger)indexOfObject:(id)anObject {
    LOCK(NSUInteger i = [_arr indexOfObject:anObject]); return i;
}

- (id)firstObject {
    LOCK(id o = _arr.firstObject); return o;
}

- (id)lastObject {
    LOCK(id o = _arr.lastObject); return o;
}

- (void)enumerateObjectsUsingBlock:(void (^)(id _Nonnull, NSUInteger, BOOL * _Nonnull)) __attribute__((noescape)) block{
    LOCK([_arr enumerateObjectsUsingBlock:block]);
}

#pragma mark - mutable

- (void)addObject:(id)anObject {
    LOCK([_arr addObject:anObject]);
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    LOCK([_arr removeObjectAtIndex:index]);
}

- (void)addObjectsFromArray:(NSArray *)otherArray {
    LOCK([_arr addObjectsFromArray:otherArray]);
}

- (void)removeAllObjects {
    LOCK([_arr removeAllObjects]);
}

- (void)removeObject:(id)anObject {
    if(anObject){
        LOCK([_arr removeObject:anObject]);
    }
}

#pragma mark - protocol

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;
    
    if ([object isKindOfClass:YSSafeArray.class]) {
        YSSafeArray *other = object;
        BOOL isEqual;
        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(other->_lock, DISPATCH_TIME_FOREVER);
        isEqual = [_arr isEqual:other->_arr];
        dispatch_semaphore_signal(other->_lock);
        dispatch_semaphore_signal(_lock);
        return isEqual;
    }
    return NO;
}

- (NSUInteger)hash {
    LOCK(NSUInteger hash = [_arr hash]);
    return hash;
}

@end
