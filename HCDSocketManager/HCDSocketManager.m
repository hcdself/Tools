//
//  HCDSocketManager.m
//  SocketDemo
//
//  Created by henry on 2018/12/13.
//  Copyright © 2018 henry. All rights reserved.
//

#import "HCDSocketManager.h"
#import "SRWebSocket.h"

@interface HCDSocketManager ()<SRWebSocketDelegate>

@property (nonatomic, copy) NSString *ursString;
@property (nonatomic, strong) SRWebSocket *webSocket;

@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, assign) NSInteger currentReconnectCount;

@end

@implementation HCDSocketManager

+(instancetype)sharedManager {
    static HCDSocketManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HCDSocketManager alloc] init];
        manager.reconnectMaxCount = 5;
        manager.reconnectIntervalTime = 1;
    });
    return manager;
}

- (void)open:(NSString *)urlStr connect:(HCDSocketConnectedBlock)connect receive:(HCDSocketReceivedBlock)receive failure:(HCDSocketFailureBlock)failure {
    self.ursString = urlStr;
    self.connectedBlock = connect;
    self.receivedBlock  = receive;
    self.failureBlock   = failure;
    
    [self.webSocket close];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSURL *url = [NSURL URLWithString:self.ursString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)sendMessage:(id)data {
    [self.webSocket send:data];
}

#pragma mark - private method

- (void)addReconnectTimer {
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
    self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:self.reconnectIntervalTime target:self selector:@selector(reconnect) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.reconnectTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

- (void)reconnect {

    if (self.currentReconnectCount >= self.reconnectMaxCount-1) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
        return;
    }
    
    [self.webSocket close];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSURL *url = [NSURL URLWithString:self.ursString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.webSocket.delegate = self;
    
    self.currentReconnectCount++;
}

#pragma mark - SRWebSocket delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    self.connectedBlock?self.connectedBlock():nil;
    self.status = HCDSocketStatusConnected;
    _currentReconnectCount = 0;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    self.receivedBlock ?self.receivedBlock(message):nil;
    self.status = HCDSocketStatusReceived;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    self.failureBlock?self.failureBlock(error):nil;
    self.status = HCDSocketStatusFailure;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    self.status = reason ? HCDSocketStatusClosedByServer:HCDSocketStatusClosedByUser;
    
    if (reason) {
        self.status = HCDSocketStatusClosedByServer;
        [self addReconnectTimer];
    } else {
        self.status = HCDSocketStatusClosedByUser;
    }
    self.closedBlock?self.closedBlock(code,reason,wasClean):nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
}

- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket {
    return YES;
}

@end
