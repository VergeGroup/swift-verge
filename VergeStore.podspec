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

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source       = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.homepage     = "https://github.com/muukii/Verge"

  s.weak_frameworks = ['Combine']
  s.swift_version = '5.1'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/VergeStore/**/*.swift'    
  end

  s.subspec 'Rx' do |rx|
    rx.dependency 'VergeStore/Core'
    rx.dependency 'RxSwift', '~> 5.0.0'
    rx.dependency 'RxCocoa', '~> 5.0.0'   
    rx.dependency 'RxRelay', '~> 5.0.0'
    rx.source_files = 'Sources/RxVergeStore/**/*.swift'    
  end

  s.subspec 'VM' do |rx|
    rx.dependency 'VergeStore/Core'   
    rx.source_files = 'Sources/VergeViewModel/**/*.swift'    
  end

end
