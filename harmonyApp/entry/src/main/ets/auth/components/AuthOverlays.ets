import {
  COROS_WHITE,
  COROS_BLACK,
  COROS_LEGAL_TEXT
} from './AuthColors';
import { LegalParagraph } from './LegalContent';
import { AppColors } from '../../core/resources/AppResources';

// ========== 全屏遮罩/整页展示组件（无回调业务状态，安全） ==========

@Builder
export function BlockingLoadingOverlay() {
  Column() {
    Blank().layoutWeight(1)
    LoadingProgress()
      .width(36)
      .height(36)
      .color(AppColors.AUTH_INPUT_TEXT)
      .padding(30)
      .backgroundColor(AppColors.AUTH_LOADING)
      .borderRadius(8)
    Blank().layoutWeight(1)
  }
  .width('100%')
  .height('100%')
  .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
}

@Builder
export function LegalDocumentPage(title: string, paragraphs: LegalParagraph[], backRequested: () => void) {
  Column() {
    Stack() {
      Row() {
        Text('‹')
          .fontSize(44)
          .fontColor(COROS_WHITE)
          .textAlign(TextAlign.Center)
          .width(48)
          .height(52)
          .onClick(() => { backRequested(); })
        Blank()
      }
      .width('100%')
      .height(52)

      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COROS_WHITE)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })

    Scroll() {
      Column({ space: 12 }) {
        ForEach(paragraphs, (paragraph: LegalParagraph) => {
          Text(paragraph.text)
            .fontSize(paragraph.isHeading ? 19 : 18)
            .fontWeight(paragraph.isHeading ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(paragraph.isHeading ? COROS_WHITE : COROS_LEGAL_TEXT)
            .lineHeight(paragraph.isHeading ? 28 : 30)
        }, (paragraph: LegalParagraph) => paragraph.text)
      }
      .width('100%')
      .padding({ top: 58, left: 20, right: 32, bottom: 32 })
    }
    .layoutWeight(1)
  }
  .width('100%')
  .height('100%')
  .backgroundColor(COROS_BLACK)
}
