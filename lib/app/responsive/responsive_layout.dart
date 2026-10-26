import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum DeviceType { mobile, tablet, desktop }

class DeviceInfo extends InheritedWidget {
  const DeviceInfo({super.key, required this.type, required super.child});

  final DeviceType type;

  static DeviceType of(BuildContext context) {
    final info = context.dependOnInheritedWidgetOfExactType<DeviceInfo>();
    return info?.type ?? _typeFromWidth(MediaQuery.sizeOf(context).width);
  }

  static DeviceType _typeFromWidth(double width) {
    if (width >= AppBreakpoints.desktop) return DeviceType.desktop;
    if (width >= AppBreakpoints.mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  @override
  bool updateShouldNotify(DeviceInfo oldWidget) => oldWidget.type != type;
}

/// Layout responsif: menentukan DeviceType dari lebar layar dan
/// menyediakannya ke subtree lewat [DeviceInfo].
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.builder});

  final Widget Function(BuildContext context, DeviceType type) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = DeviceInfo._typeFromWidth(constraints.maxWidth);
        return DeviceInfo(
          type: type,
          child: Builder(builder: (context) => builder(context, type)),
        );
      },
    );
  }
}

extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => DeviceInfo.of(this);
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
}
