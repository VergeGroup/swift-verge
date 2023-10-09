
@freestanding(expression)
public macro keyPathMap<U, each T>(_ keyPaths: repeat KeyPath<U, each T>) -> (borrowing U) -> (repeat each T) = #externalMacro(module: "VergeMacrosPlugin", type: "KeyPathMap")
