#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "desert0213_landscape" asset catalog image resource.
static NSString * const ACImageNameDesert0213Landscape AC_SWIFT_PRIVATE = @"desert0213_landscape";

/// The "desert0213_portrait" asset catalog image resource.
static NSString * const ACImageNameDesert0213Portrait AC_SWIFT_PRIVATE = @"desert0213_portrait";

#undef AC_SWIFT_PRIVATE
