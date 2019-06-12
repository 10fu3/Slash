//
//  Parse.swift
//  River
//
//  Created by 10fu3 on 2019/05/19.
//  Copyright © 2019 10fu3. All rights reserved.
//

import Foundation
import UIKit
import Ji

extension String {
    
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}


class Pattern {
    static let pettern = Pattern()
    static let anchorRegex:NSRegularExpression = try! NSRegularExpression(pattern: "(((>>?|＞＞?)\\d+(\\s*(>>?|＞＞?|,|-)\\d+){0,})|(>>?|＞＞?)(\\d+)-(\\d+)|(>>?|＞＞?)\\d+((>>?|＞＞?|,|-)\\d+)+)", options: .caseInsensitive)
    static let resCountRegex:NSRegularExpression = try! NSRegularExpression(pattern: "\\(.+?\\)", options: .caseInsensitive)
    
    static let categoryTitle = try! NSRegularExpression(pattern: "(?i)<BR><BR><B>(.+?)</B><BR>", options: [])
    
    static let boardurl = try! NSRegularExpression(pattern: "<A HREF=(.+?)>", options: [])
    static let boardname = try! NSRegularExpression(pattern: "/>(.+?)</A>", options: [])

    
    static let httpregex = try! NSRegularExpression(pattern: "https?://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$", options: .caseInsensitive)
    static let ttpregex = try! NSRegularExpression(pattern: "ttps?://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$", options: .caseInsensitive)
    static let pictureRegex = try! NSRegularExpression(pattern: "https?:\\S+\\.+(jpg|jpeg|gif|png|bmp|JPG|JPEG|GIF|PNG|BMP)(?!\\S)", options: .caseInsensitive)
    static let movieRegex = try! NSRegularExpression(pattern: "https?:\\S+\\.+(mp4|MP4|m4a|M4A|mov|MOV|qt|QT|mpeg|MPEG|mpg|MPG|vob|VOB|avi|AVI|asf|ASF|wmv|WMV|webm|WEBM|flv|FLV|mkv|MKV)(?!\\S)", options: .caseInsensitive)
    
    static let numpattern = try! NSRegularExpression(pattern: "<span class=\"number\">(.+?)</span>", options: [])
    static let idpattern = try! NSRegularExpression(pattern: "<span class=\"uid\">(.+?)</span>", options: [])
    static let namepattern = try! NSRegularExpression(pattern: "<span class=\"name\"><b>(.+?)</b>", options: [])
    static let datepattern = try! NSRegularExpression(pattern: "<span class=\"date\">(.+?)</span>", options: [])
    static let bodypattern = try! NSRegularExpression(pattern: "<div class=\"message\"><span class=\"escaped\">(.+?)</span>", options: [])
    static let mailpattern = try! NSRegularExpression(pattern: "<a href=\"mailto:(.+?)\">", options: [])
    
    func detectEncoding(data: NSData) -> String.Encoding {
        return String.Encoding(rawValue: NSString.stringEncoding(
            for: data as Data, encodingOptions: nil, convertedString: nil, usedLossyConversion: nil))
    }
    
