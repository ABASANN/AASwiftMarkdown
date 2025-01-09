//
//  SwiftyMarkdownTable.swift
//  SwiftyMarkdown
//
//  Created by 赵希帆 on 2024/2/29.
//

import UIKit

public class MarkdownTableConfiguration: NSObject {
    
    /// 表格元素的大小
    public var dataSize: [[CGSize]] = []
    
    /// 表格的size
    public var tableSize: CGSize = .zero
    public var tableStyle: TableStyles = .init()
    
    public var tableData: [[String]] = []
    
    private var maxWidth: CGFloat = 180.0
    private let leftMinMargin: CGFloat = 10
    private let rightMinMargin: CGFloat = 10
    private let topMinMargin: CGFloat = 10
    private let bottomMinMargin: CGFloat = 10
    
    public override init() {
        super.init()
    }
    
    convenience init(_ tableData: [[String]], table style: TableStyles) {
        self.init()
        self.tableData = tableData
        tableStyle = style
        calculateDataSize()
        calculateItemSize()
    }
    
    private func calculateDataSize() {
        dataSize = []
        for rows in tableData {
            var rowSize: [CGSize] = []
            for item in rows {
                let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 22)
                let maxHeightSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
                let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: configFont]
                let maxWidthSize = (item as NSString).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
                if maxWidthSize.width > maxWidth {
                    let maxHeightSize = (item as NSString).boundingRect(with: maxHeightSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
                    let size: CGSize = .init(width: ceil(maxWidth + leftMinMargin + rightMinMargin), height: ceil(maxHeightSize.height + (maxHeightSize.height/18.0*5) + topMinMargin + bottomMinMargin))
                    rowSize.append(size)
                } else {
                    let size: CGSize = .init(width: ceil(maxWidthSize.width + leftMinMargin + rightMinMargin), height: ceil(22 + topMinMargin + bottomMinMargin))
                    rowSize.append(size)
                }
            }
            dataSize.append(rowSize)
        }
    }
    
    private func calculateItemSize() {
        var heightArr: [CGFloat] = []
        var widthArr: [CGFloat] = []
        let row = dataSize.count
        let colum = dataSize.first?.count ?? 0
        for rows in dataSize {
            var height = 0.0
            for item in rows {
                if item.height > height {
                    height = item.height
                }
            }
            heightArr.append(height)
        }
        for i in 0..<Int(colum) {
            var width = 0.0
            for j in 0..<Int(row) {
                var item = dataSize[j][i]
                if item.width > width {
                    width = item.width
                }
            }
            widthArr.append(width)
        }
        for i in 0..<row {
            for j in 0..<Int(colum) {
                dataSize[i][j] = CGSize(width: widthArr[j], height: heightArr[i])
            }
        }
        tableSize = CGSize(width: widthArr.reduce(0, {$0+$1}), height: heightArr.reduce(0, {$0+$1}))
    }
  
    private var configFont: UIFont {
        get {
            let name = tableStyle.fontName ?? ""
            return UIFont(name: name, size: tableStyle.fontSize)
              ?? UIFont.systemFont(ofSize: 16.0)
        }
    }
}

public class MarkdownTableCell: UICollectionViewCell {
    
    private lazy var textLabel: UILabel = {
        let label: UILabel = .init()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.frame = self.bounds
        label.textAlignment = .center
        return label
    }()
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.textLabel)
        self.contentView.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        self.contentView.layer.borderWidth = 1
    }
  
    @discardableResult
    public func set(_ style: TableStyles) -> Self {
        textLabel.textColor = style.color
        if let fontName = style.fontName {
          textLabel.font = .init(name: fontName, size: style.fontSize)
        } else {
          textLabel.font = .systemFont(ofSize: 16)
        }
        
        contentView.layer.borderColor = style.borderColor.cgColor
        contentView.layer.borderWidth = style.borderWidth
        return self
    }
    
    public func updateCell(_ text: String) {
        textLabel.text = text
    }
}

public class MarkdownTable: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var configuration: MarkdownTableConfiguration = .init()
    
    lazy var collectionLayout: UICollectionViewLayout = {
        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.minimumLineSpacing = 0
        collectionLayout.minimumInteritemSpacing = 0
        collectionLayout.scrollDirection = .vertical
        collectionLayout.sectionInset = .zero
        return collectionLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: CGRect.init(x: 0, y: 0, width: self.configuration.tableSize.width, height: self.bounds.height), collectionViewLayout: self.collectionLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.bounces = false
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MarkdownTableCell.self, forCellWithReuseIdentifier: "MarkdownTableCell")
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = configuration.tableStyle.backgroundColor
        self.scrollView.addSubview(collectionView)
        return collectionView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scroll:UIScrollView = .init(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentSize = CGSize.init(width: self.configuration.tableSize.width, height: self.configuration.tableSize.height)
        self.addSubview(scroll)
        return scroll
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(_ frame: CGRect,_ configuration: MarkdownTableConfiguration) {
        self.init(frame: frame)
        self.configuration = configuration
        buildSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildSubviews() {
        collectionView.layoutIfNeeded()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.configuration.tableData.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.configuration.tableData[section].count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: MarkdownTableCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MarkdownTableCell", for: indexPath) as? MarkdownTableCell else { return UICollectionViewCell() }
      
        cell.set(configuration.tableStyle)
          .updateCell(self.configuration.tableData[indexPath.section][indexPath.row])
      
        let backgroundColor = configuration.tableStyle.backgroundColor
        if indexPath.section == 0 {
          cell.contentView.backgroundColor = backgroundColor.withAlphaComponent(0.1)
        } else {
          cell.contentView.backgroundColor = backgroundColor
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let row = indexPath.section
        let colum = indexPath.row
        return self.configuration.dataSize[row][colum]
    }
}
