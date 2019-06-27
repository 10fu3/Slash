//
//  Network.swift
//  River
//
//  Created by 10fu3 on 2019/05/19.
//  Copyright © 2019 10fu3. All rights reserved.
//

import Foundation
import UIKit

public class HttpClientImpl{
    
    private let session: URLSession
    
    public init(config: URLSessionConfiguration? = nil) {
        self.session = config.map { URLSession(configuration: $0) } ?? URLSession.shared
    }
    
    public func execute(request: URLRequest) -> (NSData?, URLResponse?, NSError?) {
        var d: NSData? = nil
        var r: URLResponse? = nil
        var e: NSError? = nil
        let semaphore = DispatchSemaphore(value: 0)
        session
            .dataTask(with: request) { (data, response, error) -> Void in
                d = data as NSData?
                r = response
                e = error as NSError?
                semaphore.signal()
            }
            .resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return (d, r, e)
    }
    
    public func convertImage(url:String) -> (data:Data,image:UIImage?) {
        let data = getDatafromHTTP(url: url)
        return (data,UIImage(data: data) ?? UIImage())
    }
    
    public func getStringData(url:String,encode:String.Encoding)->[String]{
        let data = getDatafromHTTP(url: url)
        
        var string = String.init(data: data, encoding: encode)?.replacingOccurrences(of: "<b>", with: "")
        if((string == nil || string!.count == 0) && encode == .shiftJIS){
            string = getStringDataWithCP932(data: data as NSData).replacingOccurrences(of: "<b>", with: "")
        }
        return string?.components(separatedBy: "\n") ?? []
    }
    
    public func getStringData(url:String,encode:String.Encoding)->String{
        let data = getDatafromHTTP(url: url)
        
        var string = String.init(data: data, encoding: encode)?.replacingOccurrences(of: "<b>", with: "")
        if((string == nil || string!.count == 0) && encode == .shiftJIS){
            string = getStringDataWithCP932(data: data as NSData).replacingOccurrences(of: "<b>", with: "")
        }
        return string ?? ""
    }
    
    public func getStringDataWithCP932(data:NSData)->String{
        let SJISMultiCheck :(UInt8)->Bool = {c in
            if(((c>=0x81)&&(c<=0x9f))||((c>=0xe0)&&(c<=0xfc))){
                return true
            }else{
                return false
            }
        }
        
        var result = ""
        var byte = [UInt8](repeating: 0, count: 1)
        
        var temp = [UInt8]()
        
        let length = data.count / MemoryLayout<UInt8>.size
        
        var count = 0
        while count<length {
            
            var flag = true
            
            while flag {
                temp = []
                data.getBytes(&byte, range: NSRange(location: count, length: MemoryLayout<UInt8>.size))
                temp.append(byte[0])
                if(SJISMultiCheck(temp[0])){
                    //下の行が実行された段階でbyteの中身は更新される
                    data.getBytes(&byte, range: NSRange(location: count+1, length: MemoryLayout<UInt8>.size))
                    temp.append(byte[0])
                    count += MemoryLayout<UInt8>.size
                }
                let line = String(bytes: temp, encoding: String.Encoding.shiftJIS) ?? "�"
                
                if(line.count > 0){
                    flag = false
                    result += line
                    //print(line)
                }
                
                count += MemoryLayout<UInt8>.size
            }
        }
        return result
    }
    
    public func getDatafromHTTP(url:String) -> Data {
        let url = URL(string: url)!
        let req = NSMutableURLRequest(url: url)
        req.httpMethod = "HEAD"
        let (head, res, _) = execute(request: (req as URLRequest))
        
        //50MB超えで空データ 画像爆弾が効かないように
        if(((res as? HTTPURLResponse)?.expectedContentLength ?? 0) > 51200000){
            return Data()
        }
        
        req.httpMethod = "GET"
        let (rawdata, _, _) = execute(request: (req as URLRequest))
        
        if rawdata != nil{
            return Data.init(referencing: rawdata ?? NSData())
        }
        return Data()
    }
    
    func getDataByUrl(url: String) -> Data{
        return getDatafromHTTP(url: url)
//        let url = URL(string: url)
//        do {
//
//            let data = try Data(contentsOf: url!)
//            return data
//        } catch let err {
//            print("Error : \(err.localizedDescription)")
//        }
//        return Data()
    }
}
