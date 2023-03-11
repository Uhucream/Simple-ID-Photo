//
//  AppliedBackgroundColor+.swift
//  Simple ID Photo
//  
//  Created by TakashiUshikoshi on 2023/03/01
//  
//

import CoreData
import SwiftUI

extension AppliedBackgroundColor {
    convenience init(
        on context: NSManagedObjectContext,
        id: UUID = .init(),
        color: Color,
        createdIDPhoto: CreatedIDPhoto? = nil
    ) {
        self.init(context: context)
        
        self.id = id
        
        self.red = Double(color.rgba?.red ?? 0)
        self.green = Double(color.rgba?.green ?? 0)
        self.blue = Double(color.rgba?.blue ?? 0)
        self.alpha = Double(color.rgba?.alpha ?? 0)
        
        self.createdIDPhoto = createdIDPhoto
    }
}
