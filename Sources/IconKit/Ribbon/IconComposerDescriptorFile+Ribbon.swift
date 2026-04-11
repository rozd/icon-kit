import Foundation

extension IconComposerDescriptorFile {

    /// The standard icon canvas size in pixels.
    public static let defaultCanvasSize = 1024

    /// Apply a ribbon overlay by adding a new front-most layer to the icon document.
    ///
    /// This creates a transparent PNG at the icon canvas size containing only
    /// the ribbon band and text, adds it to the bundle assets, and appends
    /// a new group with this layer as the front-most (top) element.
    ///
    /// The original assets and document structure are preserved — only a new
    /// group is appended.
    ///
    /// - Parameters:
    ///   - placement: Where to position the ribbon.
    ///   - style: Visual configuration for the ribbon.
    ///   - canvasSize: Icon canvas size in pixels. Default: 1024.
    public mutating func applyRibbon(
        placement: RibbonPlacement,
        style: RibbonStyle,
        canvasSize: Int = IconComposerDescriptorFile.defaultCanvasSize
    ) throws {
        let renderer = RibbonRenderer(placement: placement, style: style)
        let overlayData = try renderer.generateOverlay(width: canvasSize, height: canvasSize)

        let assetName = "_ribbon_overlay.png"
        assets[assetName] = overlayData

        // Disable all Liquid Glass effects so the ribbon renders opaque
        // with exact colors as specified
        let layer = IconLayer(imageName: assetName, glass: false)
        let group = IconGroup(
            layers: [layer],
            shadow: IconShadow(kind: .none, opacity: 0.0),
            translucency: IconTranslucency(enabled: false, value: 0.0),
            lighting: .individual,
            specular: false
        )

        // In .icon bundles, the first group in the array renders on top
        document.groups.insert(group, at: 0)
    }
}
