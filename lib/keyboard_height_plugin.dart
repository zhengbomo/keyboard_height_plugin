import 'dart:async';
import 'package:flutter/services.dart';

typedef KeyboardHeightCallback = void Function(double height, Duration? duration);

class KeyboardHeightPlugin {
    static const EventChannel _keyboardHeightEventChannel = EventChannel('keyboardHeightEventChannel');

    StreamSubscription? _keyboardHeightSubscription;


    void onKeyboardHeightChanged(KeyboardHeightCallback callback) {
        if (_keyboardHeightSubscription != null) {
            _keyboardHeightSubscription!.cancel();
        }
        _keyboardHeightSubscription = _keyboardHeightEventChannel
        .receiveBroadcastStream()
        .listen((dynamic params) {
            if (params is Map<dynamic, dynamic>) {
                final keyboardHeight = params['keyboardHeight'];
                if (keyboardHeight is double) {
                    Duration? duration = null;
                    final dur = params['duration'];
                    if (dur is double) {
                        duration = Duration(milliseconds: (dur * 1000).toInt());
                    }
                    callback(keyboardHeight, duration);
                }
            } else if (params is double) {
                callback(params, null);
            }
        });
    }

    void dispose() {
        if (_keyboardHeightSubscription != null) {
            _keyboardHeightSubscription!.cancel();
        }
    }
}
