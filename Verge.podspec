Pod::Spec.new do |s|
  s.name         = "Verge"
  s.version      = "6.0.0-beta.2"
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
  
  s.swift_version = '5.1'

  s.default_subspec = 'Core'

  s.subspec 'Classic' do |ss|
    ss.dependency 'RxSwift', '~> 5.0.0'
    ss.dependency 'RxCocoa', '~> 5.0.0'   
    ss.dependency 'RxRelay', '~> 5.0.0'
    ss.source_files = 'Sources/VergeClassic/**/*.swift'    
    ss.dependency 'Verge/Core'
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/VergeCore/**/*.swift'    
    ss.weak_frameworks = ['Combine']
  end

  s.subspec 'Store' do |ss|
    ss.source_files = 'Sources/VergeStore/**/*.swift'    
    ss.dependency 'Verge/Core'
  end

  s.subspec 'Rx' do |ss|
    ss.dependency 'Verge/Store'
    ss.dependency 'RxSwift', '~> 5.0.0'
    ss.dependency 'RxCocoa', '~> 5.0.0'   
    ss.dependency 'RxRelay', '~> 5.0.0'
    ss.source_files = 'Sources/RxVergeStore/**/*.swift'    
  end

  s.subspec 'VM' do |ss|
    ss.dependency 'Verge/Store'   
    ss.source_files = 'Sources/VergeViewModel/**/*.swift'    
  end

  s.subspec 'ORM' do |ss|
    ss.source_files = 'Sources/VergeORM/**/*.swift'    
    ss.dependency 'Verge/Core'   
  end

end