    static func pattern(pattern:NSRegularExpression,target:String) -> [String]{
        let matches = pattern.matches(in: target, options: [], range: NSMakeRange(0, target.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (target as NSString).substring(with: match.range(at: 1)) )
        }
        return results
    }
    
    
    func encodingNameFromNSStringEncoding(encoding: String.Encoding) -> String {
        return String(CFStringConvertEncodingToIANACharSetName(
            CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)))
    }
    
    func getAnchorMatch(data:String) -> [String] {
        let matches = Pattern.anchorRegex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 1)) )
        }
        return results
    }
    
    func getPictureLink(data:String) -> [String] {
        let matches = Pattern.pictureRegex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        return results
    }
    
    func getMovieLink(data:String) -> [String] {
        let matches = Pattern.pictureRegex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        return results
    }
    
    func getUrlLink(data:String) -> [String] {
        let matches = Pattern.httpregex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        
        let matches1 = Pattern.ttpregex.matches(in: data, options: [], range: NSMakeRange(0, data.count))

        matches1.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        
        
        return results
    }
    
    //値がおかしいときは0を返す
    func getResCount(data:String) -> Int {
        let sepalate = data.components(separatedBy: "(")
        if(sepalate.count == 1){
            return 0
        }else{
            let stringnum = sepalate[sepalate.count-1].replacingOccurrences(of: ")", with: "")
            return Int.init(stringnum) ?? 0
        }
    }
    
    func getAnchor(data:String)->[(String,[Int])]{
        
        var array = [(String,[Int])]()
        
        let parsedata = getAnchorMatch(data:data)
        
        for k in parsedata{
            
            let sepanc = k.replacingOccurrences(of: " ", with:"").replacingOccurrences(of: "\n", with: "").components(separatedBy: ">>")
            warp: for i in sepanc{
                if(i.count <= 0){
                    continue
                }
                var put: (String,[Int]) = (">>"+i,[])
                let sepalateperiod = i.components(separatedBy: ",")
                for j in sepalateperiod{
                    let sepalatebar = j.components(separatedBy: "-")
                    if(sepalatebar.count >= 2){
                        let count = Int.init(sepalatebar[0])
                        let count1 = Int.init(sepalatebar[sepalatebar.count-1])
                        if(count == nil || count1 == nil){
                            continue warp
                        }else if(count ?? 0 >= 1 && count1 ?? 0 >= 1){
                            var range = ((Array<Int>)(0...1))
                            if(count! < count1!){
                                range = ((Array<Int>)((count!-1)...(count1!-1)))
                            }else{
                                range = ((Array<Int>)((count1!-1)...(count!-1)))
                            }
                            range.removeAll(where: {$0 == 0})
                            
                            put.1.append(contentsOf: range)
                        }
                    }else{
                        let count = (Int.init(sepalatebar[0]) ?? 0)
                        if(count >= 1){
                            put.1.append(count-1)
                        }
                    }
                    
                }
                if(!put.1.contains(-1) && !(put.1.count >= 9)){
                    array.append(put)
                }
            }
        }
        
        return array
    }

}

class Parse {
    let jpDateFormater = DateFormatter()
    
    init() {
        jpDateFormater.locale = Locale(identifier: "ja_JP")
        jpDateFormater.dateFormat = "yyyy/MM/dd(EEE)HH:mm:ss"
        
    }
    static func setRelationParentRes(raw:[Res]) -> [Res] {
        
        let refres = raw.filter{$0.toRef.count > 0}
        for res in refres{
            for refs in res.toRef{
                for ref in refs.1{
                    var refd:Res
                    if(ref > raw.count){
                        let temp = raw.filter{$0.num == ref}.first
                        if(temp != nil){
                            refd = temp!
                        }else{
                            continue
                        }
                    }else{
                        refd = raw[ref]
                    }
                    if(res.num == refd.num){
                        continue
                    }
                    
                    if(!refd.treeChildren.contains(res.num)){
                        refd.treeChildren.append(res.num)
                    }
                    if(!res.treeParent.contains(refd.num)){
                        res.treeParent.append(refd.num)
                    }
                }
            }
        }
        
        return raw
    }

    
    func parseTreeArrayPartOfUpdate(old:[Res], update:[Res]) -> [Res]{
        
        var display = [Res]()
        let updateNum = update.map{$0.num}
        var oldNum = old.map{$0.num}
        print(updateNum)
        var totaldatas = [Res]()
        old.forEach{totaldatas.append($0)}
        update.forEach{totaldatas.append($0)}
        totaldatas = Parse.setRelationParentRes(raw: totaldatas)
        
        
        let forScan: (([Res],Int)->Int?) = {(raw:[Res],target:Int) -> (Int?) in
            var index:Int? = nil
            for arrayIndex in 0 ..< raw.count{
                if(raw[arrayIndex].num == target){
                    index = arrayIndex
                }
            }
            return index
        }
        
        var f: ((Res,Int) -> Void)? = nil
        
        f = {(res:Res,deepLev:Int) -> () in
            //var cache = Res()
            for i in res.treeChildren{
                if(i == res.num){
                    continue
                }
                guard let index = forScan(update,i) else {
                    continue
                }
                let pick = Res(cast: update[index] as SaveTypeTag)
                if(!updateNum.contains(pick.num)){
                    continue
                }
                pick.treeDepth = deepLev
                if(pick.treeChildren.count > 0){
                    display.append(pick)
                    f!(pick,deepLev+1)
                }else{
                    display.append(pick)
                }
            }
        }
        
        for i in update{
            var isSearchedOld = false
            for j in i.toRef{
                for k in j.1{
                    let index = forScan(old,k+1)
                    if(index != nil && oldNum.contains(old[index!].num)){
                        oldNum.removeAll(where: {$0 == old[index!].num})
                        display.append(Res(cast: old[index!] as SaveTypeTag))
                        f!(old[index!],1)
                    }
                }
                isSearchedOld = true
            }
            if(!isSearchedOld){
                display.append(i)
                f!(i,1)
            }
            
        }
        return display
    }
    
