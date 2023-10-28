
@attached(extension, conformances: StateType)
@attached(member)
@attached(memberAttribute)
public macro State() = #externalMacro(module: "VergeMacrosPlugin", type: "StateMacro")

@attached(accessor)
public macro StateMember() = #externalMacro(module: "VergeMacrosPlugin", type: "StateMemberMacro")

#if DEBUG

@State
struct MyState {
  var name: Int = 0

  @Edge var count: Int = 0
}

#endif
