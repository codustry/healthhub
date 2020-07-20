import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/healthhub.dart';

void main() {
  const MethodChannel channel = MethodChannel('health');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(Healthhub.isDataTypeAvailable(HealthDataType.WEIGHT), true);
  });
}
