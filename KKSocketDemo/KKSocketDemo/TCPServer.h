//
//  TCPServer.h
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TCPServerEvent) {
    TCPServerEvent_Error,
    TCPServerEvent_Listen,
    TCPServerEvent_Accept,
    TCPServerEvent_Send,
    TCPServerEvent_Receive
};

@protocol TCPServerDelegate <NSObject>
@optional
- (void)TCPServerEvent:(TCPServerEvent)event message:(NSString *)message;
@end

@interface TCPServer : NSObject

@property (nonatomic, weak) id<TCPServerDelegate>   delegate;
@property (nonatomic, assign) int  server_socket;
@property (nonatomic, assign) int  client_socket;
@property (nonatomic, assign) BOOL bStop;

+ (instancetype)sharedInstance;

- (void)listenWithHost:(NSString *)host port:(int)port;
- (void)stop;
- (void)send:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
