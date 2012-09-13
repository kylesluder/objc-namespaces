@namespace default
@interface NSObject

@public
- publicMethod; // @selector(default, publicMethod)
// Can be referenced by anyone who can see this declaration

@protected
- protectedMethod; // @selector(default.NSObject.protected, protectedMethod)
// Can be referenced within implementation of default.NSObject or any category or derived class in any namespace

@end

@interface NSObject (PrivateAndPackageExtensions)
@package
- packageMethod; // @selector(default.NSObject.package, packageMethod)
// Can be referenced within any implementation in the default namespace

@private
- privateHelper; // @selector(default.NSObject.private, privateHelper)
// Can be referenced within implementation of default.NSObject or a category on it
@end
@end

@namespace ThirdPartyFramework
@interface MyObject : NSObject

@public
- thirdPartyPublicMethod; // @selector(ThirdPartyFramework, thirdPartyPublicMethod)

@protected
- thirdPartyProtectedMethod; // @selector(ThirdPartyFramework.MyObject.protected, thirdPartyProtectedMethod)

@package
- thirdPartyPackageMethod; // @selector(ThirdPartyFramework.MyObject.package, thirdPartyPackageMethod)

@private
- thirdPartyPrivateMethod; // @selector(ThirdPartyFramework.MyObject.private, thirdPartyPrivateMethod)

@end
