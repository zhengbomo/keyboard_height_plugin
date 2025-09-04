package com.nschairer.keyboard_height_plugin
import android.graphics.Rect
import android.os.Build
import androidx.annotation.NonNull
import android.view.ViewTreeObserver
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class KeyboardHeightPlugin : FlutterPlugin, EventChannel.StreamHandler, ActivityAware {
    private val keyboardHeightEventChannelName = "keyboardHeightEventChannel"
    private var eventSink: EventChannel.EventSink? = null
    private var eventChannel: EventChannel? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var keyboardAnimationDuration: Long? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, keyboardHeightEventChannelName)
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel?.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val rootView = activityPluginBinding?.activity?.window?.decorView?.rootView
        
        // Android 11+ uses WindowInsetsAnimation to listen for keyboard animations
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && rootView != null) {
            setupWindowInsetsAnimation(rootView, events)
        }
        
        // Keep the original layout listener as a fallback
        rootView?.viewTreeObserver?.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                val r = Rect()
                rootView.getWindowVisibleDisplayFrame(r)

                val screenHeight = rootView.height
                val navigationBarHeight = getNavigationBarHeight();
                var keypadHeight = screenHeight - r.bottom
                if (isNavigationBarVisible()) {
                    keypadHeight -= navigationBarHeight
                }
                val displayMetrics = activityPluginBinding?.activity?.resources?.displayMetrics
                val logicalKeypadHeight = keypadHeight / (displayMetrics?.density ?: 1f)

                // Build the result Map
                val result = mutableMapOf<String, Any>()
                
                if (keypadHeight > screenHeight * 0.15) {
                    result["keyboardHeight"] = logicalKeypadHeight.toDouble()
                } else {
                    result["keyboardHeight"] = 0.0
                }
                
                // Add animation duration (Android 11+ only)
                keyboardAnimationDuration?.let {
                    result["duration"] = it.toDouble() / 1000.0 // Convert to seconds
                }
                
                events?.success(result)
            }
        })
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun getNavigationBarHeight(): Int {
        val resourceId = activityPluginBinding?.activity?.resources?.getIdentifier("navigation_bar_height", "dimen", "android")
        return if (resourceId != null && resourceId > 0) {
            activityPluginBinding?.activity?.resources?.getDimensionPixelSize(resourceId) ?: 0
        } else {
            0
        }
    }

    private fun isNavigationBarVisible(): Boolean {
        val decorView = activityPluginBinding?.activity?.window?.decorView
        val rootWindowInsets = decorView?.rootWindowInsets ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            rootWindowInsets.isVisible(android.view.WindowInsets.Type.navigationBars())
        } else {
            val systemWindowInsetBottom = rootWindowInsets.systemWindowInsetBottom
            systemWindowInsetBottom > 0
        }
    }
    
    @RequiresApi(Build.VERSION_CODES.R)
    private fun setupWindowInsetsAnimation(rootView: android.view.View, events: EventChannel.EventSink?) {
        rootView.setWindowInsetsAnimationCallback(object : WindowInsetsAnimation.Callback(DISPATCH_MODE_STOP) {
            override fun onProgress(
                insets: WindowInsets,
                runningAnimations: MutableList<WindowInsetsAnimation>
            ): WindowInsets {
                return insets
            }
            
            override fun onPrepare(animation: WindowInsetsAnimation) {
                super.onPrepare(animation)
                // Check if it's a keyboard (IME) animation
                if (animation.typeMask and WindowInsets.Type.ime() != 0) {
                    // Get animation duration in milliseconds
                    keyboardAnimationDuration = animation.durationMillis
                }
            }
            
            override fun onEnd(animation: WindowInsetsAnimation) {
                super.onEnd(animation)
                // Clear duration after animation ends
                if (animation.typeMask and WindowInsets.Type.ime() != 0) {
                    keyboardAnimationDuration = null
                }
            }
        })
    }
    
    // Implement ActivityAware methods
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityPluginBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityPluginBinding = null
    }
}
