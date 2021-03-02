//
//  UDPSocket.h
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UDPSocket;
@protocol UDPSocketDelegate <NSObject>
@optional
- (void)showMessage:(NSString *)message;
@end

@interface UDPSocket : NSObject

@property (nonatomic, weak) id<UDPSocketDelegate>   delegate;

+ (instancetype)sharedInstance;

- (void)listen:(int)port;
- (void)send:(NSData *)data host:(NSString *)host port:(UInt16)port;

@end

NS_ASSUME_NONNULL_END
