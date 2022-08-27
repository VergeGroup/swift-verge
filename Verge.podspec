Pod::Spec.new do |s|
  s.name = "Verge"
  s.version = "8.19.0"
  s.summary = "Verge is a state management tools"
  s.description = <<-DESC
  Verge is a state management tools (Store, ViewModel, ORM, Reactive) on iOS App (UIKit / SwiftUI)
                   DESC
  s.license = "MIT"
  s.author = { "Muukii" => "muukii.app@gmail.com" }
  s.social_media_url = "http://twitter.com/muukii_app"

  s.ios.deployment_target = "13.0"
  s.osx.deployment_target = "10.15"
  s.tvos.deployment_target = "13.0"
  s.watchos.deployment_target = "6.0"

  s.source = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.homepage = "https://github.com/muukii/Verge"

  s.swift_versions = ["5.3", "5.4", "5.5"]

  s.default_subspec = "Store"

  s.weak_frameworks = ["Combine", "SwiftUI"]

  s.subspec "Classic" do |ss|
    ss.dependency "RxSwift", ">= 6.0.0"
    ss.dependency "RxCocoa", ">= 6.0.0"
    ss.dependency "RxRelay", ">= 6.0.0"
    ss.source_files = "Sources/VergeClassic/**/*.swift"
    ss.dependency "Verge/Store"
    ss.dependency "Verge/Rx"
  end

  s.subspec "Tiny" do |ss|
    ss.source_files = "Sources/VergeTiny/**/*.swift"
  end

  s.subspec "ObjcBridge" do |ss|
    ss.source_files = "Sources/VergeObjcBridge/**/*.{h,m}"
  end

  s.subspec "Store" do |ss|
    ss.source_files = "Sources/Verge/**/*.swift"
    ss.dependency "Verge/ObjcBridge"
  end

#  s.subspec "Async" do |ss|
#    ss.source_files = "Sources/AsyncVerge/**/*.swift"
#    ss.dependency "Verge/Store"
#    ss.ios.deployment_target = "13.0"
#  end

  s.subspec "Rx" do |ss|
    ss.dependency "Verge/ORM"
    ss.dependency "Verge/Store"
    ss.dependency "RxSwift", ">= 6.0.0"
    ss.dependency "RxCocoa", ">= 6.0.0"
    ss.dependency "RxRelay", ">= 6.0.0"
    ss.source_files = "Sources/VergeRx/**/*.swift"
  end

  s.subspec "ORM" do |ss|
    ss.source_files = "Sources/VergeORM/**/*.swift"
    ss.dependency "Verge/Store"
  end
end
