import Testing
import Foundation
@testable import IconKit

@Suite("Inspect Summary")
struct InspectTests {

    // MARK: - Minimal Document

    @Test("Empty document produces concise output")
    func emptyDocument() {
        let file = IconComposerDescriptorFile(document: IconDocument(groups: []))
        let output = file.inspectSummary(bundleName: "Empty.icon")

        #expect(output.contains("Empty.icon"))
        #expect(output.contains("Groups: (none)"))
        #expect(output.contains("Assets: 0 present, 0 missing"))
    }

    // MARK: - Document-Level Properties

    @Test("Shows document fill")
    func documentFill() {
        let doc = IconDocument(fill: .automatic, groups: [])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Fill: automatic"))
    }

    @Test("Shows color space for untagged SVGs")
    func colorSpace() {
        let doc = IconDocument(colorSpaceForUntaggedSVGColors: "display-p3", groups: [])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Color space for untagged SVGs: display-p3"))
    }

    @Test("Shows supported platforms")
    func platforms() {
        let doc = IconDocument(
            groups: [],
            supportedPlatforms: SupportedPlatforms(
                circles: ["watchOS"],
                squares: .platforms(["iOS", "macOS"])
            )
        )
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Platforms: circles [watchOS], squares [iOS, macOS]"))
    }

    @Test("Shows shared squares platform")
    func sharedSquares() {
        let doc = IconDocument(
            groups: [],
            supportedPlatforms: SupportedPlatforms(squares: .shared)
        )
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Platforms: squares shared"))
    }

    // MARK: - Fill Variants

    @Test("Formats all fill types")
    func fillTypes() {
        let color = IconColor(colorSpace: .sRGB, components: [1, 0, 0, 1])

        let fills: [(IconFill, String)] = [
            (.automatic, "automatic"),
            (.systemLight, "system-light"),
            (.systemDark, "system-dark"),
            (.solid(color), "solid srgb:1.00000,0.00000,0.00000,1.00000"),
            (.automaticGradient(color), "automatic-gradient srgb:1.00000,0.00000,0.00000,1.00000"),
        ]

        for (fill, expected) in fills {
            let doc = IconDocument(fill: fill, groups: [])
            let file = IconComposerDescriptorFile(document: doc)
            let output = file.inspectSummary(bundleName: "Test.icon")
            #expect(output.contains("Fill: \(expected)"))
        }
    }

    // MARK: - Named vs Unnamed

    @Test("Named group shows name in quotes")
    func namedGroup() {
        let doc = IconDocument(groups: [
            IconGroup(name: "Background", layers: []),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Group 1 \"Background\""))
    }

