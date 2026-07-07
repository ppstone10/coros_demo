import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { init, setup } from '@kuiklybase/knoi';
import { initPersistence } from '../login/StorePersister';

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
    initKnoiBridge();
    initPersistence(this.context);
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
    windowStage.loadContent('pages/EntrancePage');
  }
}
