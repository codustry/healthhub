#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint healthhub.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'healthhub'
  s.version          = '1.0.1'
  s.summary          = 'Wrapper for the iOS HealthKit and Android GoogleFit services.'
  s.description      = <<-DESC
Wrapper for the iOS HealthKit and Android GoogleFit services.
                       DESC
  s.homepage         = 'https://pub.dev/packages/healthhub'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Codustry' => 'hello@codustry.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
