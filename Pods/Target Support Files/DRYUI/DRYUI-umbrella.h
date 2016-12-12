#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DRYUI.h"
#import "DRYUIMetamacros.h"
#import "libextobjc-metamacros.h"

FOUNDATION_EXPORT double DRYUIVersionNumber;
FOUNDATION_EXPORT const unsigned char DRYUIVersionString[];

