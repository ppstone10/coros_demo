import { AppColors } from '../core/resources/AppResources';
import {
  APP_LANGUAGE_CHINESE,
  APP_LANGUAGE_ENGLISH
} from '../core/resources/AppLanguage';

// ========== 首页弹窗（无状态，回调交给页面处理） ==========

@Component
export struct DeleteAccountDialog {
  onCancel: () => void = () => {};
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 24 }) {
        Text($r('app.string.account_delete_confirmation')).fontSize(18).fontColor(AppColors.WHITE).textAlign(TextAlign.Center)
        Row({ space: 14 }) {
          Button($r('app.string.common_cancel'), { type: ButtonType.Normal }).fontSize(16).fontColor(AppColors.WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor(AppColors.ACCOUNT_DIALOG_SECONDARY)
            .onClick(() => { this.onCancel(); })
          Button($r('app.string.common_confirm'), { type: ButtonType.Normal }).fontSize(16).fontColor(AppColors.WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor(AppColors.ACTION)
            .onClick(() => { this.onConfirm(); })
        }
      }
      .padding({ left: 24, right: 24, top: 22, bottom: 22 })
      .backgroundColor(AppColors.ACCOUNT_DIALOG).borderRadius(12).margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(AppColors.OVERLAY_62)
  }
}

@Component
export struct KickedDialog {
  onConfirmed: () => void = () => {};

  build() {
    Column() {
      Column({ space: 20 }) {
        Text($r('app.string.auth_error_session_expired_elsewhere'))
          .fontSize(17).fontColor(AppColors.WHITE).textAlign(TextAlign.Center).width('100%')
        Button($r('app.string.common_confirm'), { type: ButtonType.Normal })
          .fontSize(16).fontColor(AppColors.WHITE)
          .width('100%').height(44).borderRadius(8).backgroundColor(AppColors.ACTION)
          .onClick(() => { this.onConfirmed(); })
      }
      .width(300)
      .padding({ left: 22, right: 22, top: 24, bottom: 20 })
      .backgroundColor(AppColors.ACCOUNT_DIALOG).borderRadius(14)
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.OVERLAY_62)
  }
}

@Component
export struct LanguageDialog {
  @Prop appLanguage: string = '';
  onDismiss: () => void = () => {};
  onLanguageSelected: (language: string) => void = (_: string) => {};

  @Builder
  LanguageOption(label: ResourceStr, language: string) {
    Row() {
      Text(label).fontSize(16).fontColor(AppColors.WHITE)
      Blank().layoutWeight(1)
      if (this.appLanguage === language) {
        Text('✓').fontSize(18).fontColor(AppColors.COMPLETE)
      }
    }
    .width('100%').height(52).padding({ left: 22, right: 22 })
    .onClick(() => {
      this.onLanguageSelected(language);
    })
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Text($r('app.string.language_select_title'))
          .fontSize(19).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 10 })
        this.LanguageOption($r('app.string.language_chinese'), APP_LANGUAGE_CHINESE);
        this.LanguageOption($r('app.string.language_english'), APP_LANGUAGE_ENGLISH);
      }
      .width('84%').padding({ bottom: 12 }).backgroundColor(AppColors.ACCOUNT_DIALOG).borderRadius(14)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(AppColors.OVERLAY_62)
  }
}
