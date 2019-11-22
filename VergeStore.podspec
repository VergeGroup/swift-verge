Pod::Spec.new do |s|
  s.name         = "VergeStore"
  s.version      = "6.0.0-alpha.1"
  s.summary      = "VergeStore is Flux / Redux framework on SwiftUI/UIKit"
  s.description  = <<-DESC
  Verge Neue is Flux / Redux framework on SwiftUI (It's not exclusive only SwiftUI)
                   DESC
  s.license      = "MIT"
  s.author             = { "Muukii" => "muukii.app@gmail.com  " }
  s.social_media_url   = "http://twitter.com/muukii_app"

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.13'

  s.source       = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.source_files  = "Sources/VergeStore/**/*.swift"
  s.homepage     = "https://github.com/muukii/Verge"

  s.weak_frameworks = ['Combine']
  s.swift_version = '5.1'
end
