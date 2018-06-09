Pod::Spec.new do |s|
  s.name         = "Cycler"
  s.version      = "3.0.0"
  s.summary      = "Cycling Event Flow"
  s.description  = <<-DESC
  The unidirectional design pattern inspired with Flux
                   DESC
  s.license      = "MIT"
  s.author             = { "Muukii" => "m@muukii.me" }
  s.social_media_url   = "http://twitter.com/muukii0803"
  s.platform     = :ios
  s.ios.deployment_target = '8.0'
  s.source       = { :git => "https://github.com/muukii/Cycler.git", :tag => s.version }
  s.source_files  = "Cycler/*.swift"
  s.homepage     = "https://github.com/muukii/Cycler"

  s.dependency 'RxSwift', '~> 4.2.0'
  s.dependency 'RxCocoa', '~> 4.2.0'
end
