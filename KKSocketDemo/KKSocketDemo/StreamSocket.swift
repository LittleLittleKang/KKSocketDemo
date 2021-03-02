//
//  StreamSocket.swift
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/2/26.
//

import UIKit


protocol StreamSocketDelegate {
    func eventCode(eventCode: Stream.Event)
    func received(data: Data)
}


class StreamSocket: NSObject, StreamDelegate {

    static let shared = StreamSocket()  // 单例
    var delegate: StreamSocketDelegate?
    var iSream: InputStream?
    var oStream: OutputStream?
    

    // 创建socket连接
    func create(host: String, port: UInt32) {
        print(#function)
    
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        // 创建socket连接
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host as CFString, port, &readStream, &writeStream)
        // 转换成 InputStream & OutputStream 对象
        self.iSream = readStream?.takeRetainedValue()
        self.oStream = writeStream?.takeRetainedValue()
        
        if self.iSream == nil {
            print("Erro read")
            return
        }
        
        if self.oStream == nil {
            print("Erro write")
            return
        }
        
        self.iSream!.delegate = self
        self.oStream!.delegate = self
        
        self.iSream!.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
        self.oStream!.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
        self.iSream!.open()
        self.oStream!.open()
    }
    
    
    // 关闭socket连接
    func close() {
        
        self.iSream?.close()
        self.oStream?.close()
    }
    
    
    // 发送数据
    func send(data: Data) {
        
        guard self.oStream != nil,
              self.oStream?.hasSpaceAvailable == true
        else {
            print("no space available")
            return
        }
        
        let bytes = [UInt8](data)
        self.oStream?.write(bytes, maxLength: data.count)
    }
    
    
    //MARK: - StreamDelegate
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        self.delegate?.eventCode(eventCode: eventCode)
        
        switch eventCode {
        
            case .openCompleted:        // 打开完毕
                print(#function, "openCompleted")
                break
                
            case .hasBytesAvailable:    // 可读
                print(#function, "hasBytesAvailable")
                
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
                while (aStream as! InputStream).hasBytesAvailable {
                    let numberOfBytesRead = (aStream as! InputStream).read(buffer, maxLength: 4096)
                    if numberOfBytesRead < 0 { break }
                    let data = Data(bytes: buffer, count: numberOfBytesRead)
                    self.delegate?.received(data: data)
                }
                
                break
            
            case .hasSpaceAvailable:    // 可写
                print(#function, "hasSpaceAvailable")
                break
                
            case .errorOccurred:        // 发生错误
                print(#function, "errorOccurred", "error: \(String(describing: aStream.streamError))")
                break
                
            case .endEncountered:       // 结束
                print(#function, "endEncountered")
                break
                
            default:
                break
        }
    }
}
