import { AppColors, AppTypography, AppImages } from '../../resources/AppResources';
import lottie, { AnimationItem } from '@ohos/lottie';

@Component
export struct HeroTopRowComp {
  @Prop dateLabel: ResourceStr = $r('app.string.health_demo_date');
  onLongPress?: () => void;
  private lottieCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private lottieItem: AnimationItem | null = null;
  private lottieLoaded: boolean = false;

  aboutToDisappear(): void {
    lottie.destroy();
    this.lottieLoaded = false;
  }

  build() {
    Row() {
      Column() {
        Text(this.dateLabel).fontSize(AppTypography.CAPTION).fontColor(AppColors.HEALTH_DATE)
        Text($r('app.string.health_today')).fontSize(AppTypography.HERO_TITLE).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Image(AppImages.calendar()).width(23).height(23).objectFit(ImageFit.Contain)
      Blank().width(18)
      Canvas(this.lottieCanvasCtx)
        .width(30).height(30)
        .backgroundColor(AppColors.TRANSPARENT)
        .onReady(() => {
          if (this.lottieItem !== null) {
            this.lottieItem.destroy('lottieWatch');
          }
          this.lottieCanvasCtx.imageSmoothingEnabled = true;
          this.lottieCanvasCtx.imageSmoothingQuality = 'medium';
          this.lottieItem = lottie.loadAnimation({
            container: this.lottieCanvasCtx,
            renderer: 'canvas',
            loop: false,
            autoplay: false,
            name: 'lottieWatch',
            path: 'common/watch_status.json',
          });
          this.lottieItem.addEventListener('DOMLoaded', () => {
            this.lottieLoaded = true;
          });
          this.lottieItem.addEventListener('complete', () => {
            this.lottieItem?.goToAndStop(0, true);
          });
        })
        .gesture(LongPressGesture().onAction(() => { if (this.onLongPress) this.onLongPress(); }))
    }
    .width('100%').padding({ left: 20, right: 20, top: 32 })
  }
}
