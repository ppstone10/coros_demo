import { AppColors, AppImages } from '../../../core/resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct BodyManagementVisualComp {
  @Prop visual: HealthVisualData;
  onWeightTap: () => void = () => {};

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private bodyRegions(suffix: string): string[] {
    return (this.visual.highlightedBodyRegions || []).filter((region: string) => region.endsWith(suffix));
  }

  @Builder
  private BodyRegionLayer(region: string) {
    Image(AppImages.bodyMuscleRegion(region))
      .width(52)
      .height(108)
      .objectFit(ImageFit.Contain)
      .colorFilter(new ColorFilter([
        0, 0, 0, 0, 240 / 255,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 60 / 255,
        0, 0, 0, 1, 0
      ]))
  }

  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.text(this.visual.captionKey, this.visual.captionArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE)
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
          Text(this.text(this.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
          Image(AppImages.profileEdit()).width(16).height(16).objectFit(ImageFit.Contain).margin({ left: 6 })
        }
        .priorityGesture(
          TapGesture().onAction(() => { this.onWeightTap(); })
        )
        Text(this.text(this.visual.detailKey, this.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      Column({ space: 0 }) {
        Row({ space: 4 }) {
          Stack({ alignContent: Alignment.TopStart }) {
            Image(AppImages.bodyMaleFrontBase()).width(52).height(108).objectFit(ImageFit.Contain)
            ForEach(this.bodyRegions('_front'), (region: string) => {
              this.BodyRegionLayer(region)
            }, (region: string) => region)
          }
          .width(52).height(108)
          Stack({ alignContent: Alignment.TopStart }) {
            Image(AppImages.bodyMaleBackBase()).width(52).height(108).objectFit(ImageFit.Contain)
            ForEach(this.bodyRegions('_back'), (region: string) => {
              this.BodyRegionLayer(region)
            }, (region: string) => region)
          }
          .width(52).height(108)
        }
        .width(108).height(108)
        Text(this.text(this.visual.footerKey, this.visual.footerArgs))
          .fontSize(9).fontColor(AppColors.MUTED).maxLines(1)
      }.width(142).alignItems(HorizontalAlign.Center).clip(true)
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
