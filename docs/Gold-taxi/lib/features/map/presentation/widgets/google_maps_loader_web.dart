// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
external JSObject get window;

const _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
Completer<bool>? _loader;

bool isGoogleMapsInitialized() {
  try {
    if (window.hasProperty('google'.toJS).toDart) {
      final google = window.getProperty('google'.toJS);
      if (google != null && (google as JSObject).hasProperty('maps'.toJS).toDart) {
        return true;
      }
    }
  } catch (e) {
    // Fail-safe if JS environment behaves unexpectedly
  }
  return false;
}

Future<bool> ensureGoogleMapsInitialized() async {
  if (isGoogleMapsInitialized()) {
    return true;
  }
  if (_googleMapsApiKey.isEmpty) {
    return false;
  }
  if (_loader != null) {
    return _loader!.future;
  }

  final completer = Completer<bool>();
  _loader = completer;

  final script = html.ScriptElement()
    ..id = 'google-maps-js'
    ..async = true
    ..defer = true
    ..src = Uri.https(
      'maps.googleapis.com',
      '/maps/api/js',
      {
        'key': _googleMapsApiKey,
        'loading': 'async',
      },
    ).toString();

  script.onLoad.first.then((_) => completer.complete(isGoogleMapsInitialized()));
  script.onError.first.then((_) => completer.complete(false));
  html.document.head?.append(script);

  return completer.future;
}
