import Testing
import Foundation
@testable import IconKit

@Suite("IconDocument")
struct IconDocumentTests {

    @Test("Decode minimal document")
    func decodeMinimal() throws {
        let json = Data(#"{"groups":[]}"#.utf8)
        let doc = try JSONDecoder().decode(IconDocument.self, from: json)
        #expect(doc.groups.isEmpty)
        #expect(doc.fill == nil)
        #expect(doc.colorSpaceForUntaggedSVGColors == nil)
        #expect(doc.supportedPlatforms == nil)
    }

    @Test("Decode full document")
    func decodeFull() throws {
        let json = Data("""
        {
            "color-space-for-untagged-svg-colors": "display-p3",
            "fill": "automatic",
            "fill-specializations": [
                {
                    "appearance": "dark",
                    "value": "system-dark"
                }
            ],
            "groups": [
                {
                    "id": "group-1",
                    "name": "Background",
                    "layers": [
                        {
                            "id": "layer-1",
                            "name": "BG Image",
                            "image-name": "Background.svg",
                            "opacity": 1.0
                        }
                    ],
                    "shadow": {
                        "kind": "neutral",
                        "opacity": 0.5
                    },
                    "lighting": "combined"
                }
            ],
            "supported-platforms": {
                "circles": true,
                "squares": "shared"
            }
        }
        """.utf8)

        let doc = try JSONDecoder().decode(IconDocument.self, from: json)
        #expect(doc.colorSpaceForUntaggedSVGColors == "display-p3")
        #expect(doc.fill == .automatic)
        #expect(doc.fillSpecializations?.count == 1)
        #expect(doc.fillSpecializations?.first?.appearance == .dark)
        #expect(doc.fillSpecializations?.first?.value == .systemDark)
        #expect(doc.groups.count == 1)

        let group = doc.groups[0]
        #expect(group.id == "group-1")
        #expect(group.name == "Background")
        #expect(group.layers.count == 1)
        #expect(group.shadow == IconShadow(kind: .neutral, opacity: 0.5))
        #expect(group.lighting == .combined)

        let layer = group.layers[0]
        #expect(layer.id == "layer-1")
        #expect(layer.name == "BG Image")
        #expect(layer.imageName == "Background.svg")
        #expect(layer.opacity == 1.0)
    }

    @Test("Document round-trip preserves all fields")
    func roundTrip() throws {
        let doc = IconDocument(
            colorSpaceForUntaggedSVGColors: "display-p3",
            fill: .solid(IconColor(colorSpace: .sRGB, components: [1.0, 1.0, 1.0, 1.0])),
            fillSpecializations: [
                Specialization(appearance: .dark, value: .systemDark),
                Specialization(idiom: .macOS, value: .automatic),
            ],
            groups: [
                IconGroup(
                    id: "grp-1",
                    name: "Main",
                    layers: [
                        IconLayer(
                            id: "lyr-1",
                            imageName: "Icon.svg",
                            fill: .automaticGradient(IconColor(colorSpace: .displayP3, components: [0.5, 0.0, 1.0, 1.0])),
                            blendMode: .multiply,
                            opacity: 0.8,
                            glass: true,
                            position: IconPosition(scale: 0.57, translationInPoints: [0.0, 10.0]),
                            imageNameSpecializations: [
                                Specialization(appearance: .dark, value: "Icon-Dark.svg"),
                            ]
                        ),
                    ],
                    shadow: .neutral,
                    translucency: IconTranslucency(enabled: true, value: 0.3),
                    blurMaterial: 0.5,
                    opacity: 1.0,
                    lighting: .individual,
                    specular: true,
                    blendMode: .overlay
                ),
            ],
            supportedPlatforms: SupportedPlatforms(circles: true, squares: .shared)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(doc)
        let decoded = try JSONDecoder().decode(IconDocument.self, from: data)
        #expect(decoded == doc)
    }

    @Test("Absent optional fields stay absent after round-trip")
    func absentFieldsStayAbsent() throws {
        let doc = IconDocument(groups: [
            IconGroup(id: "g1", layers: [
                IconLayer(id: "l1"),
            ]),
        ])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(doc)
        let jsonString = String(data: data, encoding: .utf8)!

        // These keys should NOT appear in the output
        #expect(!jsonString.contains("color-space-for-untagged-svg-colors"))
        #expect(!jsonString.contains("fill-specializations"))
        #expect(!jsonString.contains("supported-platforms"))
        #expect(!jsonString.contains("image-name-specializations"))
        #expect(!jsonString.contains("shadow"))
        #expect(!jsonString.contains("translucency"))
    }

    @Test("Decode document with layer specializations")
    func decodeLayerSpecializations() throws {
        let json = Data("""
        {
            "groups": [{
                "id": "g1",
                "layers": [{
                    "id": "l1",
                    "image-name": "Icon.svg",
                    "image-name-specializations": [
                        {"appearance": "dark", "value": "Icon-Dark.svg"},
                        {"idiom": "watchOS", "value": "Icon-Watch.svg"}
                    ],
                    "opacity-specializations": [
                        {"appearance": "tinted", "value": 0.5}
                    ],
                    "glass-specializations": [
                        {"idiom": "visionOS", "value": true}
                    ]
                }]
            }]
        }
        """.utf8)

        let doc = try JSONDecoder().decode(IconDocument.self, from: json)
        let layer = doc.groups[0].layers[0]

        #expect(layer.imageNameSpecializations?.count == 2)
        #expect(layer.imageNameSpecializations?[0].appearance == .dark)
        #expect(layer.imageNameSpecializations?[0].value == "Icon-Dark.svg")
        #expect(layer.imageNameSpecializations?[1].idiom == .watchOS)

        #expect(layer.opacitySpecializations?.count == 1)
        #expect(layer.opacitySpecializations?[0].value == 0.5)

        #expect(layer.glassSpecializations?.count == 1)
        #expect(layer.glassSpecializations?[0].idiom == .visionOS)
        #expect(layer.glassSpecializations?[0].value == true)
    }

    @Test("Decode document with group specializations")
    func decodeGroupSpecializations() throws {
        let json = Data("""
        {
            "groups": [{
                "id": "g1",
                "layers": [],
                "shadow": {"kind": "neutral", "opacity": 1.0},
                "shadow-specializations": [
                    {"appearance": "dark", "value": {"kind": "layerColor", "opacity": 0.5}}
                ],
                "blend-mode": "normal",
                "blend-mode-specializations": [
                    {"idiom": "macOS", "value": "multiply"}
                ],
                "specular-specializations": [
                    {"appearance": "tinted", "value": false}
                ]
            }]
        }
        """.utf8)

        let doc = try JSONDecoder().decode(IconDocument.self, from: json)
        let group = doc.groups[0]

        #expect(group.shadow == IconShadow(kind: .neutral, opacity: 1.0))
        #expect(group.shadowSpecializations?.count == 1)
        #expect(group.shadowSpecializations?[0].value == IconShadow(kind: .layerColor, opacity: 0.5))

        #expect(group.blendMode == .normal)
        #expect(group.blendModeSpecializations?.count == 1)
        #expect(group.blendModeSpecializations?[0].value == .multiply)

        #expect(group.specularSpecializations?.count == 1)
        #expect(group.specularSpecializations?[0].value == false)
    }

    @Test("Decode document with fill variants")
    func decodeFillVariants() throws {
        let json = Data("""
        {
            "fill": {"solid": "srgb:1.0,0.0,0.0,1.0"},
            "fill-specializations": [
                {"appearance": "dark", "value": {"solid": "srgb:0.0,0.0,0.0,1.0"}},
                {"appearance": "tinted", "value": "automatic"}
            ],
            "groups": []
        }
        """.utf8)

        let doc = try JSONDecoder().decode(IconDocument.self, from: json)
        #expect(doc.fill == .solid(IconColor(colorSpace: .sRGB, components: [1.0, 0.0, 0.0, 1.0])))
        #expect(doc.fillSpecializations?.count == 2)
        #expect(doc.fillSpecializations?[1].value == .automatic)
    }
}
