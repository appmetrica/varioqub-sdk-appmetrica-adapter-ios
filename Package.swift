// swift-tools-version:5.8

import PackageDescription
import Foundation

// MARK: - Dependencies

func hasFile(_ path: String) -> Bool {
    FileManager.default.fileExists(
        atPath: URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent(path)
            .path
    )
}

// DO NOT CHANGE DEFAULT VALUES IN TRUNK
let useRegistry = hasFile(".spm-use-registry") || false
let useAppMetricaLocal = hasFile(".spm-use-appmetrica-local") || false
let useVarioqubLocal = hasFile(".spm-use-varioqub-local") || false

let varioqubCurrentVersion: Version = "1.3.0"

struct ExternalDependency {
    let package: String
    let dependency: Package.Dependency

    init(url: String, registryId: String, version: VersionSpec, localPath: String? = nil) {
        if localPath != nil {
            self.package = registryId
            self.dependency = .package(name: self.package, path: localPath!)
        } else if useRegistry {
            self.package = registryId
            self.dependency = switch version {
            case .upToNextMajor(from: let from): .package(id: self.package, .upToNextMajor(from: from))
            case .exact(let v): .package(id: self.package, exact: v)
            }
        } else {
            self.package = URL(string: url)!.lastPathComponent
            self.dependency = switch version {
            case .upToNextMajor(from: let from): .package(url: url, .upToNextMajor(from: from))
            case .exact(let v): .package(url: url, exact: v)
            }
        }
    }

    enum VersionSpec {
        case upToNextMajor(from: Version)
        case exact(Version)
    }
}

enum AppMetrica {
    private static let dep = ExternalDependency(
        url: "https://github.com/appmetrica/appmetrica-sdk-ios",
        registryId: "spm-external.AppMetrica",
        version: .upToNextMajor(from: "6.0.0"),
        localPath: useAppMetricaLocal ? "../../appmetrica-sdk/public" : nil,
    )

    static let dependency: Package.Dependency = dep.dependency
    static let core: Target.Dependency = .product(name: "AppMetricaCore", package: dep.package)
}

enum SwiftLog {
    private static let dep = ExternalDependency(
        url: "https://github.com/apple/swift-log",
        registryId: "spm-external.swift-log",
        version: .upToNextMajor(from: "1.5.2"),
    )

    static let dependency: Package.Dependency = dep.dependency
    static let logging: Target.Dependency = .product(name: "Logging", package: dep.package)
}

enum Protobuf {
    private static let dep = ExternalDependency(
        url: "https://github.com/apple/swift-protobuf",
        registryId: "spm-external.SwiftProtobuf",
        version: .upToNextMajor(from: "1.21.0"),
    )

    static let dependency: Package.Dependency = dep.dependency
    static let protobuf: Target.Dependency = .product(name: "SwiftProtobuf", package: dep.package)
}

enum Varioqub {
    private static let dep = ExternalDependency(
        url: "https://github.com/appmetrica/varioqub-sdk-ios",
        registryId: "spm-external.Varioqub",
        version: .exact(varioqubCurrentVersion),
        localPath: useVarioqubLocal ? "../varioqub" : nil,
    )

    static let dependency: Package.Dependency = dep.dependency
    static let varioqub: Target.Dependency = .product(name: "Varioqub", package: dep.package)
    static let varioqubObjC: Target.Dependency = .product(name: "VarioqubObjC", package: dep.package)
}

// MARK: - Module

protocol ModuleDependency {
    var asTargetDependency: Target.Dependency { get }
}

extension String : ModuleDependency {
    var asTargetDependency: Target.Dependency { .target(name: self) }
}

extension Target.Dependency : ModuleDependency {
    var asTargetDependency: Target.Dependency { self }
}

struct Module {
    let name: String
    let dependencies: [Target.Dependency]

    init(name: String, dependencies: [ModuleDependency]) {
        self.name = name
        self.dependencies = dependencies.map(\.asTargetDependency)
    }

    func toTargets() -> [Target] {
        return [
            .target(
                name: name,
                dependencies: dependencies,
                resources: [.copy("Resources/PrivacyInfo.xcprivacy")],
                swiftSettings: [.define("VQ_MODULES")],
            )
        ]
    }
}

extension Module {
    static let adapter = "VarioqubAppMetricaAdapter"
    static let objc = "VarioqubAppMetricaAdapterObjC"
}

// MARK: - Adapter Module

let adapter = Module(
    name: Module.adapter,
    dependencies: [
        SwiftLog.logging,
        Protobuf.protobuf,
        Varioqub.varioqub,
        AppMetrica.core,
    ],
)

// MARK: - ObjC Module

let objc = Module(
    name: Module.objc,
    dependencies: [
        Module.adapter,
        Varioqub.varioqubObjC,
    ],
)

// MARK: - Package definition

let package = Package(
    name: "VarioqubAppMetricaAdapter",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "VarioqubAppMetricaAdapter", targets: [Module.adapter]),
        .library(name: "VarioqubAppMetricaAdapterObjC", targets: [Module.adapter, Module.objc]),
    ],
    dependencies: [
        SwiftLog.dependency,
        Protobuf.dependency,
        Varioqub.dependency,
        AppMetrica.dependency,
    ],
    targets: [
        adapter,
        objc,
    ].flatMap { $0.toTargets() },
)
