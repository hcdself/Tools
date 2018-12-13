//
//  HCDSocketManager.h
//  SocketDemo
//
//  Created by henry on 2018/12/13.
//  Copyright © 2018 henry. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HCDSocketConnectedBlock)(void);
typedef void(^HCDSocketReceivedBlock)(id message);
typedef void(^HCDSocketFailureBlock)(NSError *error);
typedef void(^HCDSocketClosedBlock)(NSInteger code,NSString *reason,BOOL wasClean);

typedef enum : NSUInteger {
    HCDSocketStatusConnected,
    HCDSocketStatusReceived,
    HCDSocketStatusClosedByServer,
    HCDSocketStatusClosedByUser,
    HCDSocketStatusFailure,
} HCDSocketStatus;

NS_ASSUME_NONNULL_BEGIN

@interface HCDSocketManager : NSObject

@property (nonatomic, assign) HCDSocketStatus status;
@property (nonatomic, copy) HCDSocketConnectedBlock connectedBlock;
@property (nonatomic, copy) HCDSocketReceivedBlock receivedBlock;
@property (nonatomic, copy) HCDSocketFailureBlock failureBlock;
@property (nonatomic, copy) HCDSocketClosedBlock closedBlock;

@property (nonatomic, assign) NSInteger reconnectMaxCount;
@property (nonatomic, assign) NSInteger reconnectIntervalTime;

+ (instancetype)sharedManager;

- (void)open:(NSString *)urlStr connect:(HCDSocketConnectedBlock)connect receive:(HCDSocketReceivedBlock)receive failure:(HCDSocketFailureBlock)failure;
- (void)sendMessage:(id)data;

@end

NS_ASSUME_NONNULL_END
