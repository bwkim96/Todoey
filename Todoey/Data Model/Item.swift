//
//  Item.swift
//  Todoey
//
//  Created by Greg Kim on 2020-12-15.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift

class Item: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var detail: String = ""
//    @objc dynamic var priority: Int = 0 // Number of !, from 1 to 3
    @objc dynamic var done: Bool = false
    @objc dynamic var dateCreated: Date?
    
    var parentCategory = LinkingObjects(fromType: Category.self, property: "items")
}