    @Test("Unnamed group shows number only")
    func unnamedGroup() {
        let doc = IconDocument(groups: [
            IconGroup(layers: []),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Group 1"))
        #expect(!output.contains("Group 1 \""))
    }

    @Test("Named layer shows name in quotes")
    func namedLayer() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(name: "Logo")]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Layer \"Logo\""))
    }

    @Test("Unnamed layer shows number")
    func unnamedLayer() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer()]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Layer 1"))
        #expect(!output.contains("Layer 1 \""))
    }

    // MARK: - Non-Default Filtering

    @Test("Suppresses hidden false")
    func suppressesHiddenFalse() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(hidden: false)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(!output.contains("Hidden"))
    }

    @Test("Shows hidden true")
    func showsHiddenTrue() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], hidden: true),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Hidden"))
    }

    @Test("Suppresses normal blend mode")
    func suppressesNormalBlendMode() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(blendMode: .normal)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(!output.contains("Blend mode"))
    }

    @Test("Shows non-normal blend mode")
    func showsNonNormalBlendMode() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(blendMode: .multiply)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Blend mode: multiply"))
    }

    @Test("Suppresses opacity 1.0")
    func suppressesFullOpacity() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(opacity: 1.0)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(!output.contains("Opacity"))
    }

    @Test("Shows reduced opacity")
    func showsReducedOpacity() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], opacity: 0.5),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Opacity: 0.5"))
    }

    @Test("Suppresses disabled translucency")
    func suppressesDisabledTranslucency() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], translucency: .disabled),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(!output.contains("Translucency"))
    }

    @Test("Shows enabled translucency")
    func showsEnabledTranslucency() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], translucency: .default),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Translucency: enabled (value: 0.5)"))
    }

    @Test("Suppresses identity position")
    func suppressesIdentityPosition() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(position: .identity)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(!output.contains("Position"))
    }

    @Test("Shows non-identity position")
    func showsNonIdentityPosition() {
        let pos = IconPosition(scale: 2.0, translationInPoints: [10, 20])
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(position: pos)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Position: scale 2.0, translate (10.0, 20.0)"))
    }

    // MARK: - Layer Properties

    @Test("Shows glass true")
    func showsGlass() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(glass: true)]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Glass: true"))
    }

    @Test("Shows image name")
    func showsImageName() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(imageName: "Logo.svg")]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Image: Logo.svg"))
    }

    // MARK: - Specialization Qualifiers

    @Test("Specialization qualifier formatting")
    func specializationQualifiers() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [
                IconLayer(fillSpecializations: [
                    Specialization(value: .automatic),
                    Specialization(appearance: .dark, value: .systemDark),
                    Specialization(idiom: .macOS, value: .systemLight),
                    Specialization(appearance: .tinted, idiom: .visionOS, value: .automatic),
                ]),
            ]),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("[default] automatic"))
        #expect(output.contains("[dark] system-dark"))
        #expect(output.contains("[macOS] system-light"))
        #expect(output.contains("[tinted, visionOS] automatic"))
    }

    // MARK: - Asset Validation

    @Test("Shows missing assets")
    func missingAssets() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [
                IconLayer(imageName: "Logo.svg"),
                IconLayer(imageName: "Background.png"),
            ]),
        ])
        var file = IconComposerDescriptorFile(document: doc)
        file.assets["Logo.svg"] = Data()
        // Background.png is missing

        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Assets: 1 present, 1 missing"))
        #expect(output.contains("Missing: Background.png"))
    }

    @Test("Shows all assets present")
    func allAssetsPresent() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(imageName: "Logo.svg")]),
        ])
        var file = IconComposerDescriptorFile(document: doc)
        file.assets["Logo.svg"] = Data()

        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Assets: 1 present, 0 missing"))
        #expect(!output.contains("Missing:"))
    }

    @Test("Shows unreferenced assets")
    func unreferencedAssets() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [IconLayer(imageName: "Logo.svg")]),
        ])
        var file = IconComposerDescriptorFile(document: doc)
        file.assets["Logo.svg"] = Data()
        file.assets["Orphan.png"] = Data()

        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("1 unreferenced"))
    }

    // MARK: - Group Properties

    @Test("Shows shadow with kind none")
    func shadowKindNone() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], shadow: IconShadow(kind: .none, opacity: 0.5)),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Shadow: none (opacity: 0.5)"))
    }

    @Test("Shows lighting mode")
    func lightingMode() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], lighting: .individual),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Lighting: individual"))
    }

    @Test("Shows blur material")
    func blurMaterial() {
        let doc = IconDocument(groups: [
            IconGroup(layers: [], blurMaterial: 0.3),
        ])
        let file = IconComposerDescriptorFile(document: doc)
        let output = file.inspectSummary(bundleName: "Test.icon")

        #expect(output.contains("Blur material: 0.3"))
    }

    // MARK: - Real-World Fixture

    @Test("Matches real NewAppIcon.icon output")
    func realWorldFixture() throws {
        let json = """
        {
          "fill" : {
            "automatic-gradient" : "srgb:0.69804,0.65098,0.60392,1.00000"
          },
          "groups" : [
            {
              "hidden" : false,
              "layers" : [
                {
                  "fill-specializations" : [
                    {
                      "value" : {
                        "solid" : "display-p3:0.05882,0.08235,0.09804,1.00000"
                      }
                    },
                    {
                      "appearance" : "dark",
                      "value" : {
                        "solid" : "display-p3:0.94902,0.93725,0.87843,1.00000"
                      }
                    }
                  ],
                  "glass" : true,
                  "image-name" : "Fitness Art.png",
                  "name" : "Fitness Art",
                  "position" : {
                    "scale" : 2,
                    "translation-in-points" : [0, 0]
                  }
                }
              ],
              "lighting" : "individual",
              "position-specializations" : [
                {
                  "value" : {
                    "scale" : 0.5,
                    "translation-in-points" : [0, 0]
                  }
                },
                {
                  "idiom" : "square",
                  "value" : {
                    "scale" : 0.5,
                    "translation-in-points" : [0, 0]
                  }
                }
              ],
              "shadow" : {
                "kind" : "none",
                "opacity" : 0.5
              },
              "specular" : false,
              "translucency" : {
                "enabled" : false,
                "value" : 0.5
              }
            }
          ],
          "supported-platforms" : {
            "circles" : ["watchOS"],
            "squares" : "shared"
          }
        }
        """

        let doc = try JSONDecoder().decode(IconDocument.self, from: Data(json.utf8))
        var file = IconComposerDescriptorFile(document: doc)
        file.assets["Fitness Art.png"] = Data()

        let output = file.inspectSummary(bundleName: "NewAppIcon.icon")

        #expect(output.contains("Fill: automatic-gradient srgb:0.69804,0.65098,0.60392,1.00000"))
        #expect(output.contains("Platforms: circles [watchOS], squares shared"))
        #expect(output.contains("Lighting: individual"))
        #expect(output.contains("Shadow: none (opacity: 0.5)"))
        #expect(output.contains("Specular: false"))
        #expect(output.contains("Layer \"Fitness Art\""))
        #expect(output.contains("Image: Fitness Art.png"))
        #expect(output.contains("Glass: true"))
        #expect(output.contains("Position: scale 2.0, translate (0.0, 0.0)"))
        #expect(output.contains("[default] solid display-p3:0.05882,0.08235,0.09804,1.00000"))
        #expect(output.contains("[dark] solid display-p3:0.94902,0.93725,0.87843,1.00000"))
        #expect(output.contains("[default] scale 0.5, translate (0.0, 0.0)"))
        #expect(output.contains("[square] scale 0.5, translate (0.0, 0.0)"))
        #expect(output.contains("Assets: 1 present, 0 missing"))
        // hidden: false should be suppressed
        #expect(!output.contains("Hidden"))
        // disabled translucency should be suppressed
        #expect(!output.contains("Translucency"))
    }
}
