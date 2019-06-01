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
    let anchorRegex:NSRegularExpression = try! NSRegularExpression(pattern: "(((>>?|＞＞?)\\d+(\\s*(>>?|＞＞?|,|-)\\d+){0,})|(>>?|＞＞?)(\\d+)-(\\d+)|(>>?|＞＞?)\\d+((>>?|＞＞?|,|-)\\d+)+)", options: .caseInsensitive)
    let resCountRegex:NSRegularExpression = try! NSRegularExpression(pattern: "\\(.+?\\)", options: .caseInsensitive)
    
    let httpregex = try! NSRegularExpression(pattern: "https?://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$", options: .caseInsensitive)
    let ttpregex = try! NSRegularExpression(pattern: "ttps?://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$", options: .caseInsensitive)
    let pictureRegex = try! NSRegularExpression(pattern: "https?:\\S+\\.+(jpg|jpeg|gif|png|bmp|JPG|JPEG|GIF|PNG|BMP)(?!\\S)", options: .caseInsensitive)
    let movieRegex = try! NSRegularExpression(pattern: "https?:\\S+\\.+(mp4|MP4|m4a|M4A|mov|MOV|qt|QT|mpeg|MPEG|mpg|MPG|vob|VOB|avi|AVI|asf|ASF|wmv|WMV|webm|WEBM|flv|FLV|mkv|MKV)(?!\\S)", options: .caseInsensitive)
    
    func detectEncoding(data: NSData) -> String.Encoding {
        return String.Encoding(rawValue: NSString.stringEncoding(
            for: data as Data, encodingOptions: nil, convertedString: nil, usedLossyConversion: nil))
    }
    
    func encodingNameFromNSStringEncoding(encoding: String.Encoding) -> String {
        return String(CFStringConvertEncodingToIANACharSetName(
            CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)))
    }
    
    func getAnchorMatch(data:String) -> [String] {
        let matches = anchorRegex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 1)) )
        }
        return results
    }
    
    func getPictureLink(data:String) -> [String] {
        let matches = pictureRegex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        return results
    }
    
    func getMovieLink(data:String) -> [String] {
        let matches = pictureRegex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        return results
    }
    
    func getUrlLink(data:String) -> [String] {
        let matches = httpregex.matches(in: data, options: [], range: NSMakeRange(0, data.count))
        
        var results: [String] = []
        matches.forEach { (match) -> () in
            results.append( (data as NSString).substring(with: match.range(at: 0)) )
        }
        
        let matches1 = ttpregex.matches(in: data, options: [], range: NSMakeRange(0, data.count))

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
                        if(count ?? 1 >= 1 && count1 ?? 1 >= 1){
                            var range = ((Array<Int>)(0...1))
                            if(count! < count1!){
                                range = ((Array<Int>)((count!-1)...(count1!-1)))
                            }else{
                                range = ((Array<Int>)((count1!-1)...(count!-1)))
                            }
                            if(range.count >= 30){
                                //死ねごみ安価ゴミガイジ
                                continue warp
                            }
                            range.removeAll(where: {$0 == 0})
                            put.1.append(contentsOf: range)
                        }
                    }else{
                        let count = (Int.init(sepalatebar[0]) ?? 1)
                        if(count >= 0){
                            put.1.append(count-1)
                        }
                    }
                    
                }
                if(!put.1.contains(0)){
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
    
    func setRelationParentRes(raw:[Res]) -> [Res] {
        
        let refres = raw.filter{$0.toRef.count > 0}
        
        print("以下はどこかのレスを参照しているレス")
        print(refres.map{String($0.num)}.joined(separator: ","))
        
        for res in refres{
            for refs in res.toRef{
                for ref in refs.1{
                    //参照先
                    //>>2018みたいなやつを無効にする
                    if((raw.count-1) >= ref){
                        let refd = raw[ref]
                        if(!refd.treeChildren.contains(res.num-1)){
                            refd.treeChildren.append(res.num-1)
                        }
                        if(!res.treeParent.contains(refd.num-1)){
                            res.treeParent.append(refd.num-1)
                        }
                    }
                }
            }
        }
        
        return raw
    }
    
    func parseTreeArray(raw:[Res]) -> [Res] {
        var values = [Res]()
        
        var f: ((Res,Int) -> Void)? = nil
        f = {(res:Res,deepLev:Int) -> () in
            var cache = Res()
            for i in res.treeChildren{
                cache = raw[i]
                cache.treeDepth = deepLev
                if(cache.treeChildren.count > 0){
                    values.append(cache)
                    f!(cache,deepLev+1)
                }else{
                    values.append(cache)
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
    
//    func setRerationParentRes(raw:[Res]) -> [Res] {
//        for res in raw{
//            for refs in res.toRef{
//                for ref in refs.1{
//                    if(raw.count >= ref){
//                        if(res.num != ref){
//                            raw[ref].treeChildren.append(res.num-1)
//                            res.treeParent = raw[ref].num
//                            var deep = 0
//                            var targetRes:Res? = raw[ref]
//                            while targetRes != nil{
//                                deep += 1
//                                if(targetRes?.treeParent != nil){
//                                    targetRes = raw[targetRes?.treeParent ?? 0]
//                                }else{
//                                    targetRes = nil
//                                }
//                            }
//                            res.treeDepth = deep
//                        }
//                    }
//                }
//            }
//        }
//        return raw
//    }
//
//    func testparseTreeArray(raw:[Res]) -> [Res] {
//        //let copyarray = raw.map{Res(cast: $0 as SaveTypeTag)}
//        var value = [Res](repeating: Res(), count: raw.count)
//        raw.forEach{
//            value[$0.num-1] = Res(cast: $0)
//        }
//        var sort = [Res]()
//        var f: ((Res) -> Void)? = nil
//        f = {(res:Res) -> () in
//            var cache = Res()
//            for i in res.treeChildren{
//                //print(i-1)
//                cache = raw[i]
//                if(cache.treeChildren.count > 0){
//                    sort.append(cache)
//                    f!(cache)
//                }else{
//                    sort.append(cache)
//                }
//            }
//        }
//
////        //親子関係の設定
////        for res in value{
////            for refs in res.toRef{
////                for ref in refs.1{
////                    if(value.count >= ref){
////                        if(res.num != ref){
////                            value[ref-1].treeChildren.append(res)
////                            res.treeParent = value[ref-1]
////                            var deep = 0
////                            var targetRes:Res? = value[ref-1]
////                            while targetRes != nil{
////                                deep += 1
////                                targetRes = targetRes!.treeParent
////                            }
////                            res.treeDepth = deep
////                        }
////                    }
////                }
////            }
////        }
//
//        for res in value{
//            if(res.treeDepth == 0 && res.treeChildren.count > 0 && res.treeParent == nil){
//                sort.append(res)
//                f!(res)
//            }else if(res.treeDepth == 0 && res.treeChildren.count == 0){
//                sort.append(res)
//            }
//        }
//        sort.forEach{
//            var space = ""
//            for _ in 0 ..< $0.treeDepth{
//                space += " "
//            }
//            print(space+String($0.num))
//        }
//
//        return sort
//
//    }

    
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
            return thread
        }
    }
    
    func update5chThread(thread:Thread) -> Thread {
        //let urlGroup = thread.url.components(separatedBy: "/")
        
        //let base = Ji(htmlURL: URL(string: url)!)
        //print(thread.url)
        let rangeUrl = thread.url+"/"+String(thread.res.count+1)+"-n"
        let rawdata = HttpClientImpl().getDataByUrl(url: rangeUrl)
        
        
        let shitJIS:String = HttpClientImpl().getStringData(url: rangeUrl, encode: .shiftJIS)
        //var utf8 = String(data: rawdata,encoding: String.Encoding.) ?? ""
        //        for i in rawdata{
        //            print(i)
        //        }
        //
        
        let base = (shitJIS ).replacingOccurrences(of:"<br>" , with: "\n")
        
        
        let parseLine1 = Ji(htmlString: base)
        var responses = parseLine1?.xPath("/html/body/div[1]/div[5]")//スレタグの取得
        
        if(responses?.first?["class"] == "stoplight stopred stopdone"){
            thread.isDown = true
            responses = parseLine1?.xPath("/html/body/div[1]/div[6]")
        }else if(responses?.first?["class"] == "stoplight stopyellow"){
            responses = parseLine1?.xPath("/html/body/div[1]/div[6]")
        }
        
        var edited = false
        responses?.forEach{
            let a = $0
            //print(a.children.count)
            for i in a.children{
                let idname = i["id"] ?? ""
                if(idname == "banner"){
                    continue
                }
                for j in i.children{
                    if(j.children.count >= 4){//タグの数が4個のときは本文以外の情報が含まれる
                        
                        let res = Res()
                        let num = j.children[0].content!
                        let name = j.children[1].content!
                        let date = j.children[2].content!
                        let rawid = j.children[3].content!
                        let splitid = rawid.split(separator: ":")
                        var id = ""
                        if(splitid.count == 2){
                            id = String(splitid[1])
                        }else{
                            id = ""
                        }
                        
                        res.date = self.jpDateFormater.date(from:String(date.prefix(date.count-3))) ?? Date()
                        res.writterName = name
                        res.writterId = String(id)
                        res.num = Int(num) ?? 0
                        if (res.num == 0){
                            continue
                        }else{
                            if edited == false{
                                edited = true
                            }
                            thread.res.append(res)
                        }
                        
                    }else if(j.children.count == 1){//タグの数が1個のときは本文の情報が含まれる
                        let body = j.children[0].content!
                        //print(thread.responses.count-1)
                        thread.res[thread.res.count-1].body = body
                        thread.res[thread.res.count-1].toRef = Pattern().getAnchor(data: body)
                        thread.res[thread.res.count-1].movieURL = Pattern().getMovieLink(data: body)
                        thread.res[thread.res.count-1].pictureURL = Pattern().getPictureLink(data: body)
                    }
                }
            }
        }
        if(edited == true){
            thread.res = setRelationParentRes(raw: thread.res)
        }
        return thread
    }
    
    func getThreadsBy5ch(boardUrl:String) -> Board {
        let board = Board()
        let sepalateUrlShash = boardUrl.components(separatedBy: "/")
        board.name = sepalateUrlShash[sepalateUrlShash.count > 1 ? sepalateUrlShash.count-2 : 0]
        let titles = boardUrl+"subback.html"
        let base = Ji(htmlURL: URL(string:titles)!)
        
        for i in base?.xPath("//*[@id=\"trad\"]") ?? [JiNode](){
            let thread = Thread()
            let nonParseURL = i["href"] ?? ""//l50が入ってるURL
            let number = nonParseURL.count
            if(number == 0){
                continue
            }
            let parsedUrl = nonParseURL.prefix(number-3)//l50を削ったやつ

            var urlcomp = boardUrl.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://",with: "").components(separatedBy:"/")
            thread.url = "http://"+urlcomp[0]+"/test/read.cgi/"+urlcomp[1..<urlcomp.count].joined(separator:"/")+parsedUrl

            let rawtitle = i.content?.components(separatedBy: " ") ?? []
            var title = ""

            for i in 0 ..< rawtitle.count{
                if(i != 0 && i != (rawtitle.count-1)){
                    title += rawtitle[i]
                }
            }
            thread.title = title

            board.nowThread.append(thread)
        }
        
        return board
        
    }
    
    func getThreads(boardUrl:String) -> Board {
        var board = Board()
        let sepalateUrlShash = boardUrl.components(separatedBy: "/")
        board.name = sepalateUrlShash[sepalateUrlShash.count > 1 ? sepalateUrlShash.count-2 : 0]
        let titles = boardUrl+"subject.txt"
        let cgiurl = boardUrl.replacingOccurrences(of: board.name+"/", with: "")+"test/read.cgi/"+board.name+"/"
        //print(titles)
        
        let lines:[String] = HttpClientImpl().getStringData(url: titles, encode: .shiftJIS)
        
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
        
        let base = Ji(htmlURL: URL(string: url)!)
        var nowSearchSmallCategoryAllow = false//5chの最初の余計なタグをスキップするためのフラグ
        var childrens = base?.xPath("/html/body/font")?.first?.children
        
        if(childrens == nil){
            childrens = base?.xPath("/html/body/small")?.first?.children
        }
        
        for i in childrens ?? [JiNode](){
            if(i.tagName == "b") && (i["href"] == nil){//大カテゴリーのヒット条件
                let b = Category()
                b.savetype = .CATEGORY
                b.title = i.content!
                categories.append(b)
                nowSearchSmallCategoryAllow = true//もし地震タグが先頭にある場合、先にBタグがヒットするため
            }
            if(i.tagName == "a") && (i["href"] != nil) && (i.content != "") && (nowSearchSmallCategoryAllow){//余計なタグはここで引っかかる
                let b = Board()
                b.title = i.content!
                b.url = i["href"]!
                categories[categories.count-1].boards.append(b)
            }
        }
        return categories
    }
    
    func get5chThreadByURL(url:String,onDownload:(()->Void)?,onParse:((Int,Int)->Void)?,onError:(()->Void)?)->Thread{
        let thread = Thread()
        
        let urlGroup = url.components(separatedBy: "/")
        
        onDownload?()
        let shitJIS:String = HttpClientImpl().getStringData(url: url, encode: .shiftJIS)
        
        if(shitJIS.count == 0){
            onError?()
            return thread
        }
        
        let base = (shitJIS ?? "").replacingOccurrences(of:"<br>" , with: "\n")
        
        
        let parseLine1 = Ji(htmlString: base)
        var responses = parseLine1?.xPath("/html/body/div[1]/div[5]")//スレタグの取得
        
        if(responses?.first?["class"] == "stoplight stopred stopdone"){
            thread.isDown = true
            responses = parseLine1?.xPath("/html/body/div[1]/div[6]")
        }else if(responses?.first?["class"] == "stoplight stopyellow"){
            responses = parseLine1?.xPath("/html/body/div[1]/div[6]")
        }
        var count = 0
        responses?.forEach{
            let a = $0
            //print(a.children.count)
            for i in a.children{
                let idname = i["id"] ?? ""
                if(idname == "banner"){
                    continue
                }
                count += 1
                onParse?(count,a.children.count)
                for j in i.children{
                    if(j.children.count >= 4){//タグの数が4個のときは本文以外の情報が含まれる
                        
                        let res = Res()
                        let num = j.children[0].content!
                        let name = j.children[1].content!
                        let date = j.children[2].content!
                        let rawid = j.children[3].content!
                        let splitid = rawid.split(separator: ":")
                        var id = ""
                        if(splitid.count == 2){
                            id = String(splitid[1])
                        }else{
                            id = ""
                        }
                        
                        res.date = self.jpDateFormater.date(from:String(date.prefix(date.count-3))) ?? Date()
                        res.writterName = name
                        res.writterId = String(id)
                        res.num = Int(num) ?? 0
                        if (res.num == 0){
                            continue
                        }else{
                            thread.res.append(res)
                        }
                        
                    }else if(j.children.count == 1){//タグの数が1個のときは本文の情報が含まれる
                        let body = j.children[0].content!
                        //print(thread.responses.count-1)
                        thread.res[thread.res.count-1].body = body
                        thread.res[thread.res.count-1].toRef = Pattern().getAnchor(data: body)
                        thread.res[thread.res.count-1].movieURL = Pattern().getMovieLink(data: body)
                        thread.res[thread.res.count-1].pictureURL = Pattern().getPictureLink(data: body)
                    }
                }
            }
        }
        let threadborn = TimeInterval.init(urlGroup[urlGroup.count-1].replacingOccurrences(of: ".dat", with: "")) ?? 0
        thread.date = Date(timeIntervalSince1970: threadborn)
        thread.res = setRelationParentRes(raw: thread.res)
        
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
            return get5chThreadByURL(url: url,onDownload: onDownload,onParse: onParse,onError: onError)
        }
        return getThreadByDat(url: url)
    }
    
    func getThreadByDat(url:String) -> Thread {
        let thread = Thread()
        
        let urlGroup = url.replacingOccurrences(of: "test/read.cgi/", with: "").components(separatedBy: "/")
        let threadnumber = urlGroup[urlGroup.count-1]
        let datUrl = urlGroup[0]+"//"+urlGroup[2]+"/"+urlGroup[urlGroup.count-2]+"/dat/"+urlGroup[urlGroup.count-1]+".dat"
        var responses = [Res]()
        
        var parseUrl = datUrl
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
            
            responses.append(resvar)
            
        }
        thread.res = setRelationParentRes(raw: responses)
        thread.url = url
        let threadborn = TimeInterval.init(urlGroup[urlGroup.count-1].replacingOccurrences(of: ".dat", with: "")) ?? 0
        thread.date = Date(timeIntervalSince1970: threadborn)
        
        
        return thread
    }
}
