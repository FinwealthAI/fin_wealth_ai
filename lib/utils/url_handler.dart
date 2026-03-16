import 'package:flutter/material.dart';
import 'package:fin_wealth/screens/blog_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHandler {
  static void openUrl(BuildContext context, String? url, {String? title}) {
    if (url == null || url.isEmpty) return;

    // Check if it's a blog link or refers to the mobile domain
    if (url.contains('/blog/') || url.contains('m.finwealth.vn')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlogDetailScreen(
            url: url,
            title: title ?? 'FinWealth Blog',
          ),
        ),
      );
    } else {
      // For other links, use external browser
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
