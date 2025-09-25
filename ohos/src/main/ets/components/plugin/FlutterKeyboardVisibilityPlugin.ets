/*
* Copyright (c) 2024 Hunan OpenValley Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import EventChannel, { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { AbilityAware, AbilityPluginBinding, BinaryMessenger, Log } from '@ohos/flutter_ohos';
import { common, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import FlutterManager from '@ohos/flutter_ohos/src/main/ets/embedding/ohos/FlutterManager';

const TAG = "KeyboardHeightPlugin";
/** KeyboardHeightPlugin **/
export default class KeyboardHeightPlugin implements FlutterPlugin, StreamHandler, AbilityAware {
  // private eventSink: EventSink | null = null;
  private isVisible: boolean = false;
  private context: common.Context | null = null;
  private window: window.Window | undefined = undefined;
  // private keyboardHeight: number = 0;
  constructor() {

  }

  getUniqueClassName(): string {
    return "KeyboardHeightPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.init(binding.getBinaryMessenger());
    this.context = binding.getApplicationContext();

  }

  private init(messenger: BinaryMessenger): void {
    const eventChannel = new EventChannel(messenger, "keyboardHeightEventChannel");
    eventChannel.setStreamHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
  }

  onDetachedFromAbility(): void {
    this.unregisterListener();
  }

  onListen(o: ESObject, eventSink: EventSink): void {
    // this.eventSink = eventSink;
    this.listenForKeyboard(eventSink);
  }

  onCancel(o: ESObject): void {
    // this.eventSink = null;
  }

  private async listenForKeyboard(eventSink: EventSink): Promise<void> {
    try {
      if(this.window == undefined) {
        const uiAbility = FlutterManager.getInstance().getUIAbility((getContext(this)));
        const windowStage = FlutterManager.getInstance().getWindowStage(uiAbility);
        this.window = windowStage.getMainWindowSync();
      }
      window.getLastWindow(getContext(this)).then(currentWindow => {
        currentWindow.on('keyboardHeightChange', (data: number) => {
          // this.keyboardHeight = px2vp(data);
         eventSink.success(px2vp(data));
        })
      })
      // this.window?.on("avoidAreaChange", (data) => {
      //   if (data.type == 3) {
      //     let newState = data.area.bottomRect.height > 0 ? true : false;
      //     if (newState != this.isVisible) {
      //       this.isVisible = newState;
      //       if (this.eventSink != null) {
      //         this.eventSink.success(this.isVisible ? 1 : 0);
      //       }
      //     }
      //   }
      // });

    } catch (err) {
      Log.e(TAG, "Failed to obtain the top window. Cause: " + JSON.stringify(err));
    }

  }

  private unregisterListener(): void {
    if(this.window != undefined) {
      this.window.off("keyboardHeightChange", (data) => {
        this.window = undefined;
      });
    }
  }
}