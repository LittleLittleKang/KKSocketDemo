//
//  UDPSocket.m
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import "UDPSocket.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

static UDPSocket *_singleInstance = nil;

@implementation UDPSocket

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

- (void)send:(NSData *)data host:(NSString *)host port:(UInt16)port {
    
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(host.UTF8String);  // 如需广播，使用htonl(INADDR_BROADCAST);，等价inet_addr(“255.255.255.255”);。只能在局域网广播，路由器不做转发。
    
    int socketFD = socket(AF_INET, SOCK_DGRAM, 0);    // SOCK_STREAM为TCP，SOCK_DGRAM为UDP，SOCK_RAW为IP
    if (socketFD < 0) {
        perror("socket error \n");
        return;
    }

    // 开启广播服务
    const int broadcast = 1;
    int status = setsockopt(socketFD, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));
    if (status < 0)
    {
        printf("Error enabling address reuse (setsockopt)");
        if ([self.delegate respondsToSelector:@selector(UDPSocketEvent:message:)]) {
            [self.delegate UDPSocketEvent:UDPSocketEvent_Message message:@"Error enabling address reuse (setsockopt)"];
        }
        close(socketFD);
        return;
    }
    
    ssize_t ret = sendto(socketFD, data.bytes, data.length, 0, (sockaddr *)&addr, sizeof(addr));
    if (ret < 0)
    {
        printf("error in sendto() function. ret=%ld \n", ret);
        if ([self.delegate respondsToSelector:@selector(UDPSocketEvent:message:)]) {
            [self.delegate UDPSocketEvent:UDPSocketEvent_Message message:@"error in sendto() function."];
        }
        close(socketFD);
        return;
    }
    printf("send: %s \n", data.bytes);
    if ([self.delegate respondsToSelector:@selector(UDPSocketEvent:message:)]) {
        [self.delegate UDPSocketEvent:UDPSocketEvent_Message message:[NSString stringWithFormat:@"send: %s", data.bytes]];
    }
}


- (void)listen:(int)port {

    self.socket_server = socket(AF_INET, SOCK_DGRAM, 0);    // SOCK_STREAM为TCP，SOCK_DGRAM为UDP，SOCK_RAW为IP
    if (self.socket_server < 0) {
        perror("socket error \n");
        if ([self.delegate respondsToSelector:@selector(UDPSocketEvent:message:)]) {
            [self.delegate UDPSocketEvent:UDPSocketEvent_ListenError message:@"socket error \n"];
        }
        return;
    }
    
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);     // 等价inet_addr("0.0.0.0");
    
    int status = bind(self.socket_server, (sockaddr *)&addr, sizeof(addr));
    if (status < 0)
    {
        printf("error in bind() function \n");
        if ([self.delegate respondsToSelector:@selector(UDPSocketEvent:message:)]) {
            [self.delegate UDPSocketEvent:UDPSocketEvent_ListenError message:@"error in bind() function \n"];
        }
        close(self.socket_server);
        return;
    }
    
    char recv_msg[1024];
    while (1) {
        bzero(recv_msg, 1024);
        
        long byte_num = recv(self.socket_server, recv_msg, 1024, 0);
        recv_msg[byte_num] = '\0';
        printf("receive: %s\n", recv_msg);
        if ([self.delegate respondsToSelector:@selector(UDPSocketEvent:message:)]) {
            [self.delegate UDPSocketEvent:UDPSocketEvent_Message message:[NSString stringWithFormat:@"receive: %s", recv_msg]];
        }
    }
}


- (void)stop {
    
    close(self.socket_server);
}

@end
