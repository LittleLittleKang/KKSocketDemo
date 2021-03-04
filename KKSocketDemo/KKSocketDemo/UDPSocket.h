//
//  UDPSocket.h
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UDPSocketEvent) {
    UDPSocketEvent_ListenError,
    UDPSocketEvent_Message,
};

@protocol UDPSocketDelegate <NSObject>
@optional
- (void)UDPSocketEvent:(UDPSocketEvent)event message:(NSString *)message;
@end

@interface UDPSocket : NSObject

@property (nonatomic, weak) id<UDPSocketDelegate>   delegate;
@property (nonatomic, assign)   int socket_server;

+ (instancetype)sharedInstance;

- (void)listen:(int)port;
- (void)stop;
- (void)send:(NSData *)data host:(NSString *)host port:(UInt16)port;

@end

NS_ASSUME_NONNULL_END
