/* license: https://mit-license.org
 *
 *  Cryptography
 *
 *                               Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * =============================================================================
 */


abstract class Template {

  ///  Replace all '{key}' in the template with value
  static String replace(String template, String key, String value) =>
      template.replaceAll(RegExp('\\{$key\\}'), value);

  //
  //  URL
  //

  static String getQueryString(String url) {
    String text = url;
    int pos;
    // cut head: 'scheme://domain/path?'
    pos = text.indexOf('?');
    if (pos < 0) {
      // assert(false, 'query string not found: $url');
    } else {
      assert(pos > 0, 'URL error: $url');
      text = text.substring(pos + 1);
    }
    // cut tail: '#fragment'
    pos = text.indexOf('#');
    if (pos < 0) {
      // assert(false, 'fragment not found: $url');
    } else {
      assert(pos > 0, 'URL error: $url');
      text = text.substring(0, pos);
    }
    return text;
  }

  static String? getQueryParam(String url, String key) {
    // cut head & tail
    String text = getQueryString(url);
    // split query pairs
    List<String> pairs = text.split('&');
    int pos;
    for (String item in pairs) {
      pos = item.indexOf('=');
      // check key
      if (pos > 0 && item.substring(0, pos) == key) {
        // key matched, decode value
        return Uri.decodeComponent(item.substring(pos + 1));
      }
    }
    return null;
  }

  static Map<String, String> getQueryParams(String url) {
    Map<String, String> params = {};
    // cut head & tail
    String text = getQueryString(url);
    // split query pairs
    List<String> pairs = text.split('&');
    int pos;
    String key, value;
    for (String item in pairs) {
      pos = item.indexOf('=');
      if (pos > 0) {
        key = item.substring(0, pos);
        value = item.substring(pos + 1);
        params[key] = Uri.decodeComponent(value);
      }
    }
    return params;
  }

  static String replaceQueryParam(String url, String key, String value) {
    // seeking '?key='
    int pos = url.indexOf('?$key=');
    if (pos < 0) {
      // seeking '&key='
      pos = url.indexOf('&$key=');
    }
    if (pos > 0) {
      // param found, update its value
      return _updateValue(url, pos + 2 + key.length, value);
    }
    // param not exists,
    // append a new one to the tail
    String param = url.contains('?') ? '&$key=$value' : '?$key=$value';
    pos = url.indexOf('#');
    if (pos < 0) {
      return '$url$param';
    }
    String prefix = url.substring(0, pos);
    String suffix = url.substring(pos);
    return '$prefix$param$suffix';
  }
  static String _updateValue(String url, int start, String value) {
    String prefix, suffix;
    int end;
    if (start < url.length) {
      prefix = url.substring(0, start);
      end = url.indexOf('&', start);
      if (end < 0) {
        end = url.indexOf('#');
      }
    } else {
      prefix = url;
      end = -1;
    }
    if (end < 0) {
      return '$prefix$value';
    }
    suffix = url.substring(end);
    return '$prefix$value$suffix';
  }

}
