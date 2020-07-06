//
//  Model.swift
//  River
//
//  Created by 10fu3 on 2019/05/19.
//  Copyright © 2019 10fu3. All rights reserved.
//

import Foundation

enum SaveType: String {
    case SERVERNAME = "SERVER"
    case CATEGORY = "CATEGORY"
    case BOARD = "BOARD"
    case THREAD = "THREAD"
    case RESPONSE = "RESPONSE"
    case NG = "NG"
}

class NG{
    enum NGType {
        case Res
        case Thread
        case ID
        case CopyPase
        case ShareID
    }
    enum NGJudgeType {
        case Regex
        case Contains
    }
}

class TableFilter {
    
}

protocol SaveTypeTag {
    var savetype:SaveType { get set }
    var title:String { get set }
}

class Server:SaveTypeTag {
    init() {}
    
    init(savedata:SaveObject) {
        self.savetype = .SERVERNAME
        self.title = savedata.title
        let predicate = NSPredicate(format: "dataType == %@","CATEGORY")
        let objs = Manager.manager.realm.objects(SaveObject.self).filter(predicate)
        objs.forEach{
            let cat = Category(savedata: $0)
            self.bigcategory.append(cat)
        }
        

    }
    
    var savetype: SaveType = .SERVERNAME
    var title = ""
    var bigcategory = [Category]()
    var bbsmenuurl = ""
    
    func convertSaveData() -> SaveObject {
        let savedata = SaveObject()
        savedata.title = self.title
        savedata.dataType = self.savetype.rawValue
        return savedata
    }
}

class Category:SaveTypeTag {
    init() {}
    init(savedata:SaveObject) {
        self.title = savedata.title
        self.savetype = .CATEGORY
        let predicate = NSPredicate(format: "dataType == %@","BOARD")
        let objs = Manager.manager.realm.objects(SaveObject.self).filter(predicate)
        objs.forEach{
            let board = Board(savedata: $0)
            self.boards.append(board)
        }
    }
    
    var savetype: SaveType = .CATEGORY
    var title = ""
    var boards = [Board]()
    
    func convertSaveData() -> SaveObject {
        let savedata = SaveObject()
        savedata.title = self.title
        savedata.dataType = self.savetype.rawValue
        return savedata
    }
}

class Board:SaveTypeTag {
    init(){}
    init(savedata:SaveObject) {
        self.title = savedata.title
        self.savetype = .BOARD
        let predicate = NSPredicate(format: "dataType == %@","THREAD")
        let objs = Manager.manager.realm.objects(SaveObject.self).filter(predicate)
        objs.forEach{
            let thread = Thread(savedata: $0)
            self.cache.append(thread)
        }
    }
    
    var name = ""
    
    var cache = [Thread]()
    var memory = [Thread]()
    var nowThread = [Thread]()
    var savetype: SaveType = .BOARD
    var title = ""
    var url = ""
    //var name = ""
    
    func convertSaveData() -> SaveObject {
        let savedata = SaveObject()
        savedata.title = self.title
        savedata.name = self.name
        savedata.dataType = self.savetype.rawValue
        savedata.url = self.url
        //savedata.name = self.name
        return savedata
    }
    
}

class Thread:SaveTypeTag {
    init() {}
    init(cast:SaveTypeTag) {
        let savedata = cast as! Thread
        self.title = savedata.title
        self.savetype = .THREAD
        self.url = savedata.url
        self.lastRead = savedata.lastRead
        self.date = savedata.date
        self.isfav = savedata.isfav
        self.id = savedata.id
        self.title = savedata.title
        self.isSinchaku = savedata.isSinchaku
        self.res = savedata.res.map{$0}
    }
    
