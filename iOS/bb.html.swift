//
//  bb.html.swift
//  bb framework
//
//  Created by renan jegouzo on 01/01/2018.
//  Copyright © 2018 aestesis. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation

public class HtmlNode {
    var name:String
    public var attributes = [String:String]()
    public var styles = [String:String]()
    public var classes = [String]()
    public var children = [HtmlNode]()
    public var text:String?
    public init(name:String,classes:[String]? = nil,attributes:[String:String]? = nil,styles:[String:String]? = nil) {
        self.name = name
        if let classes = classes {
            self.classes = classes
        }
        if let attributes = attributes {
            self.attributes = attributes
        }
        if let styles = styles {
            self.styles = styles
        }
    }
    public init(_ data:[String:Any]) {
        self.name = ""
        for (k,v) in data {
            // TODO:
        }
    }
    public func append(name:String,classes:[String]? = nil,attributes:[String:String]? = nil,styles:[String:String]? = nil) -> HtmlNode {
        let c = HtmlNode(name:name,classes:classes,attributes:attributes,styles:styles)
        self.children.append(c)
        return c
    }
    public func append(text:String)  {
        let c = HtmlNode(name:name,classes:classes,attributes:attributes,styles:styles)
        c.text = text
        self.children.append(c)
    }
    public var html:String {
        if let text = text {
            return "<\(name)\(sClass)\(sStyle)\(sAttribute)>\(text)</\(name)>"
        } else if children.count > 0 {
            return "<\(name)\(sClass)\(sStyle)\(sAttribute)>\(sChildren)</\(name)>"
        } else {
            return "<\(name)\(sClass)\(sStyle)\(sAttribute)/>"
        }
    }
    private var sClass:String {
        if classes.count>0 {
            return " class=\"\(classes.joined(separator:" "))\""
        }
        return ""
    }
    private var sStyle:String {
        if styles.count>0 {
            let st = styles.reduce("") { r,p  in
                return r+"\(p.0):\(p.1);"
            }
            return " style=\"\(st)\""
        }
        return ""
    }
    private var sAttribute:String {
        return attributes.reduce("") { r,p  in
            return r+" \(p.0)=\"\(p.1)\""
        }
    }
    private var sChildren:String {
        return children.reduce("") { r,c in
            return r + c.html
        }
    }
}
