import Flutter
import UIKit

public class KeyboardHeightPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var eventChannel: FlutterEventChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = KeyboardHeightPlugin()
    instance.eventChannel = FlutterEventChannel(name: "keyboardHeightEventChannel", binaryMessenger: registrar.messenger())
    instance.eventChannel?.setStreamHandler(instance)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    registerKeyboardObservers()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    unregisterKeyboardObservers()
    return nil
  }

  private func registerKeyboardObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
  }

  private func unregisterKeyboardObservers() {
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
  }

  @objc private func keyboardWillShow(notification: NSNotification) {
    if let userInfo = notification.userInfo,
       let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
      var param: [String: Any] = [
        "keyboardHeight": keyboardFrame.height,
      ]
      if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
        param["duration"] = duration
      }
      eventSink?(param)
    }
  }

  @objc private func keyboardWillHide(notification: NSNotification) {
    if let userInfo = notification.userInfo {
      var param: [String: Any] = [
        "keyboardHeight": 0,
      ]
      if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
        param["duration"] = duration
      }
      eventSink?(param)
    }
  }
    
  @objc private func keyboardWillChangeFrame(notification: NSNotification) {
    if let userInfo = notification.userInfo,
       let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
      var param: [String: Any] = [
        "keyboardHeight": keyboardFrame.height,
      ]
      if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
        param["duration"] = duration
      }
      eventSink?(param)
    }
  }
}

