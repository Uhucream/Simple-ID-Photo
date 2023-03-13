//
//  NormalPrinterPrintInteractionControllerDelegate.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/13
//  
//

import UIKit

final class NormalPrinterPrintInteractionControllerDelegate: NSObject, UIPrintInteractionControllerDelegate {
    
    var choosePaper: ((UIPrintInteractionController, [UIPrintPaper]) -> UIPrintPaper)
    
    var onWillPresentPrinterOptions: ((UIPrintInteractionController) -> Void)?
    var onDidPresentPrinterOptions: ((UIPrintInteractionController) -> Void)?
    
    var onWillDismissPrinterOptions: ((UIPrintInteractionController) -> Void)?
    var onDidDismissPrinterOptions: ((UIPrintInteractionController) -> Void)?
    
    var onWillStartJob: ((UIPrintInteractionController) -> Void)?
    var onDidFinishJob: ((UIPrintInteractionController) -> Void)?
    
    init(
        choosePaper: @escaping ((UIPrintInteractionController, [UIPrintPaper]) -> UIPrintPaper),
        onWillPresentPrinterOptions: ((UIPrintInteractionController) -> Void)? = nil,
        onDidPresentPrinterOptions: ((UIPrintInteractionController) -> Void)? = nil,
        onWillDismissPrinterOptions: ((UIPrintInteractionController) -> Void)? = nil,
        onDidDismissPrinterOptions: ((UIPrintInteractionController) -> Void)? = nil,
        onWillStartJob: ((UIPrintInteractionController) -> Void)? = nil,
        onDidFinishJob: ((UIPrintInteractionController) -> Void)? = nil
    ) {
        self.choosePaper = choosePaper
        self.onWillPresentPrinterOptions = onWillPresentPrinterOptions
        self.onDidPresentPrinterOptions = onDidPresentPrinterOptions
        self.onWillDismissPrinterOptions = onWillDismissPrinterOptions
        self.onDidDismissPrinterOptions = onDidDismissPrinterOptions
        self.onWillStartJob = onWillStartJob
        self.onDidFinishJob = onDidFinishJob
    }
    
    func printInteractionController(_ printInteractionController: UIPrintInteractionController, choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        return choosePaper(printInteractionController, paperList)
    }

    func printInteractionControllerWillPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        self.onWillPresentPrinterOptions?(printInteractionController)
    }

    func printInteractionControllerDidPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        self.onDidPresentPrinterOptions?(printInteractionController)
    }

    func printInteractionControllerWillDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        self.onWillDismissPrinterOptions?(printInteractionController)
    }

    func printInteractionControllerDidDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        self.onDidDismissPrinterOptions?(printInteractionController)
    }

    func printInteractionControllerWillStartJob(_ printInteractionController: UIPrintInteractionController) {
        self.onWillStartJob?(printInteractionController)
    }

    func printInteractionControllerDidFinishJob(_ printInteractionController: UIPrintInteractionController) {
        self.onDidFinishJob?(printInteractionController)
    }
}
