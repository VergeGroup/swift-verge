<p align="center">
  <a href="https://vergegroup.github.io/Verge/">
<img width="256" alt="VergeIcon" src="https://user-images.githubusercontent.com/1888355/85241314-5ac19c80-b476-11ea-9be6-e04ed3bc6994.png">
    </a>
</p>

<h1 align="center">Verge</h1>
<p align="center">
<sub>A faster and scalable flux library for iOS App - SwiftUI / UIKit</sub><br/>
<br/>
<sub>Fully documented and used in production at <a hrfef="https://eure.jp/"><b>Eureka, Inc.</b></a></sub><br/>
<sub>⭐️ If you like and interested in this, give it a star on this repo! We'd like to know developer's needs. ⭐️</sub>
</p>

<p align="center">
 <a href="https://vergegroup.github.io/Verge/">
   <b>Please see the website</b>
  </a>
  </p>

<p align="center">
<img alt="swift5.3" src="https://img.shields.io/badge/swift-5.3-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/muukii/Verge/workflows/Tests/badge.svg"/>
<img alt="cocoapods" src="https://img.shields.io/cocoapods/v/Verge" />
</p>

## Requirements

* Swift 5.2 +
* @available(iOS 10, macOS 10.13, tvOS 10, watchOS 3)
* UIKit and SwiftUI

## Verge

Verge is a performant store-pattern based state management library for iOS.

Please see the website: https://vergegroup.github.io/Verge/

[And the article about store-pattern](https://medium.com/eureka-engineering/verge-start-store-pattern-state-management-before-beginning-flux-in-uikit-ios-app-development-6c74d4413829)

### Motivation

#### Verge focuses use-cases in the real-world

Recently, we could say the unidirectional data flow is a popular architecture such as flux.

#### Does flux architecture have a good performance?

It depends.
The performance will be the worst depends on how it is used.

However, most of the cases, we don't know the app we're creating how it will grow and scales.  
While the application is scaling up, the performance might decrease by getting complexity.  
To keep performance, we need to tune it up with several approaches.  
Considering the performance takes time from the beginning.  
it will make us be annoying to use flux architecture.

#### Verge is designed for use from small and supports to scale.

Setting Verge up quickly, and tune-up when we need it.

Verge automatically tune-up and shows us what makes performance badly while development from Xcode's documentation.

For example, Verge provides these stuff to tune performance up.

- Derived (Similar to [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil)'s Selector)
- ORM

#### Supports volatile events

We use an event as `Activity` that won't be stored in the state.  
This concept would help us to describe something that is not easy to describe as a state in the client application.

<img width=513 src="https://user-images.githubusercontent.com/1888355/85392055-fc83df00-b585-11ea-866d-7ab11dfa823a.png" />

## Installation

### CocoaPods

**Verge** (core module)

```ruby
pod 'Verge/Store'
```

**VergeORM**

```ruby
pod 'Verge/ORM'
```

**VergeRx**

```ruby
pod 'Verge/Rx'
```

These are separated with subspecs in Podspec.<br>
After installed, these are merged into single module as `Verge`.

To use Verge in your code, define import decralation following.

```swift
import Verge
```

## SwiftPM

Verge supports also SwiftPM.

## Questions

Please feel free to ask something about this library!  
I can reply to you faster in Twitter.

日本語での質問も全然オーケーです😆  
Twitterからだと早く回答できます⛱

[Twitter](https://twitter.com/muukii_app)

## Demo applications

This repo has several demo applications in Demo directory.
And we're looking for your demo applications to list it here!
Please tell us from Issue!

## Author

[🇯🇵 Muukii (Hiroshi Kimura)](https://github.com/muukii)

## License

Verge is released under the MIT license.
