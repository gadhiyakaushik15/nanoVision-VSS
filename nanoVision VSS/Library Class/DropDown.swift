
//
//  DropDown.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 30/05/24.
//

import UIKit

class DropDown : UITextField {

    private var arrow : Arrow!
    private var table : UITableView!
    private var shadow : UIView!
    var selectedIndex: Int?

    //MARK: IBInspectable
    @IBInspectable public var rowHeight: CGFloat = 30
    @IBInspectable public var hideOptionsWhenSelect = true
    @IBInspectable public var paddingLeft: CGFloat = 0
    @IBInspectable public var paddingRight: CGFloat = 0

    @IBInspectable  public var isSearchEnable: Bool = true {
        didSet{
            addGesture()
        }
    }


    @IBInspectable public var borderColor: UIColor =  UIColor.lightGray {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable public var listHeight: CGFloat = 150{
        didSet {

        }
    }
    @IBInspectable public var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    @IBInspectable public var cornerRadius: CGFloat = 5.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    //Variables
    fileprivate var tableHeightX: CGFloat = 100
    fileprivate var dataArray = [ListModel]()
    fileprivate var pointToParent = CGPoint(x: 0, y: 0)

    var optionArray = [ListModel]() {
        didSet{
            self.dataArray = self.optionArray
        }
    }
    
   private var searchText = String() {
        didSet{
            if searchText.trimmingCharacters(in: .whitespaces) == "" {
                self.dataArray = self.optionArray
            }else{
                self.dataArray = optionArray.filter {
                    return ($0.listName ?? "").range(of: searchText.trimmingCharacters(in: .whitespaces), options: .caseInsensitive) != nil
                }
            }
            if !self.isSelected {
                self.showList()
            } else {
                self.reSizeTable()
                self.table.reloadData()
            }
            self.selectedIndex = nil
            UIView.animate(withDuration: 0.9,
                           delay: 0,
                           usingSpringWithDamping: 0.4,
                           initialSpringVelocity: 0.1,
                           options: .curveEaseInOut,
                           animations: { () -> Void in
                if self.dataArray.count == 0 {
                    self.arrow.position = .down
                } else {
                    self.arrow.position = .up
                }
            }, completion: { (finish) -> Void in
                self.layoutIfNeeded()
            })
        }
    }
    
    @IBInspectable public var arrowSize: CGFloat = 15 {
        didSet{
            let center =  arrow.superview!.center
            arrow.frame = CGRect(x: center.x - arrowSize/2, y: center.y - arrowSize/2, width: arrowSize, height: arrowSize)
        }
    }
    @IBInspectable public var arrowColor: UIColor = .black {
        didSet{
            arrow.arrowColor = arrowColor
        }
    }
    @IBInspectable public var checkMarkEnabled: Bool = true {
        didSet{
            
        }
    }

    // Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.delegate = self
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupUI()
        self.delegate = self
    }
    
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRectMake(bounds.origin.x + paddingLeft, bounds.origin.y,
            bounds.size.width - paddingLeft - paddingRight, bounds.size.height);
    }

    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }


    //MARK: Closures
