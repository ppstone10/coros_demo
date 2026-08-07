import {
  COROS_WHITE,
  COROS_MUTED,
  AUTH_TITLE_TOP_PADDING,
  AUTH_TITLE_SIZE
} from './AuthColors';

// ========== 品牌/页眉类组件（无状态，可安全复用） ==========

@Builder
export function AuthTitle(title: ResourceStr) {
  Text(title)
    .fontSize(AUTH_TITLE_SIZE)
    .fontWeight(FontWeight.Lighter)
    .fontColor(COROS_WHITE)
    .margin({ top: AUTH_TITLE_TOP_PADDING })
}

@Component
export struct AuthHeader {
  @Prop showBack: boolean = true;
  @Prop showFeedback: boolean = false;
  backRequested: () => void = () => {};
  feedbackRequested: () => void = () => {};

  build() {
    Row() {
      if (this.showBack) {
        Text($r('app.string.common_back'))
          .fontSize(44)
          .fontColor(COROS_WHITE)
          .width(48)
          .height(52)
          .textAlign(TextAlign.Start)
          .onClick(() => {
            this.getUIContext().getFocusController().clearFocus();
            this.backRequested();
          })
      }
      Blank()
      if (this.showFeedback) {
        Text($r('app.string.auth_feedback'))
          .fontSize(14)
          .fontColor(COROS_MUTED)
          .onClick(() => {
            this.getUIContext().getFocusController().clearFocus();
            this.feedbackRequested();
          })
      }
    }
    .width('100%')
    .height(52)
    .alignItems(VerticalAlign.Center)
  }
}
