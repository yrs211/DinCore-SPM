// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DinCore",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DinCore",
            targets: ["DinCore"]
        ),
        
    ],
    dependencies: [
        .package(url: "https://github.com/yrs211/DinSupport-SPM.git", exact: "1.0.2"),
        .package(url: "https://github.com/yrs211/AlicloudHttpDNS-SPM.git", exact:"1.0.1"),
        .package(url: "https://github.com/yrs211/Objective-LevelDB.git", exact:"1.0.2"),
        .package(url: "https://github.com/yrs211/Snappy-ObjC.git", exact:"1.0.1"),
        .package(url: "https://github.com/Moya/Moya.git", exact:"15.0.0"),
        .package(url: "https://github.com/alibaba/HandyJSON.git", exact:"5.0.2"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", exact:"6.5.0"),
        .package(url: "https://github.com/qiniu/objc-sdk", exact:"8.8.1"),
        .package(url: "https://github.com/daltoniam/Starscream.git", exact:"3.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DinCore",
            dependencies: [
                         // 原有其他依赖（补充完整，避免缺失）
                         .product(name: "DinSupport", package: "DinSupport-SPM"),
                         .product(name: "AlicloudHttpDNS", package: "AlicloudHttpDNS-SPM"),
                         .product(name: "ObjectiveLevelDB", package: "Objective-LevelDB"),
                         .product(name: "SnappyObjC", package: "Snappy-ObjC"),
                         .product(name: "Moya", package: "Moya"),
                         .product(name: "HandyJSON", package: "HandyJSON"),
                         .product(name: "Qiniu", package: "objc-sdk"),
                         .product(name: "Starscream", package: "Starscream"),
                         .product(name: "RxSwift", package: "RxSwift"),       // 对应 pod 'RxSwift'
                         .product(name: "RxCocoa", package: "RxSwift"),       // 对应 pod 'RxCocoa'（同一仓库产物）
                     ]
        ),
    ]
)
