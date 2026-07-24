//
//  MeasurementSize+FormatStyle.swift
//  Simple ID Photo
//
//  Created by TakashiUshikoshi on 2025/06/09
//

import Foundation

extension MeasurementSize {
    struct FormatStyle: Foundation.FormatStyle, Sendable, Equatable {

        enum LabelStyle: Sendable, Equatable {
            case full
            case abbreviated
        }

        enum DimensionStyle: Sendable, Equatable {
            case labeled(_ labelStyle: LabelStyle = .full)
            case unitOnly
            case valueOnly
        }

        enum Separator: String, Sendable, Equatable {
            case multiplicationSign = "×"
            case letterX = "x"
        }

        var widthStyle: DimensionStyle
        var heightStyle: DimensionStyle
        var separator: Separator
        var locale: Locale

        init(
            width: DimensionStyle = .labeled(),
            height: DimensionStyle = .labeled(),
            separator: Separator = .multiplicationSign,
            locale: Locale = .autoupdatingCurrent
        ) {
            self.widthStyle = width
            self.heightStyle = height
            self.separator = separator
            self.locale = locale
        }

        func width(_ style: DimensionStyle) -> Self {
            var copy = self; copy.widthStyle = style; return copy
        }

        func height(_ style: DimensionStyle) -> Self {
            var copy = self; copy.heightStyle = style; return copy
        }

        func separator(_ separator: Separator) -> Self {
            var copy = self; copy.separator = separator; return copy
        }

        func locale(_ locale: Locale) -> Self {
            var copy = self; copy.locale = locale; return copy
        }

        func format(_ value: MeasurementSize) -> String {
            let w = formatDimension(value.width, style: widthStyle, isWidth: true)
            let h = formatDimension(value.height, style: heightStyle, isWidth: false)
            return "\(w) \(separator.rawValue) \(h)"
        }

        // MARK: - Private

        private func formatDimension(
            _ measurement: Measurement<UnitLength>,
            style: DimensionStyle,
            isWidth: Bool
        ) -> String {
            let mmValue = measurement.converted(to: .millimeters).value
            let valueStr = mmValue.formatted(.number.precision(.fractionLength(0...)).locale(locale))

            switch style {
            case .valueOnly:
                return valueStr
            case .unitOnly:
                return "\(valueStr) mm"
            case .labeled(let labelStyle):
                return "\(directionLabel(isWidth: isWidth, labelStyle: labelStyle)) \(valueStr) mm"
            }
        }

        private func directionLabel(isWidth: Bool, labelStyle: LabelStyle) -> String {
            let key: String
            switch (isWidth, labelStyle) {
            case (true,  .full):        key = "MeasurementSize.FormatStyle.widthLabel.full"
            case (true,  .abbreviated): key = "MeasurementSize.FormatStyle.widthLabel.abbreviated"
            case (false, .full):        key = "MeasurementSize.FormatStyle.heightLabel.full"
            case (false, .abbreviated): key = "MeasurementSize.FormatStyle.heightLabel.abbreviated"
            }
            let langCode = locale.language.languageCode?.identifier ?? ""
            let bundle = Bundle.main
            if let path = bundle.path(forResource: langCode, ofType: "lproj"),
               let locBundle = Bundle(path: path) {
                return locBundle.localizedString(forKey: key, value: key, table: "Localizable")
            }
            return bundle.localizedString(forKey: key, value: key, table: "Localizable")
        }
    }
}

extension FormatStyle where Self == MeasurementSize.FormatStyle {
    static var measurementSize: MeasurementSize.FormatStyle { .init() }
}

extension MeasurementSize {
    func formatted(_ style: MeasurementSize.FormatStyle = .init()) -> String {
        style.format(self)
    }
}
