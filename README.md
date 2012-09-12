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


Namespaces
=====

A namespace is a conceptual grouping of classes, categories, protocols, and selectors in which no two types of the same kind may have the same name. Two types of the same kind belonging to two different namespaces may have the same name. No two namespaces in an application may have the same name.

A namespace is named by a string consisting of valid C identifier characters and periods. There is one flat collection of namespaces; namespaces can only contain Objective-C classes, categories, protocols, and selectors. No provision is made for mapping Objective-C namespaces to C++ namespaces, even when compiling Objective-C++ code.[^OBJCPP]

[^OBJCPP]: It's not the goal to make life hard for Objective-C++ developers, but it's likewise not the goal to make Objective-C developers deal with all the intricacies of C++ namespaces, or (potentially worse) just a subset of them.


The Default Namespace
=====

There exists one namespace named `default` to which all classes, categories, and protocols are assumed to belong unless otherwise specified. This namespace exists primarily to support interoperating with existing code that is not namespace-aware. In particular, to remain compatible with existing code, framework classes should remain in the default namespace while their private methods should be moved to categories in a private namespace.


Qualified Identifiers
=====

A _qualified identifier_ names the namespace to which the object referred to by the identifier belongs. For example, `default.NSObject` is a qualified identifier that refers to the `NSObject` class (or protocol, depending on context) in the `default` namespace.


Namespace Blocks
=====

The `@namespace` keyword begins a namespace block that exists until a balancing `@end` keyword:

    @namespace <ns>
      .
      .
      .
    @end

Namespace blocks cannot occur within any other block (in either the Objective-C `@ ... @end` or C "delimited by curly-braces" sense), including within any other namespace block.[^OBJCPPNS]

Unqualified declarations, including forward declarations, declared within a namespace block belong to the namespace named by that block. Namespaces can be reopened in the same or other translation units in any module using a `@namespace` block, but those symbols may not be visible to code in scopes that cannot see the actual declaration.

[^OBJCPPNS]: It might be worth considering relaxing this restriction to allow use of Objective-C `@namespace` within C++ `namespace` blocks, but since C++ namespaces can also be reopened there doesn't seem to be a pressing need. 


Namespace Scopes and the `@using` Directive
=====

At any given point in a translation unit there exists a stack of namespace scopes. A namespace scope consists of a set of identifiers and namespace aliases. Each C scope and Objective-C `@`-block creates a correspondingly-lived namespace scope. When the compiler encounters an unqualified identifier, it looks up the stack of namespace scopes to find a matching identifier of the appropriate type.

All identifiers in the namespace named by a `@namespace` block are a member of the namespace scope created by that block.[^TWOPASS]

