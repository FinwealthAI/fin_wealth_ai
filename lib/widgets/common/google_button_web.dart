import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildWebGoogleButton() {
  final web.GoogleSignInPlugin googleSignInPlugin = 
      GoogleSignInPlatform.instance as web.GoogleSignInPlugin;
  return googleSignInPlugin.renderButton();
}
