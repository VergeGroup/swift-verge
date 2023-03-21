# Motivation

## Verge focuses use-cases in the real-world

Recently, we could say the unidirectional data flow is a popular architecture such as flux.

## Does flux architecture have a good performance?

It depends. The performance will be the worst depends on how it is used.

However, most of the cases, we don't know the app we're creating how it will grow and scales.While the application is scaling up, the performance might decrease by getting complexity.To keep performance, we need to tune it up with several approaches.Considering the performance takes time from the beginning.it will make us be annoying to use flux architecture.

## Verge is designed for use from small and supports to scale.

Setting Verge up quickly, and tune-up when we need it.

Verge automatically tune-up and shows us what makes performance badly while development from Xcode's documentation.

For example, Verge provides these stuff to tune performance up.

- Derived (Similar to [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil)'s Selector)
- ORM

## Supports volatile events - Activity

We use an event as `Activity` that won't be stored in the state.This concept would help us to describe something that is not easy to describe as a state in the client application.