The `@using` directive can be used to create a new scope that contains either a single identifier or all the identifiers from a namespace:

    - (void)foo;
    {               // introduces a namespace scope (and a C scope)
      . . .
      @using ns1.a; // introduces a namespace scope containing the identifier a from namespace ns1
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

[^TWOPASS]: With two-pass compilation, this means that a namespace scope includes even identifiers declared _after_ the end of the namespace scope in which they are used. With one-pass compilation, this may require appropriate placement or qualification of forward declarations.


Namespaced Selectors
=====

At the heart of this proposal is the redefinition of the selector (whose type is known as `SEL` in Objective-C code). The selector is currently defined as a set of keywords of the form `@selector(key1:key2)`. Under this proposal, selectors gain an _optional_ namespace. A new comparison between selectors is defined:

* Selectors with namespaces are considered equal if and only if their namespaces and keywords are equal.
* Selectors without namespaces are considered equal if and only if their keywords are equal.
* A selector with a namespace is considered "compatible with" a selector lacking a namespace if and only if their keywords are equal.

New syntax is defined to refer to namespaced selectors: `@selector(<ns>, <kw>)` refers to a selector in the namespace `<ns>` composed of keywords `<kw>`. The existing `@selector(<kw>)` syntax looks up a selector based on the namespace scope resolution rules above. The compiler should warn if multiple matching selectors are found in the current stack of namespace scopes.

To produce a selector in the default namespace, use the spelling `@selector(default, <kw>)`. To produce a selector that has no namespace, use the spelling `@selector(nil, <kw>)`.[^NILNS]

[^NILNS]: If the definition of `nil` is not changed to become a true keyword (or an alias thereof) rather than a macro for a null pointer constant, this definition may likewise permit the use of any null pointer constant as the first argument to the `@selector()`.


Namespaced Classes, Categories, and Protocols
=====

Every class, category, and protocol must belong to one and only one namespace. However, a category on a class in namespace A may be defined in namespace B; their namespaces are separate. Likewise, a class in namespace A may declare its conformance to a protocol in namespace C (potentially by a category that is declared in namespace B). Metaclasses belong to the same namespace as their corresponding class.

This makes it possible to expose publicly expose a class that implements some private methods with which external subclasses or categories cannot conflict. The private methods would be declared in a category on the public class defined in a separate namespace that is not visible to other code.

The methods declared in an `@interface` or `@protocol` block belong to the namespace of the container that declares them. In an `@implementation` block, the compiler must use a heuristic to determine which namespace the method being defined belongs to.

When the compiler encounters a method definition, it looks at the declarations of the entire inheritance and conformance chain for the class or category being implemented. If it finds only one method declaration whose signature matches the method definition, then it associates the definition with that declaration. This makes it possible to implement conformance to a protcol in namespace B from within a class or category defined in namespace A. If multiple declarations are found from classes or protcols in different namespaces, the compiler SHOULD produce a warning.

Method definitions that do not have a corresponding declaration visible to the compiler at the point of definition belong to the namespace of their containing `@implementation` block.


Method Resolution
=====

When resolving a selector to a method, the dispatch machinery follows a certain resolution order, where _S_ refers to the selector being dispatched and _C_ is the class for the receiver (or a metaclass if the receiver is a class).

1. If a matching method is found on _C_ that belongs to the same namespace as _S_, that method is chosen. Only one such method can exist.[^UNIQ]

2. Else, if _S_ does not have a namespace and a matching method is found on _C_ in the `default` namespace, that method is chosen. Only one such method can exist.

3. Else, if _S_ does not have a namespace and a matching method is found on _C_ in any other namespace, one such method is chosen. Which one is chosen is undefined.

3. Else, the resolution fails.

When emitting a message send, the compiler encodes a selector with a namespace chosen based on the static type of the receiver and the current namespace scope. If the compiler finds a method whose keywords match those in the message send, it encodes that namespace in the selector, preferring namespaces closer in scope to the message send. If the receiver is of static type `id`, then no selector is encoded.

The programmer can override the compiler's preferred namespace selection using the `@namespace()` keyword:

    [<receiver> @namespace(<ns>) arg1:... arg2:...];

A namespace of `nil` instructs the compiler not to encode a namespace in the selector for the message send. This is discouraged, but can be useful when code needs to call methods in a namespace it cannot see (for example, calling private API to work around a framework or operating system bug).[^PRIVMSG]

As noted above, the compiler should warn if multiple methods in different namespaces with the same keywords are seen defined on the class of the receiver.

[^UNIQ]: It's possible to produce an binary that has multiple definitions of a method in the same namespace, but the loader will have chosen one winning method. This situation already exists independent of namespacing.

[^PRIVMSG]: A better approach in this circumstance might be to forward-declare both the namespace and the method in question. This will permit the continued use of `-Wunknown-selector` warnings when using `@selector()` to catch typos in the namespace or keywords, or cases where ARC cannot determine the memory management behavior of the unknown selector.


`@class()` Expressions
=====

Because an arbitrary expression can be used as the receiver of an Objective-C message send, there is a potential ambiguity between a qualified class identifier `ns.SomeClass` and a member of an aggregate in local scope named `foo.SomeClass`.

New syntax is introduced to alleviate this ambiguity as well as provide a desired feature. The `@class()` parameterized keyword can be used as the argument to a message send as well wherever an expression of type "pointer to class" can appear. The parameter to the keyword is a (qualified or unqualified) identifier naming a class; the keyword expression has the type of a pointer to the named class.

With this feature, the ambiguity in message sends is resolved by always choosing variables ahead of namespaces if there is a conflict:

    @class ns.SomeClass;
    
    void f() {
      struct {
        Class SomeClass;
      } ns;
      
      [ns.SomeClass description]; // always refers to the member of struct ns
      [[ns.SomeClass class] description]; // same - refers to member of struct 
      [@class(ns.SomeClass) description]; // refers to class in namespace ns
    }

This is consistent with current behavior.


Examples
=====

The simplest way to adopt namespaces is to add explicit namespaces to identifiers.

	// ExplicitNamespaces.h
	#import <Foundation/NSObject.h>
	@interface MyNS.MyClass : default.NSObject
	- (void)publicMethod;
	@end
	
	// ExplicitNamespaces.m
	#import "ExplicitNamespaces.h"
	@interface MyNS.MyClass (PrivateNS.PrivateMethods)
	- (void)privateMethod;
	@end
	
	@implementation MyNS.MyClass
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
        // Compiler resolves NSObject to default.NSObject, because that is the closest declaration of NSObject that it sees
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
    
    @interface MyNS.MyClass (PrivateNS.PrivateMethods) <MyFramework.FwkProto>
    - (void)privateHelperMethod;
    @end
    
    @implementation MyNS.MyClass
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
    
    @implementation MyNS.MyClass (PrivateNS.PrivateMethods)
    
    // Omit definition of optional -fwkMethod. If we included the definition here, the compiler would issue another warning that it could see two methods were defined on the same class with matching selectors in different namespaces.
    
    @end