Namespaces in Objective-C
=====

Objective-C has lacked namespaces since its creation. Unfortunately because it wholly embraces its message-passing model of OOP, it is very difficult to retrofit existing other languages' approaches to namespacing atop Objective-C without breaking binary compatibility. A naive namespacing approach might make it impossible for code that is not namespace-aware to send meaningful selectors to namespace-aware code.

This proposal introduces a new kind of selector that carries a namespace in addition to, but distinct from, its keywords. It redefines classes, categories and protocols to be members of namespaces, and provides rules for what namespaces their methods belong to.


Motivation
=====

In practical Cocoa applications, the lack of namespaces leads to two conventions that are less than ideal:

1. Class, category, and protocol names must begin with distinct character strings, such as `NS` or `OF`.

2. Private and internal methods and selectors must be named in such a way that no other code in the process (and in particular in the inheritance chain) would refer to that selector unintentionally.

A common technique to achieve requirement 2 is to prefix method names with an underscore. This has led to multiple clashes between application and framework codebases and even rejection from the Mac and iOS App Stores for falsely-detected attempts to invoke private API.

Adding namespaces to the language will provide a well-known technique to naturally avoid this issue and make code more readable.


Compile time and runtime phases
=====

Because namespaces exist to alleviate naming conflicts between classes that might exist in different linkage units (for example, between a framework and a main executable), and owing to Objective-C's dynamism, support for namespaces exists both in the compiler and the runtime.

The compiler operates on Objective-C _programs_, which consist of source code assembled into a _translation unit_. The runtime operates within the context of an _executable_, which is formed of one or more _binaries_ produced by the compiler and linker.


Namespaces
=====

A _namespace_ is a conceptual grouping of classes, categories, protocols, and selectors (henceforth referred to collectively as _Objective-C symbols_). Every Objective-C symbol in an Objective-C program belongs to exactly one namespace.

Within a namespace, no two Objective-C symbols of the same kind may have the same name. Two Objective-C symbols of the same kind belonging to two different namespaces may have the same name. No two namespaces in an application may have the same name. No Objective-C symbol may have the same name as the namespace to which it belongs.

**Rationale:** Allowing namespaces and other kinds of identifiers to share names complicates parsing.

A namespace is named by a string of valid C identifier characters optionally separated by periods.

    namespace-id :: identifier-chars [ '.' identifier-chars ]+

There is one flat collection of namespaces.

**Rationale**: 

No provision is made for mapping Objective-C namespaces to C++ namespaces, even when compiling Objective-C++ code.

**Rationale**: It's not the goal to make life hard for Objective-C++ developers, but it's likewise not the goal to make Objective-C developers deal with all the intricacies of C++ namespaces, or (potentially worse) just a subset of them.


The Global Namespace
=====

There exists one namespace called the _global namespace_ to which all classes, categories, and protocols are assumed to belong unless otherwise specified. The contents of this namespace are visible from every scope. (See "Namespace Scopes and the `@using` Directive").

**Rationale:** This namespace exists primarily to support interoperating with existing code that is not namespace-aware. In particular, to remain compatible with existing code, framework classes should remain in the default namespace while their private methods should be moved to categories in a private namespace.


Qualified Identifiers
=====

A _qualified identifier_ is an identifier consisting of the name of an Objective-C symbol preceded by a namespace identifier and a backtick character ('`').

    qual-id :: namespace-id '`' identifier-chars

For example, `MyNamespace``MyClass` is a qualified identifier that refers to the `MyClass` Objective-C symbol in the `MyNamespace` namespace.

**Rationale:** Backtick is the only special character on a US English keyboard which doesn't already have significance in C.

