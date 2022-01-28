//
//  Detail3DMenuView.swift
//  fommos
//
//  Created by Eamon Liang on 2022/1/24.
//  Copyright © 2022 fommos. All rights reserved.
//

import Foundation
import UIKit


class Detail3DMenuView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 0, y: 0, width: 64, height: 32)
        titleLabel.center = CGPoint(x: 32, y: frame.height - 100)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var titleLabel: UILabel = {
        
        var titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.text = "得物"
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.87)
        return titleLabel
    }()
}
