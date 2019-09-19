Pod::Spec.new do |s|
  s.name         = "VergeNeue"
  s.version      = "0.0.1"
  s.summary      = "Verge Neue is Flux / Redux framework on SwiftUI"
  s.description  = <<-DESC
  Verge Neue is Flux / Redux framework on SwiftUI (It's not exclusive only SwiftUI)
                   DESC
  s.license      = "MIT"
  s.author             = { "Muukii" => "muukii.app@gmail.com  " }
  s.social_media_url   = "http://twitter.com/muukii_app"
  s.ios.deployment_target = '8.0'
  # s.osx.deployment_target = '10.13'
  s.source       = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.source_files  = "VergeNeue/*.swift"
  s.homepage     = "https://github.com/muukii/Verge"

  s.weak_frameworks = ['SwiftUI', 'Combine']
  s.swift_version = '5.1'
end
