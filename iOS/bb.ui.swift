//
//  bb.ui.controls.swift
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
import Alib

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
class Menu : BBView {
    var select:((Menu,Int)->())?
    var r:CGFloat = 0
    var tap:TapRecognizer?
    var position:CGPoint
    var items = [String]()
    var buttons = [UILabel]()
    var taps = [TapRecognizer]()
    var lines = 0.0
    var sub = false
    required init?(coder aDecoder: NSCoder) {
        self.position = CGPoint.zero
        super.init(coder:aDecoder)
    }
    init(frame:CGRect,position:CGPoint,items:[String],select:((Menu,Int)->())?) {
        self.select = select
        self.position = position
        self.items = items
        super.init(frame:frame)
        self.isOpaque = false
        self.backgroundColor = .clear
        tap = TapRecognizer(view:self) { _ in
            self.disappears()
        }
        self.appears()
    }
    func subMenu(items:[String],select:@escaping (Menu,Int)->()) {
        sub = true
        self.buttonDisappears {
            self.sub = false
            self.items = items
            self.buttonAppears()
            self.select = select
        }
    }
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        let color = Color(a:0.6,rgb:Color.white).system.cgColor
        for b in buttons {
            var p = Point.zero
            if b.center.x < position.x {
                p = Rect(b.frame).point(1,0.5)
            } else {
                p = Rect(b.frame).point(0,0.5)
            }
            ctx.beginPath()
            let a = (p - Point(position)).angle
            let p0 = (Point(position)+Point(angle:a,radius:Double(self.r)))
            ctx.move(to:p0.system)
            ctx.addLine(to: ((p-p0)*lines+p0).system)
            ctx.setLineWidth(1)
            ctx.setLineDash(phase:0,lengths:[])
            ctx.setStrokeColor(color.components!)
            ctx.strokePath()
        }
        ctx.beginPath()
        ctx.addEllipse(in: CGRect(x:position.x-r,y:position.y-r,width:r*2,height:r*2))
        ctx.setFillColor(color)
        ctx.setBlendMode(.normal)
        ctx.fillPath()
    }
    func addButtons() {
        let b = Rect(bounds)
        let p = Point(position)
        var ny = (items.count-1) / 2
        let sz = Size(120,24)
        let h = 40.0
        let r = 40.0
        var left = true
        var one = false
        if b.right - p.x < sz.width + r {
            one = true
            left = true
            ny = items.count - 1
        } else if p.x < sz.width + r {
            one = true
            left = false
            ny = items.count - 1
        }
        var y = -h*Double(ny)*0.5
        var n = 0
        for i in items {
            let nbut = n
            let dir = left ? -1.0 : 1.0
            let x = dir * r
            let a = (Point(x,y)).angle
            let cp = p+Point(Point(angle:a,radius:r).x,y)
            var frame = Rect.zero
            if left {
                frame.right = cp.x
                frame.left = cp.x - sz.w
                frame.top = cp.y - sz.h*0.5
                frame.bottom = cp.y + sz.h*0.5
            } else {
                frame.left = cp.x
                frame.right = cp.x + sz.w
                frame.top = cp.y - sz.h*0.5
                frame.bottom = cp.y + sz.h*0.5
            }
            let l = UILabel(frame:frame.system)
            self.addSubview(l)
            buttons.append(l)
            l.backgroundColor = .white
            l.layer.cornerRadius = 6
            l.clipsToBounds = true
            l.textAlignment = .center
            l.font = UIFont.appFont(ofSize: 12)
            l.textColor = Color.pDarkGray.system
            l.text = i
            if !one {
                left = !left
            }
            if left || one {
                y += h
            }
            taps.append(TapRecognizer(view:l) { _ in
                self.select?(self,nbut)
                if !self.sub {
                    self.disappears()
                }
            });
            n += 1
        }
    }
    func buttonAppears(fn:(()->())? = nil) {
        self.addButtons()
        var s = 0.001
        for b in buttons {
            b.transform = CGAffineTransform(scaleX:CGFloat(s),y:CGFloat(s))
        }
        let a = self.animate(duration:0.2) { t in
            self.lines = (1 - self.lines) * t + self.lines
            s = (1 - s) * t + s
            let t = CGAffineTransform(scaleX:CGFloat(s),y:CGFloat(s))
            for b in self.buttons {
                b.transform = t
            }
            self.setNeedsDisplay()
        }
        a.then { _ in
            fn?()
            self.setNeedsDisplay()
        }
    }
    func buttonDisappears(fn:(()->())? = nil) {
        let ds = 0.001
        var s = 1.0
        self.setNeedsDisplay()
        let a  = self.animate(duration:0.2) { t in
            self.lines = (0 - self.lines) * t + self.lines
            s = (ds - s) * t + s
            let t = CGAffineTransform(scaleX:CGFloat(s),y:CGFloat(s))
            for b in self.buttons {
                b.transform = t
            }
            self.setNeedsDisplay()
        }
        a.then { _ in
            for b in self.buttons {
                b.removeFromSuperview()
            }
            self.buttons.removeAll()
            fn?()
        }
    }
    override func appears(scroll:Bool = false,fn: (() -> ())? = nil) {
        if self.buttons.count == 0 {
            self.buttonAppears()
        }
        var v = 0.0
        _ = self.animate(duration: 0.7) { t in
            v = v * (1-t) + t * t
            self.backgroundColor = Color(self.backgroundColor ?? UIColor.clear).lerp(to:Color(a:0.2,l:0.2),coef:v).system
        }
        self.animate(duration:0.2) { t in
            self.r = (10 - self.r) * CGFloat(t) + self.r
            self.setNeedsDisplay()
        }.then { _ in
            fn?()
        }
    }
    override func disappears(fn: (() -> ())? = nil) {
        if buttons.count>0 {
            self.buttonDisappears()
        }
        var v = 0.0
        self.animate(duration:0.2,anime:{ t in
            v = v * (1-t) + t * t
            //self.backgroundColor = Color(self.backgroundColor ?? UIColor.clear).lerp(to:Color(a:0,l:0.2),coef:v).system
            self.backgroundColor = Color(self.backgroundColor!).lerp(to:Color.transparent,coef:v).system
            self.r = (0 - self.r) * CGFloat(t) + self.r
            self.setNeedsDisplay()
        }).then { _ in
            fn?()
            self.removeFromSuperview()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
public class IconView : BBView {
    var nlab = 0
    var image:UIImageView? {
        return subviews.first as? UIImageView
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,image:String,color:UIColor) {
        super.init(frame:frame)
        let iv = UIImageView(frame:bounds)
        self.addSubview(iv)
        iv.image = UIImage(named:image)!.withRenderingMode(.alwaysTemplate)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = color
    }
    public func add(label:String,color:UIColor,background:UIColor) {
        let hl = 0.6
        let l = UILabel(frame:Rect(bounds).percent(0.5,1-Double(1+nlab)*hl,0.7,hl*0.9).system)
        l.layer.cornerRadius = floor(l.frame.height*0.5)
        l.clipsToBounds = true
        self.addSubview(l)
        l.backgroundColor = background
        l.font = UIFont.appCondensedFont(ofSize:floor(l.frame.height*0.8),weight:.bold)
        l.text = label
        l.textColor = color
        l.textAlignment = .center
        nlab += 1
    }
    public func clear() {
        nlab = 0
        let sv = self.subviews
        for v in sv {
            if let l = v as? UILabel {
                l.removeFromSuperview()
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////
public class IconField : BBView {
    let onChanged = Event<Int>()
    var taps = [TapRecognizer]()
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,icons:[String]) {
        super.init(frame:frame)
        let n = CGFloat(icons.count)
        let w = min(bounds.height,(bounds.width-(n-1)*4)/n)
        let m = (bounds.width - w*n) / (n-1)
        let y = (bounds.height - w)*0.5
        var x:CGFloat = 0
        var i = 0
        for ic in icons {
            let current = i
            let iv = IconView(frame:CGRect(x:x,y:y,width:w,height:w),image:ic,color:skin.colors.dark.system)
            self.addSubview(iv)
            x += w+m
            i += 1
            taps.append(TapRecognizer(view:iv) { _ in
                self.select(icon:current)
                self.onChanged.dispatch(current)
            })
        }
    }
    public func select(icon:Int) {
        var i = 0
        for v in self.subviews {
            if let ic = v as? IconView {
                ic.image?.tintColor = (i==icon) ? skin.colors.white.system : skin.colors.dark.system
            }
            i += 1
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
public class TextField : UITextField,UITextFieldDelegate {
    let onFocus = Alib.Event<Bool>()
    let onChange = Alib.Event<String>()
    let onStoppedTyping = Alib.Event<Void>()
    let onSuggestion = Alib.Event<String>()
    var rview:BBView?
    var clear:UIView? = nil
    var table:TableView? = nil
    var waitAfter : Future?
    var animating = false
    var menuSuperview : UIView? = nil
    var menuBackground : UIColor = .white
    var readOnly = false
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public init(frame:CGRect,button:SimpleButton? = nil,buttonColor:Color? = nil) {
        super.init(frame:frame)
        self.delegate = self
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        self.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        self.addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        self.addTarget(self, action: #selector(textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
        
        rview = BBView(frame: CGRect(x:0,y:0,width:24,height:16))
        self.rightViewMode = .always
        self.rightView = rview
        if let b = button {
            rview?.addSubview(b)
            self.clear = b
        } else {
            let clear = SimpleButton(view:rview,frame:Rect(x:0,y:0,w:16,h:16),icon:skin.page.icons.delete,color:buttonColor ?? skin.page.form.label.title) {
                self.text = ""
                self.suggest(words:[])
            }
            self.clear = clear
        }
    }
    public init(frame:CGRect,label:String) {
        super.init(frame:frame)
        self.delegate = self
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        self.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        self.addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        self.addTarget(self, action: #selector(textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
        let l = UILabel(frame:bounds)
        l.text = label
        l.font = UIFont.systemFont(ofSize:12,weight:.light)
        l.textColor = skin.page.form.label.title.system
        l.sizeToFit()
        l.frame.size.width += 8
        self.rightViewMode = .always
        self.rightView = l
        self.leftView = UIView(frame:CGRect(x:0,y:0,width:8,height:8))
        self.leftViewMode = .always
        let clear = UIView(frame:CGRect(x:0,y:0,width:24,height:16))
        _ = SimpleButton(view:clear,frame:Rect(x:0,y:0,w:16,h:16),icon:skin.page.icons.delete,color:skin.page.form.label.title) {
            self.text = ""
        }
        _ = self.onFocus.always { focus in
            if focus {
                self.rightView = clear
            } else {
                self.rightView = l
            }
        }
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if readOnly {
            return false
        }
        self.onFocus.dispatch(true)
        self.onStoppedTyping.dispatch(())
        return true
    }
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.onFocus.dispatch(false)
        self.suggest(words:[])
        return true
    }
    @objc func textFieldDidChange() {
        onChange.dispatch(self.text ?? "")
        if let wa = waitAfter {
            wa.cancel()
            waitAfter = nil
        }
        waitAfter = Node.wait(0.8) {
            self.onStoppedTyping.dispatch(())
            self.waitAfter = nil
        }
    }
    @objc func textFieldDidBeginEditing() {
    }
    @objc func textFieldDidEndEditing() {
    }
    @objc func textFieldDidEndEditingOnExit() {
    }
    public func suggest(words:[String]) {
        if table == nil {
            let f = CGRect(x:frame.origin.x,y:frame.origin.y+frame.size.height+4,width:frame.size.width,height:0)
            if let msv = menuSuperview, let sv=self.superview {
                table = TableView(frame:sv.convert(f,to:msv),values:[])
                table?.accessibilityHint = "overlay"
                table!.sizeToFit()
                msv.addSubview(table!)
            } else if let msv = self.window?.rootViewController?.view, let sv=self.superview {
                table = TableView(frame:sv.convert(f,to:msv),values:[])
                table?.accessibilityHint = "overlay"
                table!.sizeToFit()
                msv.addSubview(table!)
            } else {
                Debug.error("no superview")
            }
            table!.backgroundColor = self.menuBackground
            _ = table!.onSelect.always { value in
                self.text = value
                self.onSuggestion.dispatch(value)
            }
            _ = table!.onDisplay.always {
                if let scroll:BBScrollStack = self.rview?.ancestor() {
                    scroll.scroll?.scrollTo(view:self.table!,animated:true)
                }
            }
        }
        table?.values = words
    }
    func animate() {
        rview?.animate(duration: 0.5) { t in
            self.clear?.transform = CGAffineTransform(rotationAngle:CGFloat(t*ß.π*2))
            }.then { _ in
                if self.animating {
                    self.animate()
                }
        }
    }
    public func activity(display:Bool) {
        animating = display
        if display {
            animate()
        }
    }
    class TableView : UITableView,UITableViewDelegate,UITableViewDataSource {
        let onSelect = Alib.Event<String>()
        let onDisplay = Alib.Event<Void>()
        let ceilHeight:CGFloat = 24
        public var values = [String]() {
            didSet {
                self.tableHeaderView = nil
                self.sizeToFit()
                self.reloadData()
                if values.count>0 {
                    onDisplay.dispatch(())
                }
            }
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder:aDecoder)
        }
        public init(frame:CGRect,values:[String]) {
            super.init(frame:frame,style:.plain)
            self.delegate = self
            self.dataSource = self
            self.separatorStyle = .none
            self.values = values
            self.layer.cornerRadius = 5
            self.clipsToBounds = true
            
            //self.layer.shadowPath = UIBezierPath(roundedRect:self.bounds,cornerRadius:self.layer.cornerRadius).cgPath
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.5
            self.layer.shadowOffset = CGSize(width: 4, height: 4)
            self.layer.shadowRadius = 4
            self.layer.masksToBounds = false
        }
        public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            return nil
        }
        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return values.count
        }
        public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 0
        }
        public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return 0
        }
        public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return ceilHeight
        }
        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let c = UITableViewCell(style:.default,reuseIdentifier:"zob2042")
            c.backgroundColor = .clear
            c.textLabel?.text = values[indexPath.row]
            return c
        }
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            onSelect.dispatch(values[indexPath.row])
        }
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width:size.width,height:self.height)
        }
        var height : CGFloat {
            return CGFloat(values.count) * ceilHeight
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////


