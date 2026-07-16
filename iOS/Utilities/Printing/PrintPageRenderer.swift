//
//  PrintPageRenderer.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/02/24
//  
//

import UIKit

class PrintPageRenderer: UIPrintPageRenderer {
    static let applePrintPixelDensity: Double = 72
    
    var onDrawPage: ((Int, CGRect) -> Void)?
    var onDrawHeaderForPage: ((Int, CGRect) -> Void)?
    var onDrawContentForPage: ((Int, CGRect) -> Void)?
    var onDrawPrintFormatter: ((UIPrintFormatter, Int) -> Void)?
    var onDrawFooterForPage: ((Int, CGRect) -> Void)?
    
    init(
        onDrawPage: ((Int, CGRect) -> Void)? = nil,
        onDrawHeaderForPage: ((Int, CGRect) -> Void)? = nil,
        onDrawContentForPage: ((Int, CGRect) -> Void)? = nil,
        onDrawPrintFormatter: ((UIPrintFormatter, Int) -> Void)? = nil,
        onDrawFooterForPage: ((Int, CGRect) -> Void)? = nil
    ) {
        self.onDrawPage = onDrawPage
        self.onDrawHeaderForPage = onDrawHeaderForPage
        self.onDrawContentForPage = onDrawContentForPage
        self.onDrawPrintFormatter = onDrawPrintFormatter
        self.onDrawFooterForPage = onDrawFooterForPage
    }
    
    
    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        self.onDrawPage?(pageIndex, printableRect)
    }

    override func drawPrintFormatter(_ printFormatter: UIPrintFormatter, forPageAt pageIndex: Int) {
        self.onDrawPrintFormatter?(printFormatter, pageIndex)
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        self.onDrawHeaderForPage?(pageIndex, headerRect)
    }

    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        self.onDrawContentForPage?(pageIndex, contentRect)
    }

    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
        self.onDrawFooterForPage?(pageIndex, footerRect)
    }
}