//    let didSelectCompletion: (ListModel) -> () = {_ in }
    var didSelectCompletion: ((ListModel?) -> Void)?

    func setupUI () {
        let size = self.frame.height
        let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
        self.rightView = rightView
        self.rightViewMode = .always
        let arrowContainerView = UIView(frame: rightView.frame)
        self.rightView?.addSubview(arrowContainerView)
        let center = arrowContainerView.center
        arrow = Arrow(origin: CGPoint(x: center.x - arrowSize/2,y: center.y - arrowSize/2),size: arrowSize  )
        arrowContainerView.addSubview(arrow)
        addGesture()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    fileprivate func addGesture (){
        let gesture =  UITapGestureRecognizer(target: self, action:  #selector(touchActionGesture))
        if isSearchEnable{
            self.rightView?.addGestureRecognizer(gesture)
        }else{
            self.addGestureRecognizer(gesture)
        }
    }
    
    func getConvertedPoint(_ targetView: UIView, baseView: UIView?)->CGPoint{
        var pnt = targetView.frame.origin
        if nil == targetView.superview{
            return pnt
        }
        var superView = targetView.superview
        while superView != baseView{
            pnt = superView!.convert(pnt, to: superView!.superview)
            if nil == superView!.superview{
                break
            }else{
                superView = superView!.superview
            }
        }
        return superView!.convert(pnt, to: baseView)
    }
    
    func showList() {
        

        if listHeight > rowHeight * CGFloat( dataArray.count) {
            self.tableHeightX = rowHeight * CGFloat(dataArray.count)
        }else{
            self.tableHeightX = listHeight
        }
        
        self.pointToParent = self.getConvertedPoint(self, baseView: self.superview?.superview?.superview)
        
        table = UITableView(frame: CGRect(x: self.pointToParent.x,
                                          y: self.pointToParent.y,
                                          width: self.frame.width,
                                          height: self.frame.height))
        shadow = UIView(frame: table.frame)
        shadow.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.alpha = 0
        table.separatorStyle = .singleLine
        table.separatorColor = .lightGrayBackground
        table.layer.cornerRadius = 3
        table.backgroundColor = .whiteBackground
        table.rowHeight = rowHeight
        self.isSelected = true
        
        self.superview?.superview?.superview?.addSubview(shadow)
        self.superview?.superview?.superview?.addSubview(table)
        
        self.pointToParent = self.getConvertedPoint(self, baseView: self.superview?.superview?.superview)

        UIView.animate(withDuration: 0.9,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: { () -> Void in
            self.table.frame = CGRect(x: self.pointToParent.x, y: self.pointToParent.y + self.frame.height + 5, width: self.frame.width, height: self.tableHeightX)
            self.table.alpha = 1
            self.shadow.frame = self.table.frame
            self.shadow.dropShadow()
            self.arrow.position = .up
            self.table.reloadData()
        }, completion: { (finish) -> Void in
            self.layoutIfNeeded()
        })

    }

    public func hideList() {
        self.shadow.frame = self.table.frame
        self.table.alpha = 0
        self.shadow.alpha = 0
        self.table.removeFromSuperview()
        self.shadow.removeFromSuperview()
        self.isSelected = false

        if let didSelectCompletion = self.didSelectCompletion {
            if let selectedIndex = self.selectedIndex, self.dataArray.indices.contains(selectedIndex) {
                didSelectCompletion(self.dataArray[selectedIndex])
            } else {
                didSelectCompletion(nil)
            }
        }
        
        self.resignFirstResponder()
        
        UIView.animate(withDuration: 0.9,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: { () -> Void in
            self.arrow.position = .down
        }, completion: { (finish) -> Void in
            self.layoutIfNeeded()
        })
    }

    @objc func touchActionGesture() {
        if isSelected {
            self.text = ""
            self.selectedIndex = nil
            self.hideList()
        } else {
            if !self.isSearchEnable {
                self.showList()
            }
            self.becomeFirstResponder()
        }
    }
    
    func reSizeTable() {
        if listHeight > rowHeight * CGFloat( dataArray.count) {
            self.tableHeightX = rowHeight * CGFloat(dataArray.count)
        }else{
            self.tableHeightX = listHeight
        }
        self.pointToParent = self.getConvertedPoint(self, baseView: self.superview?.superview?.superview)
        UIView.animate(withDuration: 0.2,
                       delay: 0.1,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: { () -> Void in
            self.table.frame = CGRect(x: self.pointToParent.x, y: self.pointToParent.y + self.frame.height + 5, width: self.frame.width, height: self.tableHeightX)
                        self.shadow.frame = self.table.frame
                        self.shadow.dropShadow()

        }, completion: { (didFinish) -> Void in
            self.layoutIfNeeded()
        })
    }
    
    func enableArrow() {
        self.rightViewMode = .always
    }
    
    func disableArrow() {
        self.rightViewMode = .never
    }

}

//MARK: UITextFieldDelegate
extension DropDown : UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return isSearchEnable
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.isEditing {
            if !self.isSelected {
                self.dataArray = self.optionArray
                self.showList()
            } else {
                self.dataArray = []
            }
        }
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return isSearchEnable
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if self.selectedIndex == nil && self.isSearchEnable {
            self.text = ""
        }
        if self.isSelected {
            self.hideList()
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string != "" {
            self.searchText = self.text! + string
        }else{
            let subText = self.text?.dropLast()
            self.searchText = String(subText!)
        }
        return true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        superview?.endEditing(true)
        self.text = ""
        self.selectedIndex = nil
        if self.isSelected {
            self.hideList()
        }
        return true
    }
}
///MARK: UITableViewDataSource
extension DropDown: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "DropDownCell"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        let data = self.dataArray[indexPath.row]

        if let image = data.listImage {
            cell!.imageView!.image = image
        }
        cell!.textLabel!.text = "\(data.listName ?? "")"
        cell!.accessoryType = (indexPath.row == selectedIndex) && checkMarkEnabled  ? .checkmark : .none
        cell!.selectionStyle = .none
        cell?.textLabel?.font = self.font
        cell?.textLabel?.textAlignment = self.textAlignment
        cell?.textLabel?.textColor = self.textColor
        return cell!
    }
}
//MARK: UITableViewDelegate
extension DropDown: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.dataArray.indices.contains(indexPath.row) {
            self.selectedIndex = indexPath.row
            self.text = self.dataArray[indexPath.row].listName ?? ""
            if hideOptionsWhenSelect {
                if self.isSelected {
                    self.hideList()
                }
            }
        }
    }
}


//MARK: Arrow
enum Position {
    case left
    case down
    case right
    case up
}

class Arrow: UIView {
    let shapeLayer = CAShapeLayer()
    var arrowColor:UIColor = .black {
        didSet{
            shapeLayer.fillColor = arrowColor.cgColor
        }
    }
    
    var position: Position = .down {
        didSet{
            switch position {
            case .left:
                self.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
                break

            case .down:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi*2)
                break

            case .right:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
                break

            case .up:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                break
            }
        }
    }

    init(origin: CGPoint, size: CGFloat ) {
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: size, height: size))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {

        // Get size
        let size = self.layer.frame.width

        // Create path
        let bezierPath = UIBezierPath()

        // Draw points
        let qSize = size/4

        bezierPath.move(to: CGPoint(x: 0, y: qSize))
        bezierPath.addLine(to: CGPoint(x: size, y: qSize))
        bezierPath.addLine(to: CGPoint(x: size/2, y: qSize*3))
        bezierPath.addLine(to: CGPoint(x: 0, y: qSize))
        bezierPath.close()

        // Mask to path
        shapeLayer.path = bezierPath.cgPath
       
        if #available(iOS 12.0, *) {
            self.layer.addSublayer (shapeLayer)
        } else {
            self.layer.mask = shapeLayer
        }
    }
}

extension UIView {
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 3
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

struct ListModel {
    let listId: Int?
    let listImage: UIImage?
    let listName: String?
}
