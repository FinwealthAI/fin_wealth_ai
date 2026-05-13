import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildWebGoogleButton() {
  return web.renderButton(
    configuration: web.GsiButtonConfiguration(
      type: web.GsiButtonType.standard,
      theme: web.GsiButtonTheme.outline,
      size: web.GsiButtonSize.large,
      shape: web.GsiButtonShape.rectangular,
      text: web.GsiButtonText.continueWith,
    ),
  );
}