    init(savedata:SaveObject) {
        
        self.title = savedata.title
        self.savetype = .THREAD
        self.url = savedata.url
        self.lastRead = savedata.num
        self.date = Parse().jpDateFormater.date(from: savedata.date) ?? Date()
        self.isfav = savedata.fav
        self.id = savedata.value
        
        let predicate = NSPredicate(format: "dataType == %@","RESPONSE")
        let objs = Manager.manager.realm.objects(SaveObject.self).filter(predicate)
        objs.forEach{
            let res = Res(savedata: $0)
            self.res.append(res)
        }
        self.res = Parse.setRelationParentRes(raw: self.res)
    }
    
    
    func getIkioi() ->  Float {
        let interval = Int(Date().timeIntervalSince1970)
        let span = Int64(interval - (Int(self.id) ?? 0))
        var speed = Float(Float(self.resCount * (86400)) / Float(span))
        if speed < 0 {
            speed = 0
        }
        speed = round((speed * 10) / Float(10))
        
        return speed
    }

    
    func convertSaveData() -> SaveObject {
        let savedata = SaveObject()
        savedata.title = self.title
        savedata.dataType = self.savetype.rawValue
        savedata.url = self.url
        savedata.num = self.lastRead
        savedata.date = Parse().jpDateFormater.string(from: self.date)
        savedata.fav = self.isfav
        savedata.value = self.id
        return savedata
    }
    
    var boardID = ""
    var savetype: SaveType = .THREAD
    var title = ""
    var isDown = false
    var isSinchaku = false
    var url = ""
    var lastRead = 0
    var date = Date()
    var res = [Res]()
    //var photoLink = [String]()
    
    var isfav = false
    var id = ""
    var resCount = 0
    
}

class Res:SaveTypeTag {
    
    init() {
        
    }
    
    init(cast:SaveTypeTag) {
        //let copy = Res(copy: cast as! Res)
        let copy = cast as! Res
        
        self.body = copy.body
        self.num = copy.num
        self.writterId = copy.writterId
        self.writterName = copy.writterName
        self.date = copy.date
        self.isfav = copy.isfav
        self.toRef = copy.toRef.map{
            var put:(String,[Int]) = ("",[])
            put.0 = $0.0
            put.1 = $0.1
            return put
        }
        
        for c in copy.treeChildren{
            if(copy.num != c){
                self.treeChildren.append(c)
            }
        }
        for c in copy.treeParent{
            if(copy.num != c){
                self.treeParent.append(c)
            }
        }
        
        for c in copy.idInBody{
            self.idInBody.append(c)
        }
        
        for c in copy.urls{
            self.urls.append(c)
        }
        
        self.treeParent = copy.treeParent
        self.treeDepth = copy.treeDepth
        self.address = copy.address
        self.title = copy.title
        self.isSinchaku = copy.isSinchaku
    }
    init(savedata:SaveObject) {
        self.body = savedata.value
        self.savetype = .RESPONSE
        self.date = savedata.date
        self.writterId = savedata.writterId
        self.writterName = savedata.name
        self.num = savedata.num
        self.isfav = savedata.fav
        self.toRef = Pattern().getAnchor(data: self.body)
        self.title = savedata.value
        self.address = savedata.url
    }
    
    var savetype: SaveType = .RESPONSE
    var body = ""
    var num = 0
    var writterId = ""
    var writterName = ""
    var date = ""
    var isfav = false
    //安価文字列,実際のインデックス(num-1)
    var toRef = [(String,[Int])]()
    var idInBody = [String]()
    var treeChildren = [Int]()
    var treeParent = [Int]()
    var treeDepth = 0
    var pictureURL = [String]()
    var urls = [String]()
    var movieURL = [String]()
    var address = ""
    var isAA = false
    var isSinchaku = false
    
    //非推奨
    var title = ""
}



class SaveObject: Object {//保存する際に共通化するオブジェクト
    @objc var fav = false
    @objc var writterId = ""
    @objc var dataType = "SERVER"
    @objc var date = ""
    
    @objc var num = 0//レス番
    @objc var url = ""//URL
    @objc var tag = ""//所属先
    @objc var title = ""//件名
    @objc var name = ""//書き込んだやつの名前
    @objc var value = ""//本文
    @objc var lastRead = 0
    @objc dynamic var down:Bool = false
    
    @objc dynamic var key:String = UUID.init().uuidString
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    func save() {
        DispatchQueue.main.async {
            try! Manager.manager.realm.write {
                Manager.manager.realm.add(self, update: true)
            }
        }
    }
}

