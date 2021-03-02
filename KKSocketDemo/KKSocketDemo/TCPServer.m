//
//  TCPServer.m
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/3/2.
//

#import "TCPServer.h"
#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>

static TCPServer *_singleInstance = nil;

@implementation TCPServer

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

- (void)listenWithHost:(NSString *)host port:(int)port {
    
    struct sockaddr_in server_addr;
    bzero(&server_addr, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(host.UTF8String);
    
    self.server_socket = socket(AF_INET, SOCK_STREAM, 0);    // SOCK_STREAM为TCP，SOCK_DGRAM为UDP，SOCK_RAW为IP
    if (self.server_socket < 0) {
        perror("socket error \n");
        if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
            [self.delegate TCPServerEvent:TCPServerEvent_Error message:@"socket success"];
        }
        return;
    }

    // 绑定socket
    int res = bind(self.server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (res < 0) {
        perror("bind error");
        if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
            [self.delegate TCPServerEvent:TCPServerEvent_Error message:@"bind error"];
        }
        return;
    }
    
    // 监听
    if (listen(self.server_socket, 5) == -1) {
        perror("listen error");
        if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
            [self.delegate TCPServerEvent:TCPServerEvent_Error message:@"listen error"];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
        [self.delegate TCPServerEvent:TCPServerEvent_Listen message:@"listen success"];
    }

    // 接收客户端地址
    struct sockaddr_in client_addr;
    socklen_t addr_len;
    self.client_socket = accept(self.server_socket, (struct sockaddr *)&client_addr, &addr_len);
    if (self.client_socket == -1) {
        perror("accept error");
        if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
            [self.delegate TCPServerEvent:TCPServerEvent_Error message:@"accept error"];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
        [self.delegate TCPServerEvent:TCPServerEvent_Accept message:@"accept success"];
    }
    
    char recv_msg[1024];
    self.bStop = NO;
    // 循环读取数据
    while (1) {
        if (self.bStop) break;
        bzero(recv_msg, 1024);
        long byte_num = recv(self.client_socket, recv_msg, 1024, 0);
        if (byte_num > 0) {
            recv_msg[byte_num] = '\0';
            printf("receive: %s\n", recv_msg);
            if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
                [self.delegate TCPServerEvent:TCPServerEvent_Receive message:[NSString stringWithFormat:@"receive: %s", recv_msg]];
            }
        }
    }
}


- (void)stop {
    
    self.bStop = YES;
    close(self.server_socket);
    close(self.client_socket);
}


- (void)send:(NSData *)data {
    
    ssize_t ret = send(self.client_socket, (char *)data.bytes, data.length, 0);
    if (ret < 0) {
        perror("send error \n");
        if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
            [self.delegate TCPServerEvent:TCPServerEvent_Error message:@"send error"];
        }
    }else {
        printf("send data: %s\n", (char *)data.bytes);
        if ([self.delegate respondsToSelector:@selector(TCPServerEvent:message:)]) {
            [self.delegate TCPServerEvent:TCPServerEvent_Send message:[NSString stringWithFormat:@"send: %s", (char *)data.bytes]];
        }
    }
}


@end
