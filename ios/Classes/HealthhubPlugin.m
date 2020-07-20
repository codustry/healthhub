#import "HeathhubPlugin.h"
#if __has_include(<heathhub/heathhub-Swift.h>)
#import <heathhub/heathhub-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "heathhub-Swift.h"
#endif

@implementation HeathhubPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftHeathhubPlugin registerWithRegistrar:registrar];
}
@end
