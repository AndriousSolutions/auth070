///
/// Copyright (C) 2019 Andrious Solutions
///
/// This program is free software; you can redistribute it and/or
/// modify it under the terms of the GNU General Public License
/// as published by the Free Software Foundation; either version 3
/// of the License, or any later version.
///
/// You may obtain a copy of the License at
///
///  http://www.apache.org/licenses/LICENSE-2.0
///
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///          Created  21 Mar 2019
///
///
import 'dart:async' show Future, Stream, StreamController;
import 'dart:io' show ContentType, HttpRequest, HttpServer, InternetAddress;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:flutter/material.dart' show required;

import 'package:http/http.dart' show Response, post;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart' show FlutterWebviewPlugin;
export 'package:auth070/src/signature_method.dart';
import 'package:auth070/src/signature_method.dart';
import 'package:prefs/prefs.dart' show Prefs;


class AuthUrl {
  AuthUrl(
      {this.url,
      this.body,
      this.headers,
      this.responseType = 'code',
      this.fullScreen = true,
      this.clearCookies = true});

  final String url;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
  final String responseType;
  final bool fullScreen;
  final bool clearCookies;
}

class OAuth {
  OAuth({
    this.authorize,
    this.token,
  });

  AuthUrl authorize;
  AuthUrl token;

  String code = '';
  Map<String, dynamic> tokens = {};

  bool get shouldRequestCode => code == null || code.isEmpty;

  final StreamController<String> onCodeListener = StreamController();

  final FlutterWebviewPlugin webView = FlutterWebviewPlugin();

  var isBrowserOpen = false;
  var server;
  var onCodeStream;

  Future<Map<String, dynamic>> performAuthorization() async {
    await requestCode(authorize);
    return getToken(token);
  }

  Future<void> requestCode(AuthUrl auth) async {
    if (auth.url == null || auth.url.isEmpty) return;
    if (auth.body == null && auth.headers == null) {
      code = await webLaunch(auth);
    } else {
      tokens = await getPost(auth);
    }
  }

  Future<Map<String, dynamic>> getToken(AuthUrl auth) async {
    if (auth.url == null || auth.url.isEmpty) return Future.value(tokens);
    if (auth.body == null && auth.headers == null) {
      code = await webLaunch(auth);
    } else {
      tokens = await getPost(auth);
    }
    return tokens;
  }

  Future<String> webLaunch(AuthUrl auth) async {
    if (shouldRequestCode && !isBrowserOpen) {
      isBrowserOpen = true;

      server = await createServer();

      listenForServerResponse(server);

      webView.onDestroy.first.then((_) {
        close();
      });

      String url = auth.url;

      if (tokens != null && tokens.containsKey(auth.responseType))
        url = "$url?${auth.responseType}=${tokens[auth.responseType]}";

      webView.launch(url,
          clearCookies: auth.clearCookies, withZoom: auth.fullScreen);

      code = await onCode.first;

      close();
    }
    return code;
  }

  Stream<String> get onCode =>
      onCodeStream ??= onCodeListener.stream.asBroadcastStream();

  void close() {
    if (isBrowserOpen) {
      server.close(force: true);
      webView.close();
    }
    isBrowserOpen = false;
  }

