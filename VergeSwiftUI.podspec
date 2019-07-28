Pod::Spec.new do |s|
  s.name         = "VergeSwiftUI"
  s.version      = "0.0.1"
  s.summary      = "The Architecture for building UI"
  s.description  = <<-DESC
  The unidirectional design pattern inspired with Flux
                   DESC
  s.license      = "MIT"
  s.author             = { "Muukii" => "muukii.app@gmail.com  " }
  s.social_media_url   = "http://twitter.com/muukii_app"
  s.ios.deployment_target = '13.0'
  s.source       = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.source_files  = "VergeSwiftUI/*.swift"
  s.homepage     = "https://github.com/muukii/Verge"
end