An _unqualified identifier_ is any other kind of identifier. (See "Namespace Scopes and the `@using` Directive.)


Namespace Blocks
=====

The `@namespace` keyword begins a namespace block that exists until a balancing `@end` keyword:

    @namespace <ns>
      .
      .
      .
    @end

Namespace blocks may only exist at the top level of a source file, as the direct child of another Objective-C namespace block, or as the direct child of a curly-brace delimited block attached to a C++ `namespace` declaration.

**Rationale**: It might not always be feasible to order Objective-C++ source code such that all the Objective-C `@namespace` declarations precede the C++ `namespace` declarations.

Unqualified declarations, including forward declarations, declared within a namespace block belong to the namespace named by that block. Namespaces can be reopened in the same or other translation units in any module using a `@namespace` block, but those symbols may not be visible to code in scopes that cannot see the actual declaration.


Namespace Scopes and the `@using` Directive
=====

At any given point in a translation unit there exists a stack of namespace scopes. A namespace scope consists of a set of identifiers and namespace aliases. Each C scope and Objective-C `@`-block creates a correspondingly-lived namespace scope. Each namespace scope is also a C identifier scope.

When the compiler encounters an unqualified identifier, it looks up the stack of namespace scopes to find a matching identifier of an appropriate kind. It first tries to match any C symbols in the current scope. If a match is not found, the compiler then tries to match an Objective-C symbol of an appropriate kind. If none is found, the compiler emits an error.

All identifiers in the namespace named by a `@namespace` block are a member of the namespace scope created by that block.

**Note:** With two-pass compilation, this means that a namespace scope includes even identifiers declared _after_ the end of the namespace scope in which they are used. With one-pass compilation, this may require appropriate placement or qualification of forward declarations.

The `@using` directive can be used to create a new scope that contains either a single identifier or all the identifiers from a namespace:

    - (void)foo;
    {               // introduces a namespace scope (and a C scope)
      . . .
      @using ns1`a; // introduces a namespace scope containing the identifier a from namespace ns1
      . . .
      @using ns2;   // introduces a namespace scope containing all identifiers from namespace ns2
      . . .
    }               // end of namespace (and C) scopes

The scope created by the `@using` directive extends from the `@using` directive to the end of the containing scope.

The `@using` directive can also create a namespace scope containing a namespace alias:

    - (void)bar;
    {
      . . .
      @using ns = some.long.namespace; // introduces a namespace scope that contains an alias `ns` for the namespace some.long.namespace
      . . .
    }                                  // end of namespace (and C) scopes

Within a scope containing a namespace alias, references to that namespace alias are treated as if they were spelled as references to the original namespace.

A `@using` directive MAY NOT create an ambiguity in identifier resolution. A `@using` directive that would cause an unqualified identifier to refer to two different symbols is an error.


Qualified Selectors
=====

Since all selectors belong to exactly one namespace, the _selector literal_ is extended to include an optional namespace qualifier:

    selector :: '@' 'selector' '(' [ [ namespace-id ] ? '`' ] ? [ keyword [ ':' ] ? ]+ ')'

This permits three kinds of selector literals:

* A selector literal of the form `@selector(MyNamespace``keyword1:keyword2:)`, which is a _qualified_ selector referring to the `keyword1:keyword2:` selector in the `MyNamespace` namespace

* A selector literal of the form `@selector(``keyword1:keyword2:)`, which is a _qualified_ selector referring to the `keyword1:keyword2:` selector in the global namespace

* A selector literal of the form `@selector(keyword1:keyword2:)`, which is an _unqualified_ selector. (See "Method Resolution".)

Just as it is not an error to create a `@selector` expression that refers to a non-existent method, it is not an error to refer to a non-existent namespace in a namespaced `@selector` expression. The compiler can optionally be made to warn about such expressions; these warnings can be silenced by making a declaration of a category within the appropriate namespace visible to the `@selector` expression.

**Rationale**: It is often useful for code to refer to private or otherwise invisible names. For example, debugging code might want to send a private message to an object, or replace a private method's implementation with one that logs. Requiring an artificial category declaration just to reference such symbols seems heavy-handed, though extending the approach of `-Wundeclared-selector` to namespaces offers flexibility to those who believe code quality is improved by requiring explicit redeclarations of the contents of private namespaces.

Namespaced Messages
=====

When emitting a message send, the compiler encodes a selector with a namespace chosen based on the static type of the receiver and the current namespace scope. If the compiler finds a method whose keywords match those in the message send, it encodes that namespace in the selector, preferring namespaces closer in scope to the message send.

**TODO:** What namespace is used if the receiver is of type `id`?

The programmer can override the compiler's preferred namespace selection by prefixing the first keyword with a qualifier:

    [<receiver> MyNamespace`arg1:... arg2:...];

As noted above, the compiler should warn if multiple methods in different namespaces with the same keywords are seen defined on the class of the receiver.


Namespaced Classes, Categories, and Protocols
=====

Every class, category, and protocol must belong to one and only one namespace. However, a category on a class in namespace A may be defined in namespace B; their namespaces are separate. Likewise, a class in namespace A may declare its conformance to a protocol in namespace C (potentially by a category that is declared in namespace B). Metaclasses belong to the same namespace as their corresponding class.

This makes it possible to expose publicly expose a class that implements some private methods with which external subclasses or categories cannot conflict. The private methods would be declared in a category on the public class defined in a separate namespace that is not visible to other code.

The methods declared in an `@interface` or `@protocol` block belong to the namespace of the container that declares them. In an `@implementation` block, the compiler must use a heuristic to determine which namespace the method being defined belongs to.

When the compiler encounters a method definition, it looks at the declarations of the entire inheritance and conformance chain for the class or category being implemented. If it finds only one method declaration whose signature matches the method definition, then it associates the definition with that declaration. This makes it possible to implement conformance to a protcol in namespace B from within a class or category defined in namespace A. If multiple declarations are found from classes or protcols in different namespaces, the compiler SHOULD produce a warning.

Method definitions that do not have a corresponding declaration visible to the compiler at the point of definition belong to the namespace of their containing `@implementation` block.


Compatibility with Legacy Code
=====

Legacy code that interfaces with namespace-aware code will emit selectors that do not belong to any namespace. Such selectors are called _legacy selectors_. To implement backwards-compatibility, a new comparison between selectors is defined:

* Qualified selectors are considered equal if and only if their namespaces and keywords are equal.

* Legacy selectors are considered equal if and only if their keywords are equal.

* A qualified selector is considered "compatible with" a legacy selector if and only if their keywords are equal.

When resolving a legacy selector to a method at runtime, the dispatch machinery follows a certain resolution order, where _S_ refers to the selector being dispatched and _C_ is the class for the receiver (or a metaclass if the receiver is a class).

1. If a matching method is found on _C_ that belongs to the same namespace as _S_, that method is chosen. Only one such method can exist.

   **Rationale:** It's possible to produce a binary that has multiple definitions of a method in the same namespace, but the loader will have chosen one winning method. This situation already exists independent of namespacing.

2. Else, if _S_ does not have a namespace and a matching method is found on _C_ in the `default` namespace, that method is chosen. Only one such method can exist.

3. Else, if _S_ does not have a namespace and a matching method is found on _C_ in any other namespace, one such method is chosen. Which one is chosen is undefined.

3. Else, the resolution fails.



Examples
=====

The simplest way to adopt namespaces is to add explicit namespaces to identifiers.

	// ExplicitNamespaces.h
	#import <Foundation/NSObject.h>
	@interface MyNS @@ MyClass : default @@ NSObject
	- (void)publicMethod;
	@end
	
	// ExplicitNamespaces.m
	#import "ExplicitNamespaces.h"
	@interface MyNS`MyClass (PrivateNS`PrivateMethods)
	- (void)privateMethod;
	@end
	
	@implementation MyNS`MyClass
	- (void)privateMethod;
	{
		// Compiler resolves this implementation to @selector(PrivateNS, privateMethod)
	}
	
	- (void)publicMethod;
	{
		// Compiler resolves this implementation to @selector(MyNS, publicMethod)
	}
	@end

To avoid redundancy, you can use a `@namespace` block:

    // NamespaceBlock.h
    #import <Foundation/NSObject.h>
    @namespace MyNS
    @interface MyClass : NSObject
        // Compiler resolves NSObject to default`NSObject, because that is the closest declaration of NSObject that it sees
    @end
    @end

A common but complicated scenario involves using protocols from other namespaces in a private category:

    // MyFramework.h
    @namespace MyFramework
    @protocol FwkProto
    @optional
        - (void)fwkMethod;
    @end
    @end
    
    // MyClass.h
    #import <Foundation/NSObject.h>
    #import <MyFramework/MyFramework.h>
    @namespace MyNS
    @interface MyClass : NSObject
    - (void)publicMethod;
    @end
    @end
    
    // MyClass.m
    #import "MyClass.h"
    
    @interface MyNS`MyClass (PrivateNS`PrivateMethods) <MyFramework`FwkProto>
    - (void)privateHelperMethod;
    @end
    
    @implementation MyNS`MyClass
    - (void)publicMethod;
    {
        // @selector(MyNS, publicMethod)
    }
    
    - (void)fwkMethod;
    {
        // NOTE: This resolves to @selector(MyNS, fwkMethod) !!!
        // Because the inheritance and conformance chain of _this @implementation_ does not include a class or protocol that declares a selector named fwkMethod, the compiler considers this to be a definition of an undeclared method.
        // But because the compiler can see a category on this class that conforms to a protocol that declares a selector with a matching signature (even though both the selector and the category are in namesapces different from this implementation), it SHOULD issue a warning about this confusing behavior.
    }
    @end
    
    @implementation MyNS`MyClass (PrivateNS`PrivateMethods)
    
    // Omit definition of optional -fwkMethod. If we included the definition here, the compiler would issue another warning that it could see two methods were defined on the same class with matching selectors in different namespaces.
    
    @end