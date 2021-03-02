//
//  TCPClient.m
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import "TCPClient.h"
#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>

static TCPClient *_singleInstance = nil;

@implementation TCPClient

#pragma mark - 单例

+ (instancetype)sharedInstance
{
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _singleInstance = [super allocWithZone:zone];
    });
    return _singleInstance;
}

- (instancetype)init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _singleInstance = [super init];
        if (_singleInstance) {
            // 在这里初始化self的属性和方法
        }
    });
    return _singleInstance;
}


#pragma mark - 对象方法

- (void)connectWithHost:(NSString *)host port:(int)port {
    
    struct sockaddr_in server_addr;
    bzero(&server_addr, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(host.UTF8String);
    
    self.socketFD = socket(AF_INET, SOCK_STREAM, 0);    // SOCK_STREAM为TCP，SOCK_DGRAM为UDP，SOCK_RAW为IP
    if (self.socketFD < 0) {
        perror("socket error \n");
        return;
    }

    int ret = connect(self.socketFD, (struct sockaddr *)&server_addr, sizeof(struct sockaddr_in));
    if (ret < 0) {
        perror("connect error \n");
        if ([self.delegate respondsToSelector:@selector(TCPClientEvent:message:)]) {
            [self.delegate TCPClientEvent:TCPClientEvent_ConnectFailed message:@"connect error"];
        }
        return;
    }
    
    printf("connect success \n");
    if ([self.delegate respondsToSelector:@selector(TCPClientEvent:message:)]) {
        [self.delegate TCPClientEvent:TCPClientEvent_Connected message:@"connect success"];
    }
    
    char buffer[1024];
    self.bStop = NO;
    while (1) {
        if (self.bStop) break;
        bzero(buffer, 1024);
        ssize_t byte_num = recv(self.socketFD, buffer, 1024, 0);     // 阻塞直到收到数据
        if (byte_num > 0) {
            buffer[byte_num] = '\0';
            printf("receive: %s\n", buffer);
            if ([self.delegate respondsToSelector:@selector(TCPClientEvent:message:)]) {
                [self.delegate TCPClientEvent:TCPClientEvent_ReceiveData message:[NSString stringWithFormat:@"receive: %s", buffer]];
            }
        }
    }
}


- (void)disconnect {
    
    self.bStop = YES;
    close(self.socketFD);
}


- (void)send:(NSData *)data {
    
    ssize_t ret = send(self.socketFD, (char *)data.bytes, data.length, 0);
    if (ret < 0) {
        perror("send error \n");
        if ([self.delegate respondsToSelector:@selector(TCPClientEvent:message:)]) {
            [self.delegate TCPClientEvent:TCPClientEvent_SendError message:@"send error"];
        }
    }else {
        printf("send data: %s\n", (char *)data.bytes);
        if ([self.delegate respondsToSelector:@selector(TCPClientEvent:message:)]) {
            [self.delegate TCPClientEvent:TCPClientEvent_SendSuccess message:[NSString stringWithFormat:@"send: %s", (char *)data.bytes]];
        }
    }

}


@end
