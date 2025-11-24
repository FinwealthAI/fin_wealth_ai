import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TextParser {
  static List<TextSpan> parseMixedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp tagRegex = RegExp(r'<b>(.*?)</b>');
    int currentIndex = 0;

    for (final match in tagRegex.allMatches(text)) {
      // Add text before the tag
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        );
      }

      // Add the bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text after the last tag
    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      );
    }

    // If no tags were found, return the entire text as normal
    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      );
    }

    return spans;
  }

  static Widget buildRichText(String text, {TextStyle? baseStyle}) {
    // Nếu chuỗi có chứa HTML phức tạp (thẻ <table>, <tr>, <td>, <th>, <p>, ...)
    if (_containsComplexHtml(text)) {
      return Html(
        data: text,
        style: {
          "table": Style(
            border: const Border.fromBorderSide(BorderSide(color: Colors.black26)),
            width: Width.auto(),
          ),
          "tr": Style(
            border: const Border(bottom: BorderSide(color: Colors.black26)),
          ),
          "th": Style(
            padding: HtmlPaddings.all(8),
            backgroundColor: Colors.blueGrey.shade100,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          "td": Style(
            padding: HtmlPaddings.all(8),
            alignment: Alignment.centerLeft,
          ),
        },

      );
    }
    final spans = parseMixedText(text);
    
    // Apply base style by creating new TextSpan objects with merged styles
    final styledSpans = baseStyle != null
        ? spans.map((span) {
            return TextSpan(
              text: span.text,
              style: baseStyle.merge(span.style),
            );
          }).toList()
        : spans;

    return RichText(
      text: TextSpan(
        children: styledSpans,
      ),
    );
  }

  static bool _containsComplexHtml(String text) {
    return text.contains(RegExp(r'<(table|tr|td|th|p|div|span|html|body)[^>]*>', caseSensitive: false));
  }

  static bool containsHtmlTags(String text) {
    return text.contains(RegExp(r'<b>.*?</b>'));
  }
}
