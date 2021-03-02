//
//  TCPClient.h
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TCPClientEvent) {
    TCPClientEvent_Connected,
    TCPClientEvent_ConnectFailed,
    TCPClientEvent_SendSuccess,
    TCPClientEvent_SendError,
    TCPClientEvent_ReceiveData,
};

@protocol TCPClientDelegate <NSObject>
@optional
- (void)TCPClientEvent:(TCPClientEvent)event message:(NSString *)message;
@end

@interface TCPClient : NSObject

@property (nonatomic, weak) id<TCPClientDelegate>   delegate;
@property (nonatomic, assign) int  socketFD;
@property (nonatomic, assign) BOOL bStop;

+ (instancetype)sharedInstance;

- (void)connectWithHost:(NSString *)host port:(int)port;
- (void)disconnect;
- (void)send:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
