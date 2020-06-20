<p align="center">
<img width="240" alt="Frame 8" src="https://user-images.githubusercontent.com/1888355/82828305-b6d2e880-9eeb-11ea-9c3b-7659da42b499.png">
</p>

<h1 align="center">Verge</h1>
<p align="center">
<sub>A faster and scalable flux library for iOS App - SwiftUI / UIKit</sub><br/>
<sub>Mainly, it inspired by <a hrfef="https://vuex.vuejs.org/"><b>Vuex</b></a></sub>
<br/>
<sub>Fully documented and used in production at <a hrfef="https://eure.jp/"><b>Eureka, Inc.</b></a></sub>
</p>

<p align="center">
<img alt="swift5.2" src="https://img.shields.io/badge/swift-5.2-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/muukii/Verge/workflows/Tests/badge.svg"/>
<img alt="cocoapods" src="https://img.shields.io/cocoapods/v/Verge" />
</p>

<p align="center">
<img alt="VergeStore sample code" width="495" src="https://user-images.githubusercontent.com/1888355/84426195-c5e0c700-ac5d-11ea-94ab-6604c64caca0.png"/>
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


<!--stackedit_data:
eyJoaXN0b3J5IjpbMTM2MDcwNTAwMywtMTM5ODAzNzAxMiwtMT
MxNTQzOTc0MywxNzQ3NDUxMDIzLC0xNjE2Nzg4MiwtMTQ1NjEy
MDIzNCwxMzI1MjAzMzkyLC0zNDQwMDc0MzcsMTk4NDM3MTkwNC
w1NDc5ODY4NTQsMjQyMTc4OTI3LDE2OTU1NzUwMjMsMTI3MTA3
MjA0NiwtMzQxNDI0MzgyLDk3MTY3NDU5Nyw4NDczNDc3NzQsMT
I4MTQ0ODQ5OCwtMTA3MTU1MTU0NCwtMTg5NTQ4MDcwMCwyMTA0
NTExNzk5XX0=
-->
