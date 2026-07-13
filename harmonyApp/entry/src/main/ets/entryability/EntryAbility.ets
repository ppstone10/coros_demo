import hilog from '@ohos.hilog';
import UIAbility from '@ohos.app.ability.UIAbility';
import { BusinessError } from '@ohos.base';
import window from '@ohos.window';
import { init, setup } from '@kuiklybase/knoi';
import { initPersistence, saveStoreSnapshot } from '../login/StorePersister';
import { getService } from '../login/HarmonyServiceProvider';

let knoiInitialized: boolean = false;

function initKnoiBridge(): void {
  if (knoiInitialized) {
    return;
  }
  setup('libkn.so', false);
  init();
  knoiInitialized = true;
}

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0001, 'demo_persist', 'onWindowStageCreate');
    initKnoiBridge();
    hilog.info(0x0001, 'demo_persist', 'initKnoiBridge done');
    windowStage.getMainWindow()
      .then((mainWindow: window.Window) => {
        mainWindow.setWindowBackgroundColor('#000000');
        return mainWindow.setWindowLayoutFullScreen(true)
          .then(() => {
            return mainWindow.setWindowSystemBarProperties({
              statusBarColor: '#00000000',
              navigationBarColor: '#00000000',
              isStatusBarLightIcon: true,
              isNavigationBarLightIcon: true,
              statusBarContentColor: '#FFFFFF',
              navigationBarContentColor: '#FFFFFF'
            });
          });
      })
      .catch(() => {
        console.error('configure immersive window failed');
      });

    initPersistence(this.context)
      .then(() => {
        this.loadStartContent(windowStage);
      })
      .catch((error: BusinessError) => {
        console.error('restore login state failed: ' + error.message);
        this.loadStartContent(windowStage);
      });
  }

  onForeground(): void {
    hilog.info(0x0001, 'demo_persist', 'onForeground');
  }

  onBackground(): void {
    hilog.info(0x0001, 'demo_persist', 'onBackground');
    getService().pauseSession();
    this.persistCurrentLoginStore('background');
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0001, 'demo_persist', 'onWindowStageDestroy');
    this.persistCurrentLoginStore('window stage destroy');
  }

  onDestroy(): void {
    hilog.info(0x0001, 'demo_persist', 'onDestroy');
    this.persistCurrentLoginStore('destroy');
  }

  private loadStartContent(windowStage: window.WindowStage): void {
    try {
      windowStage.loadContent('pages/EntrancePage');
    } catch (error) {
      console.error('load content failed: ' + error);
    }
  }

  private persistCurrentLoginStore(reason: string): void {
    if (!saveStoreSnapshot()) {
      console.error('persist login state on ' + reason + ' failed');
    }
  }
}
