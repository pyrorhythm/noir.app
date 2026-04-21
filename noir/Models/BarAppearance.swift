import Foundation

struct BarAppearance: Codable, Sendable, Equatable {
    var height: Double = 28
    var opacity: Double = 1
    var cornerRadius: Double = 6

    static let `default` = BarAppearance()
}

struct BarAppearanceControl: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let range: ClosedRange<Double>
    let step: Double
    let value: WritableKeyPath<BarAppearance, Double>
    let format: FloatingPointFormatStyle<Double>

    init(
        id: String,
        title: String,
        systemImage: String,
        range: ClosedRange<Double>,
        step: Double,
        value: WritableKeyPath<BarAppearance, Double>,
        format: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(0))
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.range = range
        self.step = step
        self.value = value
        self.format = format
    }
}

extension BarAppearance {
    static let controls: [BarAppearanceControl] = [
        BarAppearanceControl(
            id: "height",
            title: "Height",
            systemImage: "rectangle.compress.vertical",
            range: 24...36,
            step: 2,
            value: \.height
        ),
        BarAppearanceControl(
            id: "opacity",
            title: "Opacity",
            systemImage: "circle.lefthalf.filled",
            range: 0.5...1,
            step: 0.05,
            value: \.opacity,
            format: .number.precision(.fractionLength(2))
        ),
        BarAppearanceControl(
            id: "cornerRadius",
            title: "Corner Radius",
            systemImage: "rectangle.roundedtop",
            range: 0...32,
            step: 0.5,
            value: \.cornerRadius,
            format: .number.precision(.fractionLength(1))
        ),
    ]
}
