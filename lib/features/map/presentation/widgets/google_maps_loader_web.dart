import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
external JSObject get window;

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
