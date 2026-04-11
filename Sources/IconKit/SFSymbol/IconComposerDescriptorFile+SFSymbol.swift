import Foundation

extension IconComposerDescriptorFile {

    /// Create a new icon bundle from an SF Symbol.
    ///
    /// The symbol is rendered as a transparent PNG and placed as a single
    /// layer in the icon document. The background color is set as the
    /// document-level fill, so it can be changed later in Icon Composer
    /// without regenerating the symbol asset.
    ///
    /// - Parameters:
    ///   - style: SF Symbol rendering configuration.
    ///   - background: Background color for the icon document fill.
    ///   - canvasSize: Icon canvas size in pixels. Default: 1024.
    /// - Returns: A complete icon descriptor ready to write to disk.
    public static func sfSymbol(
        style: SFSymbolStyle,
        background: IconColor,
        canvasSize: Int = defaultCanvasSize
    ) throws -> IconComposerDescriptorFile {
        let renderer = SFSymbolRenderer(style: style)
        let symbolData = try renderer.render(canvasSize: canvasSize)

        let assetName = "Symbol.png"
        let layer = IconLayer(imageName: assetName)
        let group = IconGroup(layers: [layer])
        let document = IconDocument(
            fill: .solid(background),
            groups: [group]
        )

        var descriptor = IconComposerDescriptorFile(document: document)
        descriptor.assets[assetName] = symbolData
        return descriptor
    }
}
