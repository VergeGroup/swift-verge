<p align="center">
  <a href="https://vergegroup.github.io/Verge/">
<img width="256" alt="VergeIcon" src="https://user-images.githubusercontent.com/1888355/85240806-7d52b600-b474-11ea-8179-f9fe49636877.png">
    </a>
</p>

<h1 align="center">Verge</h1>
<p align="center">
<sub>A faster and scalable flux library for iOS App - SwiftUI / UIKit</sub><br/>
<sub>Mainly, it inspired by <a hrfef="https://vuex.vuejs.org/"><b>Vuex</b></a></sub>
<br/>
<sub>Fully documented and used in production at <a hrfef="https://eure.jp/"><b>Eureka, Inc.</b></a></sub>
</p>

<p align="center">
 <a href="https://vergegroup.github.io/Verge/">
   <b>Please see the website</b>
  </a>
  </p>

<p align="center">
<img alt="swift5.2" src="https://img.shields.io/badge/swift-5.2-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/muukii/Verge/workflows/Tests/badge.svg"/>
<img alt="cocoapods" src="https://img.shields.io/cocoapods/v/Verge" />
</p>

## Requirements

* Swift 5.2 +
* iOS 10 +
* UIKit and SwiftUI

## Verge

Verge is a performant flux based state management library for iOS.

Please see the website: https://vergegroup.github.io/Verge/

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


## Installation

### CocoaPods

**VergeStore**

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

## Author

[🇯🇵 Muukii (Hiroshi Kimura)](https://github.com/muukii)

## License

Verge is released under the MIT license.