    func parseTreeArray(raw:[Res]) -> [Res] {
        var values = [Res]()
        let forScan: (([Res],Int)->Int?) = {(raw:[Res],target:Int) -> (Int?) in
            var index:Int? = nil
            for arrayIndex in 0 ..< raw.count{
                if(raw[arrayIndex].num == target){
                    index = arrayIndex
                }
            }
            return index
        }
        
        var f: ((Res,Int) -> Void)? = nil
        f = {(res:Res,deepLev:Int) -> () in

            //var cache = Res()
            for i in res.treeChildren{
                if(i == res.num){
                    continue
                }
                
                guard let index = forScan(raw,i) else{
                    continue
                }
                
                let pick = Res(cast: raw[index] as SaveTypeTag)
                
                
                pick.treeDepth = deepLev
                if(pick.treeChildren.count > 0){
                    values.append(pick)
                    f!(pick,deepLev+1)
                }else{
                    values.append(pick)
                }
            }
        }
        
        for res in raw{
            if(res.treeParent.count == 0){
                values.append(res)
                if(res.treeChildren.count > 0){
                    f!(res,1)
                }
            }
        }
        
        return values
    }
    
    static func getMatch(data:String,pattern:String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 1)) )
        }
        return results
    }

    
    func replaceChar(rawdata:String) -> String {
        return String(htmlEncodedString: rawdata)
    }
    
    func updateThread(thread:Thread) -> Thread {
        if(thread.url.contains("5ch.net")){
            return update5chThread(thread: thread)
        }else{
            return updateDatThread(thread: thread)
        }
    }
    
    func updateDatThread(thread:Thread) -> Thread {
        let downloaded = getThreadByDat(url: thread.url,isUpdate: thread)
        let data = Thread(cast: thread)
        if(downloaded.res.count - thread.res.count) > 0{
            data.res = downloaded.res[thread.res.count..<downloaded.res.count].map{$0}
        }else{
            data.res = []
        }
        return data
    }
    
    func update5chThread(thread:Thread) -> Thread {
        let rangeUrl = thread.url+"/"+String(thread.res.count+1)+"-n"
        
        return get5chThreadByUrl(url: rangeUrl, onDownload: nil, onParse: nil, onError: nil)
    }

    
    func getThreads(boardUrl:String) -> Board {
        let board = Board()
        let sepalateUrlShash = boardUrl.components(separatedBy: "/")
        board.name = sepalateUrlShash[sepalateUrlShash.count > 1 ? sepalateUrlShash.count-2 : 0]
        let titles = boardUrl+"subject.txt"
        let cgiurl = boardUrl.replacingOccurrences(of: board.name+"/", with: "")+"test/read.cgi/"+board.name+"/"
        //print(titles)
        
        let data = HttpClientImpl().getDatafromHTTP(url: titles)
        
        var shitJIS:String = String(data: data, encoding: .shiftJIS) ?? ""
        
        if(shitJIS.count == 0){
            shitJIS = HttpClientImpl().getStringDataWithCP932(data: data as NSData)
        }
        
        let lines:[String] = shitJIS.components(separatedBy: "\n")
        
        
        for line in lines{
            let datAndTitle = line.components(separatedBy: "<>")
            if(datAndTitle.count == 2){
                let thread = Thread()
                thread.id = String(datAndTitle[0].prefix(datAndTitle[0].count-4))
                thread.resCount = Pattern().getResCount(data: datAndTitle[1])
                thread.date = Date.init(timeIntervalSince1970: TimeInterval(Double(thread.id) ?? 0))
                let rawtitle = String(datAndTitle[1].prefix(datAndTitle[1].count-String(thread.resCount).count-3))
                thread.title = String(htmlEncodedString: rawtitle.trimmingCharacters(in: NSCharacterSet.whitespaces))
                thread.url = cgiurl+thread.id
                board.nowThread.append(thread)
                
            }
        }
        
        return board
    }
    
    
    
    func getCategoryAndBoard(url:String) -> [Category] {
        var categories = [Category]()
        
        let data = HttpClientImpl().getDatafromHTTP(url: url)
        
        var str:String = String(data: data, encoding: .shiftJIS) ?? ""
        
        if(str.count == 0){
            
            str = HttpClientImpl().getStringDataWithCP932(data: data as NSData)
            if(str.count == 0){
                print("Error")
            }
        }
        
        for line in str.components(separatedBy: "\n"){
            let rawtitle = Pattern.pattern(pattern: Pattern.categoryTitle, target: line)
            let category = Category()
            if(rawtitle.count > 0){
                let title = rawtitle[0]
                category.title = title
                categories.append(category)
            }else if categories.count > 0{
                let lastAppendCategory = categories[categories.count-1]
                let board = Board()
                let rawurl = Pattern.pattern(pattern: Pattern.boardurl, target: line)
                let rawname = Pattern.pattern(pattern: Pattern.boardname, target: line)
                if(rawurl.count > 0){
                    let url = rawurl[0]
                    board.url = url
                }
                if(rawname.count > 0){
                    let name = rawname[0]
                    board.title = name
                }
                if(board.title.count > 0 && board.url.count > 0){
                    lastAppendCategory.boards.append(board)
                }
            }
        }
        return categories
    }
    
    func get5chThreadByUrl(url:String,onDownload:(()->Void)?,onParse:((Int,Int)->Void)?,onError:(()->Void)?) -> Thread {
        //var isFirstRes = false
        var updatedata = [Res]()
        
        let thread = Thread()
        
        let urlGroup = url.components(separatedBy: "/")
        
        onDownload?()
        let data = HttpClientImpl().getDatafromHTTP(url: url)
        
        var str:String = String(data: data, encoding: .shiftJIS) ?? ""
        
        if(str.count == 0){
            str = HttpClientImpl().getStringDataWithCP932(data: data as NSData)
            //str = String(data: data, encoding: .iso2022JP) ?? ""
            if(str.count == 0){
                onError?()
                
                return thread
            }
        }
        
        if str.contains("<div class=\"toplight stopred stopdone\">"){
            thread.isDown = true
        }
        
        str = str.replacingOccurrences(of: "<span class=\"uid\"></span>", with: "<span class=\"uid\"><$EMPTY$></span>")
        
        let numArray = Pattern.pattern(pattern: Pattern.numpattern, target: str)
        let idArray = Pattern.pattern(pattern: Pattern.idpattern, target: str)
        let nameArray = Pattern.pattern(pattern: Pattern.namepattern, target: str)
        let dateArray = Pattern.pattern(pattern: Pattern.datepattern, target: str)
        let bodyArray = Pattern.pattern(pattern: Pattern.bodypattern, target: str)
        
        if numArray.count ==  dateArray.count && numArray.count == bodyArray.count {
            
            for i in 0 ..< numArray.count{
                onParse?(i+1,numArray.count)
                let res = Res()
                res.num = Int(numArray[i]) ?? 0
                res.writterId = idArray[i] == "<$EMPTY$>" ? "" : idArray[i].replacingOccurrences(of: "ID:", with: "")
                if(nameArray[i].contains("mailto:")){
                    //ここから
                    let address = Pattern.pattern(pattern: Pattern.mailpattern, target: nameArray[i])[0]
                    var name = nameArray[i].replacingOccurrences(of: "<a href=\"mailto:"+address+"\">", with: "")
                    name = String(htmlEncodedString: name.replacingOccurrences(of: "</a>", with: ""))
                    //ここまでが下処理
                    
                    res.address = address
                    res.writterName = name
                    
                }else{
                    res.writterName = nameArray[i]
                }
                
                res.date = jpDateFormater.date(from: dateArray[i]) ?? Date()
                let body = String(htmlEncodedString: bodyArray[i])
                res.body = body
                res.toRef = Pattern().getAnchor(data: res.body)
//                if(isFirstRes == false){
//                    res.isSinchaku = true
//                    isFirstRes = true
//                }
                thread.res.append(res)
            }
        }
        let threadborn = TimeInterval.init(urlGroup[urlGroup.count-1].replacingOccurrences(of: ".dat", with: "")) ?? 0
        thread.date = Date(timeIntervalSince1970: threadborn)
        thread.res = Parse.setRelationParentRes(raw: thread.res)
        
        return thread
    }
    
    func getThread(thread:Thread, onDownload:(()->Void)?,onParse:((Int,Int)->Void)?,onError:(()->Void)?) -> Thread {
        let data = getThread(url: thread.url,onDownload: onDownload,onParse: onParse,onError: onError)
        
        data.date = thread.date
        data.title = thread.title
        data.isDown = thread.isDown
        data.isfav = thread.isfav
        data.isSinchaku = thread.isSinchaku
        data.lastRead = thread.lastRead
        data.id = thread.id
        data.savetype = thread.savetype
        data.url = thread.url
        
        
        return data
    }
    
    func getThread(url:String,onDownload:(()->Void)?,onParse:((Int,Int)->Void)?,onError:(()->Void)?) -> Thread {
        if(url.contains("5ch.net")){
            return get5chThreadByUrl(url: url,onDownload: onDownload,onParse: onParse,onError: onError)
        }
        return getThreadByDat(url: url,isUpdate: nil)
    }
    
    func getThreadByDat(url:String,isUpdate:Thread?) -> Thread {
        let thread = Thread()
        
        var isFirstRes = false
        
        let urlGroup = url.replacingOccurrences(of: "test/read.cgi/", with: "").components(separatedBy: "/")
        let threadnumber = urlGroup[urlGroup.count-1]
        let datUrl = urlGroup[0]+"//"+urlGroup[2]+"/"+urlGroup[urlGroup.count-2]+"/dat/"+urlGroup[urlGroup.count-1]+".dat"
        var responses = [Res]()
        
        let parseUrl = datUrl
        if(!parseUrl.hasSuffix(".dat")){
            //parseUrl += ".dat"
        }
        
        let raw:[String] = HttpClientImpl().getStringData(url: parseUrl , encode: String.Encoding.shiftJIS)
        var count = 0
        for line in raw{
            if(line.count <= 0){
                continue
            }
            count += 1
            let resvar = Res()
            let res = line.components(separatedBy: "<>")
            if(res.count > 4 && res[4].count > 0){
                thread.title = res[4]
            }
            var dateAndId = res[2].components(separatedBy: " ID:")
            if(dateAndId.count == 2){
                var dateAndTime = dateAndId[0].components(separatedBy: " ")
                if(dateAndTime.count > 1){
                    if(dateAndTime[0].count == "0000/00/00(火)".count){
                        resvar.date = jpDateFormater.date(from: dateAndTime[0]+dateAndTime[1]) ?? Date()
                    }else{
                        resvar.date = jpDateFormater.date(from: "20"+dateAndTime[0]+dateAndTime[1]) ?? Date()
                    }
                }else{
                    if(dateAndTime[0].count == "0000/00/00(火)00:00:00".count){
                        resvar.date = jpDateFormater.date(from: dateAndTime[0]) ?? Date()
                    }else{
                        //応急措置 2100年以降は考えられてない
                        resvar.date = jpDateFormater.date(from: "20"+dateAndTime[0]) ?? Date()
                    }
                }
                
                resvar.writterId = dateAndId[1]
            }
            resvar.num = count
            resvar.body = replaceChar(rawdata: res[3])
            resvar.toRef = Pattern().getAnchor(data: resvar.body)
            resvar.writterName = res[0].replacingOccurrences(of: "</b>", with: "")
            
            if(isFirstRes == false){
                resvar.isSinchaku = true
                isFirstRes = true
            }
            responses.append(resvar)
            
        }
        thread.res = Parse.setRelationParentRes(raw: responses)
        thread.url = url
        let threadborn = TimeInterval.init(urlGroup[urlGroup.count-1].replacingOccurrences(of: ".dat", with: "")) ?? 0
        thread.date = Date(timeIntervalSince1970: threadborn)
        
        
        return thread
    }
}
