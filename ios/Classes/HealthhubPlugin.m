#import "HealthhubPlugin.h"
#if __has_include(<heathhub/heathhub-Swift.h>)
#import <healthhub/healthhub-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "healthhub-Swift.h"
#endif

@implementation HealthhubPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftHealthhubPlugin registerWithRegistrar:registrar];
}
@end
