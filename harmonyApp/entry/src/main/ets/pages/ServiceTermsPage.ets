import router from '@ohos.router';
import { COROS_BLACK, COROS_WHITE } from '../login/components/AuthColors';
import { LegalParagraph, SERVICE_TERMS_PARAGRAPHS } from '../login/components/LegalContent';
import { LegalDocumentParams } from '../login/AuthRoutes';
import { navigate, NavOperation } from '../login/AuthNavigator';

@Entry
@Component
struct ServiceTermsPage {
  @State title: string = '服务条款';
  private returnPage: string = '';

  aboutToAppear(): void {
    let params = router.getParams() as LegalDocumentParams;
    if (params !== null && params !== undefined && params.returnPage !== undefined) {
      this.returnPage = params.returnPage;
    }
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Column() {
      Stack() {
        Row() {
          Text('‹')
            .fontSize(44)
            .fontColor(COROS_WHITE)
            .textAlign(TextAlign.Center)
            .width(48)
            .height(52)
            .onClick(() => { navigate(NavOperation.Pop, ''); })
          Blank()
        }
        .width('100%')
        .height(52)

        Text(this.title)
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
          ForEach(SERVICE_TERMS_PARAGRAPHS, (paragraph: LegalParagraph) => {
            Text(paragraph.text)
              .fontSize(paragraph.isHeading ? 19 : 18)
              .fontWeight(paragraph.isHeading ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(paragraph.isHeading ? COROS_WHITE : '#C9C9CC')
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
}
