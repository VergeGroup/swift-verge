Pod::Spec.new do |s|
  s.name         = "Verge"
  s.version      = "5.2.0"
  s.summary      = "The Architecture for building UI"
  s.description  = <<-DESC
  The unidirectional design pattern inspired with Flux
                   DESC
  s.license      = "MIT"
  s.author             = { "Muukii" => "muukii.app@gmail.com  " }
  s.social_media_url   = "http://twitter.com/muukii_app"
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.13'
  s.source       = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.source_files  = "Sources/VergeClassic/*.swift"
  s.homepage     = "https://github.com/muukii/Verge"

  s.dependency 'RxSwift', '~> 5'
  s.dependency 'RxCocoa', '~> 5'
end