  Future<HttpServer> createServer() async {
    final server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 8080, shared: true);
    return server;
  }

  listenForServerResponse(HttpServer server) {
    server.listen((HttpRequest request) async {
      final uri = request.uri;
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.html.mimeType);

      final code = uri.queryParameters["code"];
      final error = uri.queryParameters["error"];
      await request.response.close();
      if (code != null && error == null) {
        onCodeListener.add(code);
      } else if (error != null) {
        onCodeListener.add(null);
        onCodeListener.addError(error);
      }
    });
  }

  Future<Map<String, dynamic>> getPost(AuthUrl auth) async {
    if (code != null && code.isNotEmpty)
      auth.body.addAll({"${auth.responseType}": code});

    Response response;
    Map<String, dynamic> params;

    if (auth.body == null) {
      response = await post(auth.url, headers: auth.headers);
    } else {
      response = await post(auth.url,
          body: jsonEncode(auth.body), headers: auth.headers);
    }

    if (auth.headers != null &&
        auth.headers.containsKey('Content-Type') &&
        auth.headers['Content-Type'] == 'application/json') {
      params = jsonDecode(response.body);
    } else {
      params = Uri.splitQueryString(response.body);
//      if (params['oauth_callback_confirmed'].toLowerCase() != 'true') {
//        throw new StateError("oauth_callback_confirmed must be true");
//      }
    }
    return params;
  }

  /// Recreate an 'OAuth' header
  static Map<String, String> header({
    @required String secret,
    @required String url,
    @required Map<String, String> header,
  }) {
    return {'Authorization': _oAuthHeader('POST', secret, url, header)};
  }

  static String _oAuthHeader(
      String _method, String secret, String _url, Map<String, String> params) {
    params['oauth_signature'] = _createSignature(_method, secret, _url, params);

    return 'OAuth ' +
        params.keys.map((k) {
          return '$k="${Uri.encodeComponent(params[k])}"';
        }).join(', ');
  }

  ///
  /// Create signature in ways referred from
  ///   https://dev.twitter.com/docs/auth/creating-signature.
  ///
  static String _createSignature(
      String method, String secret, String url, Map<String, String> params) {
    if (params.isEmpty) {
      throw new ArgumentError("params is empty.");
    }
    Uri uri = Uri.parse(url);

    //
    // Collecting parameters
    //

    // 1. Percent encode every key and value
    //    that will be signed.
    Map<String, String> encodedParams = new Map<String, String>();

    params.forEach((k, v) {
      encodedParams[Uri.encodeComponent(k)] = Uri.encodeComponent(v);
    });

    uri.queryParameters.forEach((k, v) {
      encodedParams[Uri.encodeComponent(k)] = Uri.encodeComponent(v);
    });

    params.remove("realm");

    // 2. Sort the list of parameters alphabetically[1]
    //    by encoded key[2].
    List<String> sortedEncodedKeys = encodedParams.keys.toList()..sort();

    // 3. For each key/value pair:
    // 4. Append the encoded key to the output string.
    // 5. Append the '=' character to the output string.
    // 6. Append the encoded value to the output string.
    // 7. If there are more key/value pairs remaining,
    //    append a '&' character to the output string.
    String baseParams = sortedEncodedKeys.map((k) {
      return '$k=${encodedParams[k]}';
    }).join('&');

    //
    // Creating the signature base string
    //

    StringBuffer base = new StringBuffer();
    // 1. Convert the HTTP Method to uppercase and set the
    //    output string equal to this value.
    base.write(method.toUpperCase());

    // 2. Append the '&' character to the output string.
    base.write('&');

    // 3. Percent encode the URL origin and path, and append it to the
    //    output string.
    base.write(Uri.encodeComponent(uri.origin + uri.path));

    // 4. Append the '&' character to the output string.
    base.write('&');

    // 5. Percent encode the parameter string and append it
    //    to the output string.
    base.write(Uri.encodeComponent(baseParams.toString()));

    //
    // Getting a signing key
    //

    // The signing key is simply the percent encoded consumer
    // secret, followed by an ampersand character '&',
    // followed by the percent encoded token secret:
    String consumerSecret = Uri.encodeComponent(secret);

//    String tokenSecret = _credentials != null
//        ? Uri.encodeComponent(_credentials.tokenSecret)
//        : "";
    String tokenSecret = "";

    String signingKey = "$consumerSecret&$tokenSecret";

    //
    // Calculating the signature
    //
    return SignatureMethods.HMAC_SHA1.sign(signingKey, base.toString());
  }

  static Future<String> get(String platform, String value) async {
//use this    larKey;
    String id = _Keys.get(platform)[value];
    Prefs.setString(platform + value, trim(id));
    return Future.value(id);
  }
}

class _Keys {
  static Map<String, String> get(String platform) {
    Map<String, String> keys;

    switch (platform) {
      case 'Facebook':
        {
          keys = {
            'id': '629273300857569',
            'secret': 'd3e41a0547f4516e886e5f5369d56555'
          };
          break;
        }
      case 'Github':
        {
          keys ={
            'id': '66e5e1f9d32314f75593',
            'secret': '5d0ae11332e75810f37f14a706833a1d43b0e8c9'
          };
          break;
        }
      case 'Twitter':
        {
          keys = {
            'id': 'zl9ixhxd09NxjyEsI5JlDZAk9',
            'secret': 'rEx8Dyz2aGWixZiQb6SBcBWeRd3FrkIPy4fyw4jREDeTW2bIhk'
          };
          break;
        }

      case 'Instagram':
        {
          keys = {
            'id': 'c62ffcf0fa204229ad58d9c65a16c92a',
            'secret': 'd3e41a0547f4516e886e5f5369d56555'
          };
          break;
        }

      default:
        {
          keys = {
            'id': '123456789012345',
            'secret': '2f1ff78f4ff7452af1fff882f925b9ff'
          };
        }
    }
    return keys;
  }
}
