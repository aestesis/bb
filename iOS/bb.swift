//
//  bb.swift
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
import UIKit
import MobileCoreServices
import CoreVideo
import Alib
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class TagInput : UIControl, UIKeyInput { // in dev, good as custom KeyInput example
    var label:UILabel?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    override public var canBecomeFirstResponder: Bool {
        return true
    }
    override public init(frame: CGRect) {
        super.init(frame:frame)
        label = UILabel(frame:bounds)
        self.addSubview(label!)
        label!.text = ""
        label!.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        self.addTarget(self, action: #selector(onTap),for:.touchUpInside)
    }
    @objc private func onTap(_: AnyObject) {
        becomeFirstResponder()
    }
    public var hasText: Bool {
        if let label = label, let text = label.text {
            return text.count > 0
        }
        return false
    }
    public func insertText(_ text: String) {
        label!.text! += text
    }
    public func deleteBackward() {
        if let label = label, label.text!.count>0 {
            label.text = label.text![0...label.text!.count-2]
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class BBImages : BBView {
    let onClick = Event<(UIImageView,String)>()
    var x:CGFloat = Margins.mh
    var scroll:UIScrollView?
    var taps = [TapRecognizer]()
    var images = [String]()
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame:CGRect) {
        super.init(frame:frame)
        scroll = UIScrollView(frame: self.bounds)
        scroll!.showsHorizontalScrollIndicator = false
        self.addSubview(scroll!)
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
    public func add(name:String,image:UIImage) -> UIImageView {
        let r = Rect(self.bounds).crop(Size(image.size).ratio).system
        let iv = UIImageView(frame: CGRect(x:x,y:0,width:r.width,height:r.height))
        iv.layer.cornerRadius = 5
        iv.layer.masksToBounds = true
        iv.accessibilityLabel = name
        iv.contentMode = .scaleAspectFit
        iv.image = image
        x += r.width + 10
        scroll!.addSubview(iv)
        scroll!.contentSize = CGSize(width:x,height:self.bounds.height)
        taps.append(TapRecognizer(view:iv) { _ in
            self.onClick.dispatch((iv,name))
        })
        images.append(name)
        iv.transform = CGAffineTransform.init(translationX:UIScreen.main.bounds.width,y:0)
        _ = self.animate(duration:0.2) { t in
            let v = CGFloat(Signal(t).pow(0.4).value)
            iv.transform = CGAffineTransform.init(translationX:UIScreen.main.bounds.width*(1-v),y:0)
        }
        return iv
    }
    public func remove(name:String) {
        images.remove(at: images.index(of: name)!)
        if let iv:UIView = self.find(label:name) {
            let w = iv.frame.size.width + 10
            for v in scroll!.subviews {
                if v.frame.origin.x > iv.frame.origin.x {
                    var f = v.frame
                    f.origin.x -= w
                    v.frame = f
                }
            }
            x -= w
            scroll!.contentSize = CGSize(width:x,height:self.bounds.height)
            iv.removeFromSuperview()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class BBScrollStack : BBView,UIScrollViewDelegate {
    let onScroll = Event<Void>()
    var scroll:UIScrollView?
    var stack:BBStackView?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame:CGRect) {
        super.init(frame:frame)
        scroll = UIScrollView(frame:bounds)
        self.addSubview(scroll!)
        scroll!.delegate = self
        stack = BBStackView(frame:bounds)
        scroll!.addSubview(stack!)
        stack!.onResize.alive(self) { size in
            self.scroll!.contentSize = size
        }
        initKeyboard()
    }
    func initKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    var keyboardSize : CGSize?
    @objc func keyboardWillShow(notification:NSNotification) {
        if keyboardSize != nil {
            return
        }
        if let scroll = scroll {
            let userInfo = notification.userInfo!
            let keyboardSize = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect).size
            self.keyboardSize = keyboardSize
            let contentInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            scroll.contentInset = contentInsets
            scroll.scrollIndicatorInsets = contentInsets
            if let tv = scroll.firstResponder() as? UITextView { // UITextField as automatic scrollTo, not textView
                scroll.scrollTo(view:tv,animated:true)
            }
        }
    }
    @objc func keyboardWillHide() {
        scroll!.contentInset = UIEdgeInsets.zero
        scroll!.scrollIndicatorInsets = UIEdgeInsets.zero
        keyboardSize = nil
    }
    @objc public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.onScroll.dispatch(())
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class BBPages : BBView {
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame:CGRect) {
        super.init(frame:CGRect(x:frame.origin.x,y:frame.origin.y,width:frame.size.width,height:0))
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        if animating {
            return
        }
        var h:CGFloat = 0
        for v in subviews {
            let y = v.frame.origin.y + v.frame.size.height
            h = max(h,y)
        }
        var f = self.frame
        f.size.height = h
        self.frame = f
    }
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var h:CGFloat = 0
        for v in subviews {
            let y = v.frame.origin.y + v.frame.size.height
            h = max(h,y)
        }
        var s = size
        s.height = h
        return s
    }
    public func swap(to v:BBView) {
        let sv = self.subviews
        for v in sv {
            v.removeFromSuperview()
        }
        self.addSubview(v)
        let mc = v.clipsToBounds
        v.clipsToBounds = true
        self.animate(duration:0.2) { t in
            let tf = CGFloat(t)
            var f = self.frame
            f.size.height = f.size.height * (1-tf) + v.bounds.height * tf
            self.frame = f
        }.then { _ in
            v.clipsToBounds = mc
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class BBStackView : BBView {
    //let onResize = Event<CGSize>()
    let onDebug = Event<String>()
    let direction:Direction
    required public init?(coder aDecoder: NSCoder) {
        self.direction = .vertical
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,direction:Direction = .vertical) {
        self.direction = direction
        super.init(frame:frame)
    }
    override open func layoutSubviews() {
        //Debug.warning("BBStackView.layoutSubview")
        super.layoutSubviews()
        if animating {
            return
        }
        switch direction {
        case .vertical:
            var y:CGFloat = 0
            for v in subviews {
                if v.accessibilityHint != "overlay" {
                    v.frame.origin.y = y
                    y += v.frame.size.height
                }
            }
            self.frame = CGRect(x:self.frame.origin.x,y:self.frame.origin.y,width:bounds.width,height:y)
            onResize.dispatch(self.frame.size)
        case .horizontal:
            var x:CGFloat = 0
            for v in subviews {
                if v.accessibilityHint != "overlay" {
                    v.frame.origin.x = x
                    x += v.frame.size.width
                }
            }
            self.frame = CGRect(x:self.frame.origin.x,y:self.frame.origin.y,width:x,height:bounds.height)
            onResize.dispatch(self.frame.size)
        }
        //let subs = self.subviews.map{"\($0.frame.size)"}
        //onDebug.dispatch("layoutSubview, frame: \(self.frame.size)   subviews: \(subs)")
    }
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        //Debug.warning("BBStackView.sizeThatFits: \(size)")
        var sz = size
        switch direction {
        case .vertical:
            var y:CGFloat = 0
            for v in subviews {
                if v.accessibilityHint != "overlay" {
                    v.frame.origin.y = y
                    y += v.frame.size.height
                }
            }
            sz = CGSize(width:size.width,height:y)
        case .horizontal:
            var x:CGFloat = 0
            for v in subviews {
                if v.accessibilityHint != "overlay" {
                    v.frame.origin.x = x
                    x += v.frame.size.width
                }
            }
            sz = CGSize(width:x,height:size.height)
        }
        //let subs = self.subviews.map{"\($0.frame.size)"}
        //onDebug.dispatch("sizeThatFit, size: \(sz)   subviews: \(subs)")
        return sz
    }
    public override func appears(scroll:Bool = false,fn:(()->())? = nil) {
        self.sizeToFit()
        super.appears(scroll:scroll,fn:fn)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class BBTableView : BBView,UITableViewDelegate,UITableViewDataSource { // UITextFieldDelegate,UITextViewDelegate
    var header:BBForm?
    var table:UITableView?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,title:String,description:String,style:UITableView.Style = .plain) {
        super.init(frame:frame)
        self.initKeyboard()
        self.backgroundColor = .clear
        table = UITableView(frame:self.bounds,style:style)
        table!.backgroundColor = .clear
        table!.delegate = self
        table!.dataSource = self
        table!.separatorStyle = .none
        table!.allowsSelection = false
        let header = BBForm(frame:self.bounds,title:title,description:description)
        self.header = header
        header.frame = header.contentBounds
        table!.tableHeaderView = header
        self.addSubview(table!)
    }
    public init(frame:CGRect,style:UITableView.Style = .plain) {
        super.init(frame:frame)
        self.initKeyboard()
        self.backgroundColor = .clear
        table = UITableView(frame:self.bounds,style:style)
        table!.backgroundColor = .clear
        table!.delegate = self
        table!.dataSource = self
        table!.separatorStyle = .none
        table!.allowsSelection = false
        self.addSubview(table!)
    }
    @objc public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    @objc public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }
    func initKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    var keyboardSize : CGSize?
    @objc func keyboardWillShow(notification:NSNotification) {
        if keyboardSize != nil {
            return
        }
        if let scroll = table {
            //autoScroll = ß.time + 1
            let userInfo = notification.userInfo!
            let keyboardSize = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect).size
            self.keyboardSize = keyboardSize
            let contentInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            scroll.contentInset = contentInsets
            scroll.scrollIndicatorInsets = contentInsets
        }
    }
    @objc func keyboardWillHide() {
        table!.contentInset = UIEdgeInsets.zero
        table!.scrollIndicatorInsets = UIEdgeInsets.zero
        keyboardSize = nil
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class ErrorView : Page {
    let skp = skin.page
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,title:String,description:String,message:String) {
        let info = Info(icon:skin.page.icons.error,title:title,subtitle:description,condensed:title)
        super.init(frame:frame,info:info)
        let stack = self.content!.stack!
        _ = self.add(space:skp.m)
        let form = BBForm(frame:Rect(bounds).extend(w:-skp.m,h:0).system)
        stack.addSubview(form)
        form.add(text:message,lines:0,color:skp.colors.dark)
        form.sizeToFit()
        _ = self.add(space:skp.m)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class BBForm : BBView,UITextFieldDelegate {
    var y:CGFloat = Margins.mh
    let mv:CGFloat = Margins.mv
    let mmv:CGFloat = Margins.mmv
    let mh:CGFloat
    var taps = [TapRecognizer]()
    public func getRect(_ left:CGFloat,_ width:CGFloat,_ height:CGFloat)->(CGRect) {
        return CGRect(x:left,y:y,width:width,height:height)
    }
    public func calcRect(_ left:CGFloat,_ height:CGFloat)->(CGRect) {
        let r = CGRect(x:left,y:y,width:self.bounds.width-left-mh,height:height)
        y = y+height+mv
        return r
    }
    public func centerRect(width:CGFloat,height:CGFloat)->(CGRect) {
        let r = CGRect(x:(bounds.width-width)*0.5,y:y,width:width,height:height)
        y = y+height+mv
        return r
    }
    public func calcRect(_ height:CGFloat)->(CGRect) {
        let r = CGRect(x:0,y:y,width:self.bounds.width,height:height)
        y = y+height+mv
        return r
    }
    public var contentSize:CGSize {
        return CGSize(width:self.bounds.width,height:y)
    }
    public var contentBounds:CGRect {
        return CGRect(x:0,y:0,width:self.bounds.width,height:y)
    }
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width:size.width,height:y)
    }
    required public init?(coder aDecoder: NSCoder) {
        self.mh = Margins.mh
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,left:CGFloat = Margins.mh,top:CGFloat = Margins.mh) {
        self.y = top
        self.mh = left
        super.init(frame:frame)
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
    public init(frame:CGRect,left:CGFloat = Margins.mh, top:CGFloat = Margins.mh,title t:String,description d:String) {
        self.y = top
        self.mh = left
        super.init(frame:frame)
        let title = UILabel(frame: calcRect(mh,38))
        title.accessibilityLabel = "form.title"
        title.backgroundColor = .clear
        title.textAlignment = .left
        title.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        title.text = t
        title.textColor = skin.colors.white.system
        addSubview(title)
        let desc = UILabel(frame: calcRect(mh,20))
        desc.accessibilityLabel = "form.description"
        desc.text = d
        desc.textColor = skin.colors.full.system
        desc.font = UIFont.systemFont(ofSize:16,weight:.light)
        addSubview(desc)
        y = y+mmv*2
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
    public override func appears(scroll:Bool = false,fn:(()->())? = nil) {
        self.sizeToFit()
        super.appears(scroll:scroll,fn:fn)
    }
    // NEW UI =====================================================================
    public func add(name:String? = nil,icon:String,title:String,lines:Int = 1,align:NSTextAlignment = .left, font:UIFont = UIFont.systemFont(ofSize: 18),color:Color = .white,click: (()->())? = nil) {
        let iv = UIImageView(frame: CGRect(x:mh,y:y,width:font.pointSize*1.2,height:font.pointSize*1.2))
        self.addSubview(iv)
        iv.image = UIImage(named:icon)?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = color.system
        let l = UILabel(frame: calcRect(mh+iv.bounds.width+10,CGFloat(lines)*font.pointSize))
        self.addSubview(l)
        l.accessibilityLabel = name
        l.backgroundColor = .clear
        l.textAlignment = align
        l.font = font
        l.text = title
        l.numberOfLines = lines
        l.textColor = color.system
        let oh = l.frame.height
        let ow = l.frame.width
        l.sizeToFit()
        var f = l.frame
        f.size.width = ow
        l.frame = f
        y += l.frame.height - oh
        if let c = click {
            taps.append(TapRecognizer(view:l) { _ in
                c()
            })
        }
    }
    public enum ButtonStyle {
        case plain
        case normal
    }
    public func add(button:String,style:ButtonStyle = .normal,fn:@escaping ()->()) {
        let c = skin.colors.white
        let b = SimpleButton(view:self,frame:Rect(calcRect(mh,28)),label:button,font:UIFont.systemFont(ofSize:14,weight:.medium),color:c,fn:fn)
        b.layer.cornerRadius = 14
        b.clipsToBounds = true
        b.backgroundColor = style == .plain ? skin.colors.dark.system : .clear
        if style == .normal {
            b.layer.borderColor = skin.colors.white.system.cgColor
            b.layer.borderWidth = 2
        }
    }
    public class Field {
        public enum Keyboard {
            case text
            case number
            case decimal
            case phone
            case email
            case url
            case password
            // not text field
            case icons
            case date
        }
        var label:String
        var value:String
        var keyboard:Keyboard
        var select:[String]
        var width:Double
        var fn:((String)->())?
        var fni:((Int)->())?
        init(label:String,value:String,keyboard:Keyboard = .text,select:[String]=[String](),width:Double = 0,fn: @escaping (String)->()) {
            self.label = label
            self.value = value
            self.keyboard = keyboard
            self.select = select
            self.width = width
            self.fn = fn
        }
        init(value:Int,icons:[String],width:Double = 0,fn:@escaping (Int)->()) {
            self.label = ""
            self.value = String(value)
            self.keyboard = .icons
            self.select = icons
            self.width = width
            self.fni = fn
        }
    }
    public func add(fields:[Field])  {
        let n = fields.count
        let m:Double = 10
        var w = (Double(bounds.width)-Double(mh)*2-Double(n-1)*m)/Double(n)
        var x = Double(mh)
        var ww = [Double](repeating:0,count:fields.count)
        var nchange = 0
        var wchange = 0.0
        for i in 0..<fields.count {
            let fw = fields[i].width
            if fw>0 && fw<=1 {
                let nw = w*Double(n)*fw
                ww[i] = nw
                nchange += 1
                wchange += nw
            } else if fw>1 {
                let nw = fw
                ww[i] = nw
                nchange += 1
                wchange += nw
            }
        }
        w = (w*Double(n)-wchange) / Double(n-nchange)
        for i in 0..<fields.count {
            if ww[i] == 0 {
                ww[i] = w
            }
        }
        var i = 0
        for f in fields {
            let w = ww[i]
            if f.keyboard == .icons {
                let field = IconField(frame:getRect(CGFloat(x),CGFloat(w),40),icons:f.select)
                self.addSubview(field)
                field.select(icon:Int(f.value) ?? 0)
                field.onChanged.alive(self) { v in
                    f.value = String(v)
                    f.fni?(v)
                }
            } else {
                let field = TextField(frame:getRect(CGFloat(x),CGFloat(w),40),label:f.label)
                field.accessibilityLabel = f.label
                self.addSubview(field)
                self.onAttach.once {
                    if let page:Page = self.ancestor() {
                        page.onTap.alive(self) {
                            field.endEditing(false)
                        }
                    }
                }
                if f.keyboard == .date {
                    field.readOnly = true
                    taps.append(TapRecognizer(view:field) { _ in
                        if let page:Page = self.ancestor() {
                            page.onTap.dispatch(())
                        }
                        let alert = BBAlertDate(parent:self["mainview"] as! UIView,title:"Date travaux",value:f.value)
                        alert.changed = { value in
                            field.text = ß.justLocaleDate(date:value)
                            f.value = value
                            f.fn?(value)
                        }
                        alert.changed?(alert.get()) // set default value (today) in case no value yet
                    })
                    field.text = ß.justLocaleDate(date:f.value)
                } else {
                    if f.select.count>0 {
                        field.readOnly = true
                        taps.append(TapRecognizer(view:field) { _ in
                            if let page:Page = self.ancestor() {
                                page.onTap.dispatch(())
                            }
                            let alert = UIAlertController(title:f.label,message:"",preferredStyle:.actionSheet)
                            for s in f.select {
                                alert.addAction(UIAlertAction(title:s,style:.default) { a in
                                    if let text = a.title {
                                        field.text = text
                                        f.value = text
                                        f.fn?(text)
                                    }
                                })
                            }
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                            })
                            if let app = UIApplication.shared.delegate as? AppDelegate {
                                app.controller?.present(alert, animated: true) {
                                }
                                alert.view.tintColor = skin.colors.dark.system
                            }
                        })
                    }
                    field.text = f.value
                    field.onChange.alive(self) { text in
                        f.value = text
                        f.fn?(text)
                    }
                }
                field.borderStyle = .line
                field.layer.borderColor = skin.page.form.label.border.system.cgColor
                field.layer.borderWidth = 1
                field.textColor = skin.page.form.label.foregound.system
                field.backgroundColor = skin.page.form.label.background.system
                field.layer.cornerRadius = 4
                field.clipsToBounds = true
                switch f.keyboard {
                case .number:
                    //field.keyboardType = .numberPad
                    field.autocapitalizationType = .none
                case .decimal:
                    //field.keyboardType = .decimalPad
                    field.autocapitalizationType = .none
                case .phone:
                    //field.keyboardType = .phonePad
                    field.autocapitalizationType = .none
                case .email:
                    //field.keyboardType = .emailAddress
                    field.autocapitalizationType = .none
                case .url:
                    //field.keyboardType = .URL
                    field.autocapitalizationType = .none
                case .password:
                    field.isSecureTextEntry = true
                    field.autocapitalizationType = .none
                default:
                    break
                }
            }
            x += w+m
            i += 1
        }
        _ = calcRect(mh,40)
    }
    public func addField(label:String,text:String,keyboard:Field.Keyboard = .text,fn:@escaping (String)->())  {
        let field = TextField(frame:calcRect(mh,40),label:label)
        field.accessibilityLabel = label
        self.addSubview(field)
        self.onAttach.once {
            if let page:Page = self.ancestor() {
                page.onTap.alive(self) {
                    //Debug.warning("field tap")
                    field.endEditing(false)
                }
            }
        }
        field.onChange.alive(self) { text in
            fn(text)
        }
        field.text = text
        field.borderStyle = .line
        field.layer.borderColor = skin.page.form.label.border.system.cgColor
        field.layer.borderWidth = 1
        field.textColor = skin.page.form.label.foregound.system
        field.backgroundColor = skin.page.form.label.background.system
        field.layer.cornerRadius = 4
        field.clipsToBounds = true
        switch keyboard {
        case .number:
            //field.keyboardType = .numberPad
            field.autocapitalizationType = .none
        case .decimal:
            //field.keyboardType = .decimalPad
            field.autocapitalizationType = .none
        case .phone:
            //field.keyboardType = .phonePad
            field.autocapitalizationType = .none
        case .email:
            //field.keyboardType = .emailAddress
            field.autocapitalizationType = .none
        case .url:
            //field.keyboardType = .URL
            field.autocapitalizationType = .none
        case .password:
            field.isSecureTextEntry = true
            field.autocapitalizationType = .none
        default:
            break
        }
    }
    public func addField(label:String,textview:String,fn:@escaping (String)->())  {
        let l = UILabel(frame: calcRect(mh+2,16))
        y -= mv - 2
        l.backgroundColor = .clear
        l.textAlignment = .left
        l.font = UIFont.appFont(ofSize: 14, weight: .light)
        l.text = label
        l.textColor = skin.colors.black.system
        self.addSubview(l)
        let tv = SimpleTextView(frame: calcRect(mh,64))
        tv.text = textview
        tv.changed = fn
        self.addSubview(tv)
        tv.font = UIFont.systemFont(ofSize:16)
        tv.layer.borderColor = skin.page.form.label.border.system.cgColor
        tv.layer.borderWidth = 1
        tv.textColor = skin.page.form.label.foregound.system
        tv.backgroundColor = skin.page.form.label.background.system
        tv.layer.cornerRadius = 4
        tv.clipsToBounds = true
        self.onAttach.once {
            if let page:Page = self.ancestor() {
                page.onTap.alive(self) {
                    //Debug.warning("view tap")
                    tv.endEditing(false)
                }
            }
        }
    }
    func add(label:String) {
        let l = UILabel(frame: calcRect(mh+2,16))
        l.backgroundColor = .clear
        l.textAlignment = .left
        l.font = UIFont.appFont(ofSize: 14, weight: .light)
        l.text = label
        l.textColor = skin.colors.black.system
        self.addSubview(l)
    }
    func add(label:String,tags:[String],tap:@ escaping ()->()) {
        let l = UILabel(frame: calcRect(mh+2,16))
        l.backgroundColor = .clear
        l.textAlignment = .left
        l.font = UIFont.appFont(ofSize: 14, weight: .light)
        l.text = label
        l.textColor = skin.colors.black.system
        self.addSubview(l)
        let field = TagsView(frame:calcRect(80),tags:tags)
        self.addSubview(field)
        field.values = tags
        let oh = field.frame.height
        field.sizeToFit()
        y += field.frame.height - oh
        taps.append(TapRecognizer(view:field) { _ in
            if let view:Page = self.ancestor() {
                view.onTap.dispatch(())
            }
            tap()
        })
    }

    // END NEW UI ===========================================================
    
    
    
    public func add(name:String? = nil,text:String,lines:Int = 1,align:NSTextAlignment = .left, font:UIFont = UIFont.appFont(ofSize: 16),color:Color = .white,click: (()->())? = nil) {
        let l = UILabel(frame: calcRect(mh,CGFloat(lines)*font.pointSize))
        l.accessibilityLabel = name
        l.backgroundColor = .clear
        l.textAlignment = align
        l.font = font
        l.text = text
        l.numberOfLines = lines
        l.textColor = color.system
        let oh = l.frame.height
        let ow = l.frame.width
        l.sizeToFit()
        var f = l.frame
        f.size.width = ow
        l.frame = f
        y += l.frame.height - oh
        self.addSubview(l)
        if let c = click {
            taps.append(TapRecognizer(view:l) { _ in
                c()
            })
        }
    }
    public func add(table:[Any],styles:[[String:String]]? = nil,header:[String:String]? = nil) {
        let t = HtmlNode(name:"table",attributes:["cellspacing":"0","cellpadding":"0"],styles:["margin":"0px","padding":"0px","width":"100%","font-family":"San Francisco, sans-serif","font-size":"16"])
        var r = 0
        var hs = header // header style
        for row in table {
            let tr = t.append(name:"tr")
            if let a = row as? [Any] {
                var c = 0
                for col in a {
                    let td = tr.append(name:"td")
                    if let styles = styles {
                        td.styles += styles[c]
                    }
                    if let hs = hs {
                        td.styles += hs
                    }
                    td.text = String(describing:col)
                    c += 1
                }
            } else {
                let td = tr.append(name:"td")
                if let styles = styles {
                    td.styles = styles[0]
                }
                td.text = String(describing:row)
            }
            r += 1
            hs = nil
        }
        self.add(html:t)
    }
    public func add(table:[[String]],width:[Double],link:Bool = false,fn:((Int)->())? = nil) {
        let w = self.bounds.width - mh*2
        var r = 0
        for row in table {
            let cr = r
            var c = 0
            var x = mh
            for col in row {
                let f = getRect(x, CGFloat(width[c])*w, 18)
                let l = UILabel(frame: f)
                l.font = UIFont.appFont(ofSize: 16, weight: (r==0) ? .bold : .regular)
                l.text = col
                if r == 0 {
                    l.textColor = Color.pLogoRed.system
                } else if link && c == row.count-1 {
                    l.textColor = Color.pLogoGreen.system
                } else {
                    l.textColor = Color.pDarkGray.system
                }
                self.taps.append(TapRecognizer(view:l) { _ in
                    fn?(cr)
                });
                self.addSubview(l)
                x += f.size.width
                c += 1
            }
            y += 20
            r += 1
        }
        y += mmv
    }
    public func add(html:HtmlNode) {
        self.add(html:html.html)
    }
    public func add(html:String) {
        let h = "<div style=\"font-family: San Francisco, sans-serif; font-size: 16; color: #404040; text-align: left;\">\(html)</div>"
        let data = h.data(using: .utf8)
        do {
            let str = try NSAttributedString(data:data!,options:[NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],documentAttributes:nil)
            let l = UILabel(frame: calcRect(mh,40))
            l.backgroundColor = .clear
            l.numberOfLines = 0
            l.font = UIFont.appFont(ofSize: 16, weight: .light)
            l.attributedText = str
            self.addSubview(l)
            l.sizeToFit()
            y = CGFloat(Rect(l.frame).bottom)
        } catch {
            Debug.error("can't create html")
        }
    }
    public func add(rtf:String) {
        let data = rtf.data(using: .utf8)
        do {
            let str = try NSAttributedString(data:data!,options:[NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],documentAttributes:nil)
            let l = UILabel(frame: calcRect(mh,40))
            l.backgroundColor = .clear
            l.numberOfLines = 0
            l.font = UIFont.appFont(ofSize: 16, weight: .light)
            l.attributedText = str
            self.addSubview(l)
            l.sizeToFit()
            y = CGFloat(Rect(frame).bottom)
        } catch {
            Debug.error("can't create rtf")
        }
    }
    public func add(logo:UIImage) {
        let img = UIImageView(frame:calcRect(logo.size.height))
        self.addSubview(img)
        img.contentMode = .scaleAspectFit
        img.image = logo
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next {
            var i = 1
            while i<100 {
                if let next = textField.superview?.viewWithTag(textField.tag+i) {
                    if next.canBecomeFocused {
                        next.becomeFirstResponder()
                        break
                    }
                }
                i += 1
            }
            if i>=100 {
                Debug.error("Form.resignFirstResponder error, last textfield should have returnkey = .done")
                textField.resignFirstResponder()
            }
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class BBView : UIView {
    let onAttach = Event<Void>()
    let onDetach = Event<Void>()
    let onLayout = Event<Void>()
    let onResize = Event<CGSize>()
    let onNotify = Event<(message:String,object:Any?)>()
    var prop:[String:Any]=[String:Any]()
    var anims = 0
    var animating : Bool {
        return anims>0
    }
    private var _timers = [String:Alib.Timer]()
    deinit {
        self.onDetach.dispatch(())
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame:CGRect) {
        super.init(frame:frame)
        self.onDetach.once {
            self.unpulseAll()
            self.prop.removeAll()
            self.onAttach.removeAll()
        }
    }
    @objc open override func layoutSubviews() {
        self.onLayout.dispatch(())
        self.onResize.dispatch(self.bounds.size)
    }
    @objc open override func willMove(toWindow newWindow: UIWindow?) {
        // if present viewcontroller (ex: camera) view are temporary detached from window
        if newWindow == nil, let adel = UIApplication.shared.delegate as? AppDelegate, let rc = adel.controller, rc.presentedViewController == nil {
            onDetach.dispatch(())
        }
    }
    @objc open override func didMoveToWindow() {
        if window != nil, let adel = UIApplication.shared.delegate as? AppDelegate, let rc = adel.controller, rc.presentedViewController == nil {
            onAttach.dispatch(())
        }
    }
    open func notify(message:String,object:Any? = nil) {
        self.onNotify.dispatch((message:message,object:object))
    }
    public func notify(toParent message:String,object:Any? = nil) {
        var v = self.superview
        while v != nil {
            if let bbv = v as? BBView {
                bbv.notify(message:message,object:object)
            }
            v = v!.superview
        }
    }
    private func notifyChildren(view:UIView,message:String,object:Any?) {
        if let bbv = view as? BBView {
            bbv.notify(message:message,object:object)
        }
        for v in view.subviews {
            notifyChildren(view:v,message:message,object:object)
        }
    }
    public func notify(toChildren message:String,object:Any? = nil) {
        for v in self.subviews {
            notifyChildren(view:v,message:message,object:object)
        }
    }
    public func pulse(interval:Double,tick: @escaping ()->()) -> String {
        let id = ß.alphaID
        self.ui {
            let t = Alib.Timer(period:interval) {
                tick()
            }
            self._timers[id] = t
        }
        return id
    }
    public func unpulse(timer:String) {
        if let t = _timers[timer] {
            t.stop()
            _timers.remove(at: _timers.index(forKey: timer)!)
        }
    }
    public func unpulseAll() {
        for (_,t) in _timers {
            t.stop()
        }
        _timers.removeAll()
    }
    public func wait(_ duration:Double,fn: @escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
            fn()
        })
    }
    public func ui(fn: @escaping ()->()) {
        DispatchQueue.main.async {
            fn()
        }
    }
    public func animate(duration:Double,anime:@escaping (Double)->()) -> Future {
        let fut=Future(context:"animation")
        let start=ß.time
        if let synced = Application.live["screensync"] as? ScreenSync {
            var a : Action<Void>? = nil
            a = synced.pulse.always {
                let t=(ß.time-start)/duration
                if t<1 {
                    anime(t)
                    fut.progress(t)
                } else {
                    if let a=a {
                        synced.pulse.remove(a)
                    }
                    anime(1)
                    fut.done()
                    a = nil
                }
            }
            fut.onCancel { p in
                if let a=a {
                    synced.pulse.remove(a)
                }
                a = nil
            }
            self.anims += 1
            fut.then { _ in
                self.anims -= 1
            }
        }
        return fut
    }
    public func resize(fn:(()->())? = nil) {
        let mclip = clipsToBounds
        clipsToBounds = true
        let nsz = Size(self.sizeThatFits(self.frame.size))
        var s = Size(self.frame.size)
        let a = self.animate(duration:0.4) { t in
            s = s.lerp(nsz,coef:t)
            self.frame.size = s.system
            self.setNeedsDisplay()
        }
        a.then { _ in
            self.clipsToBounds = mclip
            fn?()
        }
    }
    public func appears(scroll:Bool = false,fn:(()->())? = nil) {
        let mclip = clipsToBounds
        clipsToBounds = true
        let h = frame.size.height
        frame = Rect(frame).set(h:0).system
        let a = self.animate(duration:0.4) { t in
            self.frame = Rect(self.frame).lerp(Rect(self.frame).set(h:Double(h)),coef:t).system
            if scroll, let s:UIScrollView = self.ancestor() {
                s.scrollTo(bottomOf:self,animated:false)
            }
        }
        a.then { _ in
            self.clipsToBounds = mclip
            fn?()
        }
    }
    public func disappears(fn:(()->())? = nil) {
        clipsToBounds = true
        let a = self.animate(duration:0.4) { t in
            self.frame = Rect(self.frame).lerp(Rect(self.frame).set(h:0),coef:t).system
        }
        a.then { _ in
            self.removeFromSuperview()
            fn?()
        }
    }
    public func addBottomLine(view:UIView) {
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = Color.pDarkGray.system.cgColor
        border.frame = CGRect(x: 0, y: view.frame.size.height - width, width:  view.frame.size.width, height: view.frame.size.height)
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true
    }
    public subscript(k:String) -> Any? {
        get {
            if let v=prop[k] {
                if let p = v as? Property {
                    return p.value
                }
                return v
            }
            var p = self.superview
            while p != nil {
                if let bb = p as? BBView {
                    return bb[k]
                }
                p = p?.superview
            }
            return nil
        }
        set(v) {
            if let p=prop[k] as? Node {
                if let p = p as? Property {
                    p.value = v
                    return
                } else if let pv = v as? Node {
                    if pv != p {
                        p.detach()
                    }
                } else {
                    p.detach()
                }
            }
            prop[k]=v
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class BigButton : UIButton {
    var tap:TapRecognizer?
    public init(view:UIView, frame:Rect,label:String,font:UIFont,background:Color = Color.pLogoRed, fn:@escaping (BigButton)->()) {
        super.init(frame:frame.system)
        self.backgroundColor = background.system
        self.layer.cornerRadius = 10.0
        self.clipsToBounds = true
        self.titleLabel?.font = font
        self.setTitle(label, for: .normal)
        self.setTitleColor(.white, for: .normal)
        view.addSubview(self)
        tap = TapRecognizer(view:self) { _ in
            fn(self)
            UIView.animate(withDuration:0.2, animations: {
                self.transform = CGAffineTransform(scaleX:1.1,y:1.1)
            }, completion: { _ in
                UIView.animate(withDuration:0.2, animations: {
                    self.transform = CGAffineTransform(scaleX:1.0,y:1.0)
                }, completion: nil)
            })
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class SimpleButton : UIButton {
    var tap:TapRecognizer?
    public init(view:UIView?,frame:Rect,label:NSAttributedString,click:NSAttributedString? = nil,fn:@escaping ()->()) {
        super.init(frame:frame.system)
        self.setAttributedTitle(label,for:.normal)
        view?.addSubview(self)
        tap = TapRecognizer(view:self) { _ in
            fn()
            if let click=click {
                UIView.transition(with:self, duration:0.2, options:.transitionCrossDissolve, animations: {
                    self.setAttributedTitle(click,for:.normal)
                }, completion: { ok in
                    UIView.transition(with:self, duration:0.2, options:.transitionCrossDissolve, animations: {
                        self.setAttributedTitle(label,for:.normal)
                    }, completion:nil)
                })
            }
        }
    }
    public init(view:UIView?,frame:Rect,label:String,font:UIFont,color:Color = Color.pLogoBlue, fn:@escaping ()->()) {
        super.init(frame:frame.system)
        self.titleLabel?.font = font
        self.setTitleColor(color.system, for: .normal)
        self.setTitle(label, for: .normal)
        view?.addSubview(self)
        tap = TapRecognizer(view:self) { _ in
            fn()
            UIView.transition(with:self, duration:0.2, options:.transitionCrossDissolve, animations: {
                self.setTitleColor(.black,for:.normal)
            }, completion: { ok in
                UIView.transition(with:self, duration:0.2, options:.transitionCrossDissolve, animations: {
                    self.setTitleColor(color.system,for:.normal)
                }, completion:nil)
            })
        }
    }
    public init(view:UIView?,frame:Rect,icon:String,color:Color = Color.pLogoBlue, fn:@escaping ()->()) {
        super.init(frame:frame.system)
        self.tintColor = color.system
        self.setImage(UIImage(named:icon)!.withRenderingMode(.alwaysTemplate),for:.normal)
        view?.addSubview(self)
        tap = TapRecognizer(view:self) { _ in
            fn()
            UIView.animate(withDuration:0.2, animations: {
                self.tintColor = .black
            }, completion: { _ in
                UIView.animate(withDuration:0.2, animations: {
                    self.tintColor = color.system
                }, completion: nil)
            })
        }
    }
    public init(view:UIView?,frame:Rect,icon:UIImage,color:Color = Color.pLogoBlue, fn:@escaping ()->()) {
        super.init(frame:frame.system)
        self.tintColor = color.system
        self.setImage(icon,for:.normal)
        view?.addSubview(self)
        tap = TapRecognizer(view:self) { _ in
            fn()
            UIView.animate(withDuration:0.2, animations: {
                self.tintColor = .black
            }, completion: { _ in
                UIView.animate(withDuration:0.2, animations: {
                    self.tintColor = color.system
                }, completion: nil)
            })
        }
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
}
class SimpleShadowButton : SimpleButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(view:UIView?,frame:Rect,label:String,font:UIFont,color:Color = Color.pLogoBlue, fn:@escaping ()->()) {
        super.init(view:view,frame:frame,label:label,font:font,color:color,fn:fn)
    }
    public override init(view:UIView?,frame:Rect,icon:String,color:Color = Color.pLogoBlue, fn:@escaping ()->()) {
        super.init(view:view,frame:frame,icon:icon,color:color,fn:fn)
    }
    @objc override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.saveGState()
        ctx!.setShadow(offset:CGSize(width:0,height:20),blur:5,color:UIColor.black.cgColor)
        super.draw(rect)
        ctx!.restoreGState()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SimpleButtonItem : UIBarButtonItem {
    let fn:()->()
    required init?(coder aDecoder: NSCoder) {
        self.fn = { }
        super.init(coder:aDecoder)
    }
    public init(name:String? = nil,image:UIImage? = nil,label:String? = nil,fn:@escaping ()->()) {
        self.fn = fn
        super.init()
        if let i = image, let l = label {
            let b = Button(label:l,image:i)
            self.customView = b
            b.onClick.alive(b) {
                fn()
            }
        } else {
            self.image = image
            self.title = label
        }
        self.style = .plain
        self.target = self
        self.action = #selector(click)
        self.accessibilityLabel = name
    }
    @objc func click() {
        fn()
    }
    public var color : UIColor {
        get {
            if let b = self.customView as? Button {
                return b.color
            } else {
                return self.tintColor ?? UIColor.gray
            }
        }
        set(c) {
            if let b = self.customView as? Button {
                b.color = c
            } else {
                self.tintColor = c
            }
        }
    }
    class Button : BBView {
        let onClick = Event<Void>()
        var tap:TapRecognizer? = nil
        var label:UILabel? = nil
        var image:UIImageView? = nil
        var toColor:UIColor?
        required init?(coder aDecoder: NSCoder) {
            super.init(coder:aDecoder)
        }
        public init(size:CGSize = CGSize(width:60,height:60),label:String,image:UIImage) {
            super.init(frame:CGRect(x:0,y:0,width:size.width,height:size.height))
            let widthConstraint = self.widthAnchor.constraint(equalToConstant:size.width)
            let heightConstraint = self.heightAnchor.constraint(equalToConstant:size.height)
            heightConstraint.isActive = true
            widthConstraint.isActive = true
            let iv = UIImageView(frame:Rect(CGRect(x:0,y:0,width:bounds.width,height:bounds.height-20)).extend(-4).system)
            self.addSubview(iv)
            self.image = iv
            iv.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            iv.contentMode = .scaleAspectFit
            iv.tintColor = .gray
            iv.image = image.withRenderingMode(.alwaysTemplate)
            let lbl = UILabel(frame:CGRect(x:0,y:bounds.height-20,width:bounds.width,height:16))
            self.addSubview(lbl)
            self.label = lbl
            lbl.autoresizingMask = [.flexibleWidth,.flexibleTopMargin]
            lbl.textColor = .gray
            lbl.textAlignment = .center
            lbl.font = UIFont.systemFont(ofSize: 12)// .appFont(ofSize:12,weight:.light)
            lbl.text = label
            tap = TapRecognizer(view:self) { _ in
                self.toColor = iv.tintColor
                self.animate(duration:0.05) { t in
                    let c = Color(lbl.textColor).lerp(to:.black,coef:t).system
                    lbl.textColor = c
                    iv.tintColor = c
                }.then { _ in
                    _ = self.animate(duration:0.2) { t in
                        let c = Color(lbl.textColor).lerp(to:Color(self.toColor!),coef:t).system
                        lbl.textColor = c
                        iv.tintColor = c
                    }
                }
                self.onClick.dispatch(())
            }
        }
        public var color : UIColor {
            get {
                return label?.textColor ?? UIColor.gray
            }
            set(c) {
                if animating {
                    toColor = c
                } else {
                    label?.textColor = c
                    image?.tintColor = c
                }
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class TapRecognizer : NSObject {
    var tap : UITapGestureRecognizer?
    let click : (CGPoint)->()
    public init(view:UIView,count:Int = 1,click: @escaping (CGPoint)->()) {
        self.click = click
        super.init()
        tap = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tap!.numberOfTapsRequired = count
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap!)
        
    }
    deinit {
        if let t=tap, let v=t.view {
            v.removeGestureRecognizer(t)
        }
    }
    @objc public func tapDetected() {
        let p = tap!.location(in:tap!.view)
        click(p)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SwipeRecognizer : NSObject,UIGestureRecognizerDelegate {
    let onSwipe = Event<Void>()
    var swipe : UISwipeGestureRecognizer?
    var fn:(()->())?
    weak var view : UIView?
    public init(view:UIView,direction:UISwipeGestureRecognizer.Direction,fn:(()->())? = nil) {
        self.view = view
        self.fn = fn
        super.init()
        swipe = UISwipeGestureRecognizer(target:self,action:#selector(drag))
        swipe!.numberOfTouchesRequired = 1
        swipe!.direction = direction
        swipe!.delegate = self
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(swipe!)
        if let ss = view as? BBScrollStack, let scroll = ss.scroll {
            scroll.panGestureRecognizer.require(toFail: swipe!)
        }
    }
    deinit {
        if let p=swipe, let v=view {
            v.removeGestureRecognizer(p)
        }
    }
    @objc func drag(_ sender:UISwipeGestureRecognizer){
        fn?()
        onSwipe.dispatch(())
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let ss = view as? BBScrollStack, let scroll = ss.scroll {
            return otherGestureRecognizer == scroll.panGestureRecognizer
        }
        return false
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class ImagePicker : NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    let onDismiss = Event<Void>()
    var picker:UIImagePickerController?
    let image: (UIImage?)->()
    public init(type: UIImagePickerController.SourceType, image: @escaping (UIImage?)->()) {
        self.image = image
        super.init()
        if let adel = UIApplication.shared.delegate as? AppDelegate, let rc = adel.controller {
            picker = UIImagePickerController()
            picker!.sourceType  = type
            //picker!.allowsEditing = true;
            picker!.delegate = self
            picker!.mediaTypes = [String(kUTTypeImage)]
            rc.present(picker!, animated: true, completion: nil)
        }
    }
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let i = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        if let image = i[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            self.image(image)
        }
        self.picker!.dismiss(animated: true, completion: {
            self.picker = nil
            self.onDismiss.dispatch(())
        })
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.image(nil)
        self.picker!.dismiss(animated: true, completion: {
            self.picker = nil
            self.onDismiss.dispatch(())
        })
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class SimpleSource : NSObject,UIPickerViewDataSource,UIPickerViewDelegate {
    let values:[String]
    var changed : ((String)->())?
    public private(set) var selected = 0
    public init(values:[String]) {
        self.values = values
    }
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[row]
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected = row
        changed?(values[row])
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class SimplePickerView : UIPickerView {
    let source : SimpleSource
    var changed : ((String)->())?
    public var clickMode = true {
        didSet {
            self.alpha = clickMode ? 0.5 : 1
        }
    }
    public var current : String {
        get {
            return self.source.values[self.source.selected]
        }
        set(c) {
            var i = 0
            for vs in source.values {
                if vs == c {
                    self.selectRow(i, inComponent: 0, animated: false)
                    break
                }
                i += 1;
            }
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        source = SimpleSource(values:[])
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,values:[String]) {
        source = SimpleSource(values:values)
        super.init(frame:frame)
        source.changed = { value in
            self.changed?(value)
        }
        self.isOpaque = false
        self.dataSource = source
        self.delegate = source
        self.alpha = 0.5
        self.isUserInteractionEnabled = true
    }
    @objc override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !clickMode {
            super.touchesBegan(touches, with: event)
        }
    }
    @objc override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !clickMode {
            super.touchesBegan(touches, with: event)
        }
    }
    @objc override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !clickMode {
            super.touchesBegan(touches, with: event)
        }
        if clickMode {
            clickMode = false
        }
    }
    @objc override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !clickMode {
            super.touchesBegan(touches, with: event)
        }
    }
    @objc override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if clickMode && self.bounds.contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SimpleTextField : UITextField {
    var changed : ((String)->())?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame:CGRect) {
        super.init(frame:frame)
        self.addTarget(self, action: #selector(cchanged), for: .editingChanged)
    }
    @objc func cchanged() {
        if let text = self.text {
            changed?(text)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SimpleTextView : UITextView,UITextViewDelegate {
    var changed : ((String)->())?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect) {
        super.init(frame:frame,textContainer:nil)
        self.delegate = self
        self.isEditable = true
    }
    func textViewDidChange(_ textView: UITextView) {
        if let text = self.text {
            changed?(text)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SimpleImageSelect : BBView {
    var changed : ((Int)->())?
    var taps = [TapRecognizer]()
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,images:[UIImage],value:Int) {
        super.init(frame:frame)
        let sz = Size(images[0].size)
        let w = sz.width+8
        var r = Rect(x:0,y:(Double(frame.height)-sz.height)*0.5,w:sz.width,h:sz.height)
        var n = 0
        var current:UIImageView?
        for i in images {
            let v = n
            let iv = UIImageView(frame: r.system)
            self.addSubview(iv)
            iv.image = i.withRenderingMode(.alwaysTemplate)
            iv.contentMode = .scaleAspectFit
            if v == value {
                current = iv
                iv.tintColor = Color.pLogoBlue.system
            } else {
                iv.tintColor = Color.pDarkGray.system
            }
            taps.append(TapRecognizer(view:iv) { _ in
                if let c = current {
                    c.tintColor = Color.pDarkGray.system
                }
                iv.tintColor = Color.pLogoBlue.system
                current = iv
                self.changed?(v)
            })
            r.x += w
            n += 1
        }
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
    public init(frame:CGRect,images:[UIImage],selected:[UIImage],value:Int) {
        super.init(frame:frame)
        let sz = Size(images[0].size)
        let w = sz.width+8
        var r = Rect(x:0,y:(Double(frame.height)-sz.height)*0.5,w:sz.width,h:sz.height)
        var n = 0
        var current:UIImageView?
        for _ in images {
            let v = n
            let iv = UIImageView(frame: r.system)
            iv.accessibilityLabel = String(v)
            self.addSubview(iv)
            iv.contentMode = .scaleAspectFit
            if v == value {
                current = iv
                iv.image = selected[v].withRenderingMode(.alwaysTemplate)
                iv.tintColor = Color.pLogoBlue.system
            } else {
                iv.image = images[v].withRenderingMode(.alwaysTemplate)
                iv.tintColor = Color.pDarkGray.system
            }
            taps.append(TapRecognizer(view:iv) { _ in
                if let c = current {
                    let n = Int(c.accessibilityLabel!)!
                    c.tintColor = Color.pDarkGray.system
                    c.image = images[n].withRenderingMode(.alwaysTemplate)
                }
                iv.tintColor = Color.pLogoBlue.system
                iv.image = selected[v].withRenderingMode(.alwaysTemplate)
                current = iv
                self.changed?(v)
            })
            r.x += w
            n += 1
        }
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MultiSelect : BBView {
    var changed : (([String])->())?
    var taps = [TapRecognizer]()
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,select:[String],value v:[String]) {
        super.init(frame:frame)
        var values = v
        var y:CGFloat = 0
        for s in select {
            let selected = values.contains(element: s)
            let sww:CGFloat = 48
            let l = UILabel(frame: CGRect(x:0.0,y:y,width:bounds.width-sww,height:24.0))
            l.backgroundColor = .clear
            l.textAlignment = .left
            l.font = UIFont.appFont(ofSize: 16)
            l.text = s
            l.numberOfLines = 1
            l.textColor = selected ? Color.pLogoBlue.system : Color.pDarkGray.system
            self.addSubview(l)
            let sw = SimpleSwitch(frame: CGRect(x:bounds.width-sww,y:y-4,width:sww,height:24.0))
            sw.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            sw.tintColor = Color.pDarkGray.system
            sw.onTintColor = Color.pLogoBlue.system
            sw.changed = { on in
                l.textColor = on ? Color.pLogoBlue.system : Color.pDarkGray.system
                if on {
                    values.append(s)
                } else {
                    values.remove(at: values.index(of: s)!)
                }
                self.changed?(values)
            }
            sw.setOn(selected,animated: false)
            self.addSubview(sw)
            y += l.frame.height
        }
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
    public static func height(count:Int) -> CGFloat {
        return max(CGFloat(count) * 24, 40)
    }
}
class SimpleSwitch : UISwitch {
    var changed : ((Bool)->())?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame: CGRect) {
        super.init(frame:frame)
        self.addTarget(self, action: #selector(cchanged), for: .valueChanged)
    }
    @objc func cchanged() {
        changed?(self.isOn)
    }
}
class SimpleMultiSelect : BBView {
    var changed : (([String])->())?
    var taps = [TapRecognizer]()
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,select:[String],value v:[String]) {
        super.init(frame:frame)
        var values = v
        let scroll = UIScrollView(frame: self.bounds)
        var y:CGFloat = 0
        for s in select {
            var selected = values.contains(element: s)
            let l = UILabel(frame: CGRect(x:0.0,y:y,width:bounds.width,height:24.0))
            l.backgroundColor = .clear
            l.textAlignment = .center
            l.font = UIFont.appFont(ofSize: 16)
            l.text = s
            l.numberOfLines = 1
            l.textColor = selected ? Color.pLogoBlue.system : Color.pDarkGray.system
            y += l.frame.height
            scroll.addSubview(l)
            taps.append(TapRecognizer(view:l) { _ in
                if selected {
                    values.remove(at: values.index(of: s)!)
                } else {
                    values.append(s)
                }
                selected = !selected
                l.textColor = selected ? Color.pLogoBlue.system : Color.pDarkGray.system
                self.changed?(values)
            })
        }
        scroll.contentSize = CGSize(width:bounds.width,height:y)
        self.addSubview(scroll)
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
}
public class SimpleSegments : UISegmentedControl {
    var changed:((Int)->())?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,segments:[String]) {
        super.init(frame:frame)
        var i = 0
        for s in segments {
            self.insertSegment(withTitle:s,at:i,animated:false)
            i += 1
        }
        //selectedSegmentIndex = 0
        self.addTarget(self,action:#selector(cchanged),for:.valueChanged)
    }
    public init(frame:CGRect,segments:[UIImage]) {
        super.init(frame:frame)
        var i = 0
        for s in segments {
            self.insertSegment(with:s,at:i,animated:false)
            i += 1
        }
        //selectedSegmentIndex = 0
        self.addTarget(self,action:#selector(cchanged),for:.valueChanged)
    }
    public func insert(segment:String,at:Int) {
        self.insertSegment(withTitle:segment,at:at,animated:true)
    }
    public func insert(segment:UIImage,at:Int) {
        self.insertSegment(with:segment,at:at,animated:true)
    }
    public func add(segment:String) -> Int {
        let n = self.numberOfSegments
        self.insertSegment(withTitle:segment,at:n,animated:true)
        return n
    }
    public func add(segment:UIImage) -> Int {
        let n = self.numberOfSegments
        self.insertSegment(with:segment,at:n,animated:true)
        return n
    }
    public func remove(segment:Int) {
        self.removeSegment(at:segment,animated:true)
    }
    @objc func cchanged() {
        changed?(self.selectedSegmentIndex)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class SimpleActionSheet {
    public init(title:String,description:String = "",select:[String],fn: @escaping (String)->()) {
        let alert = UIAlertController(title:title,message:description,preferredStyle:.actionSheet)
        for s in select {
            alert.addAction(UIAlertAction(title: s, style: .default) { a in
                fn(a.title!)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        })
        if let app = UIApplication.shared.delegate as? AppDelegate {
            app.controller?.present(alert, animated: true) {
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class SimpleDatePicker : BBView {
    var changed : ((String)->())?
    var tap:TapRecognizer?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,title:String,value:String) {
        super.init(frame: frame)
        let label = UILabel(frame:self.bounds)
        label.text = ß.justLocaleDate(date:value)
        self.addSubview(label)
        var date = value
        self.tap = TapRecognizer(view:self) { _ in
            let alert = BBAlertDate(parent:self["mainview"] as! UIView,title:title,value:date)
            alert.changed = { value in
                date = value
                label.text = ß.justLocaleDate(date:value)
                self.changed?(value)
            }
            alert.changed?(alert.get()) // set default value (today) in case no value yet
        }
        self.onDetach.once {
            self.tap = nil
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class BBAlertDate : BBAlertTemplate {
    var changed:((String)->())?
    var date:UIDatePicker?
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(parent:UIView,title:String,value:String) {
        super.init(parent:parent,title:title)
        self.select!.frame = Rect(self.select!.frame).set(h:120).system
        date = UIDatePicker(frame: self.select!.bounds)
        date!.datePickerMode = .date
        date!.addTarget(self, action: #selector(cchanged), for: .valueChanged)
        self.set(date:value)
        self.select!.addSubview(date!)
        self.layout()
    }
    @objc func cchanged() {
        changed?(self.get())
    }
    public func set(date:String) {
        let pub = DateFormatter()
        pub.locale = Locale(identifier:"en_US_POSIX")
        pub.timeZone = TimeZone(secondsFromGMT: 0)
        pub.dateFormat="yyyy-MM-dd"
        if let d = pub.date(from: date) {
            self.date!.date = d
        }
    }
    public func get() -> String {
        let pub = DateFormatter()
        pub.locale = Locale(identifier:"en_US_POSIX")
        pub.timeZone = TimeZone(secondsFromGMT: 0)
        pub.dateFormat="yyyy-MM-dd"
        return pub.string(from:date!.date)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class BBAlertTemplate : BBView {
    var background:UIView?
    var select:BBView?
    var button:BBView?
    var taps = [TapRecognizer]()
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(parent:UIView,title:String,button:String = "OK") {
        super.init(frame: parent.bounds)
        self.background = UIView(frame:self.bounds)
        self.addSubview(self.background!)
        self.background!.backgroundColor = .black
        self.background!.alpha = 0.0
        parent.addSubview(self)
        self.select = BBView(frame: self.bounds)
        self.addSubview(self.select!)
        self.select!.backgroundColor = .white
        self.select!.layer.cornerRadius = 8;
        self.select!.layer.masksToBounds = true;
        self.button = BBView(frame: self.bounds)
        self.addSubview(self.button!)
        self.button!.backgroundColor = .white
        self.button!.layer.cornerRadius = 8;
        self.button!.layer.masksToBounds = true;
        let l = UILabel(frame:self.button!.bounds)
        l.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        l.textAlignment = .center
        l.text = button
        l.textColor = skin.colors.dark.system
        l.font = UIFont.appFont(ofSize:20,weight:.bold)
        self.button!.addSubview(l)
        taps.append(TapRecognizer(view:self.button!) { _ in
            self.disappears()
        })
        taps.append(TapRecognizer(view:background!) { _ in
            self.disappears()
        })
        self.onDetach.once {
            self.taps.removeAll()
        }
    }
    public override func disappears(fn: (() -> ())? = nil) {
        var s = Rect(self.select!.frame)
        var b = Rect(self.button!.frame)
        let dy = Double(self.bounds.size.height) - s.y
        s.y += dy
        b.y += dy
        let a = self.animate(duration:0.4) { t in
            self.background!.alpha = CGFloat(0.2 * (1-t))
            self.select!.frame = Rect(self.select!.frame).lerp(s,coef:t).system
            self.button!.frame = Rect(self.button!.frame).lerp(b,coef:t).system
        }
        a.then { _ in
            self.removeFromSuperview()
        }
    }
    func layout() {
        let m = 10.0
        let r = Rect(self.bounds).extend(w:-m, h:0)
        var y = Rect(self.bounds).bottom - m
        self.button!.frame = r.set(y:y-60,h:60).system
        y -= Double(self.button!.frame.size.height) + m
        let sh = Double(self.select!.frame.height)
        self.select!.frame = r.set(y:y-sh,h:sh).system
        // appears
        let s = Rect(self.select!.frame)
        let b = Rect(self.button!.frame)
        let dy = Double(self.bounds.size.height) - s.y
        self.select!.frame = s.translate(x:0,y:dy).system
        self.button!.frame = b.translate(x:0,y:dy).system
        _ = self.animate(duration:0.4) { t in
            self.background!.alpha = CGFloat(0.2 * t)
            self.select!.frame = Rect(self.select!.frame).lerp(s,coef:t).system
            self.button!.frame = Rect(self.button!.frame).lerp(b,coef:t).system
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
