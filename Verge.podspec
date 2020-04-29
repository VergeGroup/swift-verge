Pod::Spec.new do |s|
  s.name         = "Verge"
  s.version      = "7.0.0-beta.18"
  s.summary      = "Verge is a state management tools"
  s.description  = <<-DESC
  Verge is a state management tools (Store, ViewModel, ORM, Reactive) on iOS App (UIKit / SwiftUI)
                   DESC
  s.license      = "MIT"
  s.author             = { "Muukii" => "muukii.app@gmail.com  " }
  s.social_media_url   = "http://twitter.com/muukii_app"

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source       = { :git => "https://github.com/muukii/Verge.git", :tag => s.version }
  s.homepage     = "https://github.com/muukii/Verge"
  
  s.swift_version = '5.2'

  s.default_subspec = 'Core'

  s.weak_frameworks = ['Combine']

  s.subspec 'Classic' do |ss|
    ss.dependency 'RxSwift', '~> 5'
    ss.dependency 'RxCocoa', '~> 5'   
    ss.dependency 'RxRelay', '~> 5'
    ss.source_files = 'Sources/VergeClassic/**/*.swift'    
    ss.dependency 'Verge/Core'
    ss.dependency 'Verge/Rx'
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/VergeCore/**/*.swift'    
  end

  s.subspec 'Store' do |ss|
    ss.source_files = 'Sources/VergeStore/**/*.swift'    
    ss.dependency 'Verge/Core'
  end

  s.subspec 'Rx' do |ss|
    ss.dependency 'Verge/ORM'
    ss.dependency 'Verge/Store'
    ss.dependency 'RxSwift', '~> 5'
    ss.dependency 'RxCocoa', '~> 5'   
    ss.dependency 'RxRelay', '~> 5'
    ss.source_files = 'Sources/VergeRx/**/*.swift'    
  end

  s.subspec 'ORM' do |ss|
    ss.source_files = 'Sources/VergeORM/**/*.swift'    
    ss.dependency 'Verge/Store'   
  end

end
