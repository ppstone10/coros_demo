import { AppColors, AppTypography } from '../../resources/AppResources';

@Component
export struct MetricComp {
  @Prop icon: Resource;
  @Prop value: string;
  @Prop unit: ResourceStr;

  build() {
    Column({ space: 3 }) {
      Image(this.icon).width(22).height(22).objectFit(ImageFit.Contain)
      Text(this.value).fontSize(AppTypography.HERO_TITLE).fontColor(AppColors.WHITE)
      Text(this.unit).fontSize(AppTypography.CAPTION).fontColor(AppColors.HEALTH_METRIC_UNIT)
    }
    .width(82)
  }
}
