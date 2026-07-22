import { AppColors, AppTypography, AppImages } from '../../resources/AppResources';
import { HealthCardModel, HealthChartPointData, HealthMetricData, SleepStageData, localizedHealthText } from '../HealthDashboardTypes';

@Component
export struct DashboardCardComp {
  @Prop card: HealthCardModel;
  onTap?: () => void;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private minimumCardHeight(): number {
    if (this.card.status === 'Empty') return 82;
    if (this.card.visual.kind === 'TodayActivity') return 114;
    if (this.card.visual.kind === 'WeeklyPlan') return 178;
    if (this.card.visual.kind === 'TrainingAssessment') return 206;
    if (this.card.visual.kind === 'HealthCheckGrid') return 180;
    if (this.card.visual.kind === 'BodyMap') return 188;
    return 122;
  }

  @Builder Header() {
    Row() {
      Image(this.card.id === 'TodayActivity' ? AppImages.todayHeader() : AppImages.healthCardIcon(this.card.id)).width(20).height(20).objectFit(ImageFit.Contain)
      Blank().width(5)
      Text(this.card.title).fontSize(16).fontColor(AppColors.HEALTH_CARD_TITLE).fontWeight(FontWeight.Medium).maxLines(1)
      Blank()
    }.width('100%').height(24)
  }

  @Builder Metric(metric: HealthMetricData, accent: ResourceColor = AppColors.WHITE) {
    Column({ space: 1 }) {
      Row() {
        Text(metric.value).fontSize(30).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(accent)
        if (metric.unitKey) { Text(this.text(metric.unitKey)).fontSize(16).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
      }
      Text(this.text(metric.labelKey)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
    }.alignItems(HorizontalAlign.Start)
  }

  private barColor(point: HealthChartPointData, index: number): ResourceColor {
    if (this.card.visual.kind === 'TrainingLoad') return AppColors.VISUAL_CYAN;
    if (index === this.card.visual.highlightedIndex) return AppColors.VISUAL_GREEN;
    if (point.level === 'High') return AppColors.HEALTH_WARNING;
    if (point.level === 'Elevated') return AppColors.VISUAL_ORANGE;
    if (point.level === 'Good') return AppColors.VISUAL_YELLOW;
    return AppColors.VISUAL_BAR;
  }

  private barHeight(point: HealthChartPointData): number {
    let high: number = 1;
    this.card.visual.chartPoints.forEach((item: HealthChartPointData) => { if (item.value > high) high = item.value; });
    return point.value <= 0 ? 2 : Math.max(3, Math.round(58 * point.value / high));
  }

  @Builder Bars(widthValue: number = 130, heightValue: number = 54) {
    Row({ space: 5 }) {
      ForEach(this.card.visual.chartPoints, (point: HealthChartPointData, index: number) => {
        Column() { Blank() }
          .height(this.barHeight(point)).layoutWeight(1).backgroundColor(this.barColor(point, index)).borderRadius(5)
      })
    }.height(heightValue).width(widthValue).alignItems(VerticalAlign.Bottom).clip(true)
  }

  @Builder Visual() {
    if (this.card.visual.kind === 'TodayActivity') {
      Row({ space: 12 }) {
        Image(AppImages.activityMap()).width(48).height(48).objectFit(ImageFit.Cover).borderRadius(6)
        Column({ space: 0 }) {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(24).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
            Text(this.text(this.card.visual.primaryUnitKey)).fontSize(16).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
          }
          Row({ space: 3 }) {
            Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
            Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Image(AppImages.todayRunner()).width(24).height(24).objectFit(ImageFit.Contain)
      }.width('100%').height(56).alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'WeeklyPlan') {
      Column({ space: 8 }) {
        Row() {
          ForEach(this.card.visual.chartPoints.slice(0, 7), (point: HealthChartPointData, index: number) => {
            Text(this.text(point.label)).fontSize(14).fontColor(index === this.card.visual.highlightedIndex ? AppColors.WHITE : AppColors.MUTED)
              .width(28).height(28).textAlign(TextAlign.Center)
              .backgroundColor(index === this.card.visual.highlightedIndex ? AppColors.ACTION : AppColors.TRANSPARENT).borderRadius(14)
            if (index < 6) { Blank() }
          })
        }.width('100%')
        Row({ space: 8 }) {
          Image(AppImages.todayRunner()).width(20).height(20).objectFit(ImageFit.Contain)
          Column({ space: 2 }) {
            Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(14).fontColor(AppColors.WHITE).maxLines(1)
            Row() {
              Text(this.card.visual.primaryValue || '--').fontSize(12).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE)
              Text(this.text(this.card.visual.primaryUnitKey)).fontSize(12).fontFamily('COROSAPPBold').fontColor(AppColors.MUTED).margin({ left: 2 })
            }
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Blank()
          this.Bars(80, 36)
        }.width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor(AppColors.ACTIVITY_TILE).borderRadius(6)
      }
    } else if (this.card.visual.kind === 'TrainingLoad' || this.card.visual.kind === 'TrendBars') {
      Row() {
        Column() {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
            if (this.card.visual.primaryUnitKey) { Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
          }
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start)
        Blank()
        this.Bars(this.card.visual.kind === 'TrendBars' ? 166 : 130, this.card.visual.kind === 'TrendBars' ? 56 : 54)
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'TrainingAssessment') {
      Column({ space: 4 }) {
        Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(20).fontColor(AppColors.VISUAL_ORANGE).fontWeight(FontWeight.Medium)
        Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE).maxLines(2)
        Blank()
        Row() {
          ForEach(this.card.visual.metrics.slice(0, 3), (metric: HealthMetricData, index: number) => {
            this.Metric(metric)
            if (index < 2) { Blank(); Divider().vertical(true).height(42).color(AppColors.DIVIDER); Blank() }
          })
        }.width('100%')
      }.alignItems(HorizontalAlign.Start)
    } else if (this.card.visual.kind === 'RecoveryGauge' || this.card.visual.kind === 'AbilityGauge') {
      Row() {
        Column({ space: 0 }) {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
            if (this.card.visual.primaryUnitKey) { Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
          }
          Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 0 }) {
          Gauge({ value: (this.card.visual.progress || 0) * 100, min: 0, max: 100 })
            .startAngle(-90).endAngle(90).colors(AppColors.VISUAL_CYAN).strokeWidth(4).width(114).height(58)
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(130).alignItems(HorizontalAlign.Center).clip(true)
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'RangeIndicator') {
      Row() {
        Column({ space: 0 }) {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
            if (this.card.visual.primaryUnitKey) { Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
          }
          Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 5 }) {
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
          Stack({ alignContent: Alignment.Start }) {
            Row().height(4).width(130).backgroundColor(AppColors.RANGE_TRACK).borderRadius(2)
            Row().height(4).width(46).margin({ left: 45 }).backgroundColor(AppColors.VISUAL_GREEN).borderRadius(2)
          }.height(14).width(130)
        }.width(130).clip(true)
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'SleepStages') {
      Row() {
        Column({ space: 0 }) {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
            Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT)
            Text(this.card.visual.secondaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE).margin({ left: 5 })
            Text(this.text(this.card.visual.secondaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT)
          }
          Text((this.card.visual.startTime || '--') + ' – ' + (this.card.visual.endTime || '--')).fontSize(12).fontColor(AppColors.MUTED)
        }.width(141).alignItems(HorizontalAlign.Start)
        Blank()
        Row({ space: 2 }) {
          ForEach(this.card.visual.sleepStages, (stage: SleepStageData) => {
            Row().height(7).layoutWeight(Math.max(1, stage.durationMinutes))
              .margin({ top: stage.stage === 'Awake' ? 0 : stage.stage === 'Rem' ? 16 : stage.stage === 'Deep' ? 48 : 32 })
              .backgroundColor(stage.stage === 'Awake' ? AppColors.VISUAL_ORANGE : stage.stage === 'Rem' ? AppColors.VISUAL_PURPLE : stage.stage === 'Deep' ? AppColors.VISUAL_DEEP_BLUE : AppColors.VISUAL_BLUE).borderRadius(2)
          })
        }.width(130).height(56).alignItems(VerticalAlign.Top).clip(true)
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'HealthCheckGrid') {
      Column({ space: 7 }) {
        Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(10).fontColor(AppColors.MUTED)
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.card.visual.metrics, (metric: HealthMetricData) => { Column() { this.Metric(metric) }.width('31%').margin({ bottom: 7 }) })
        }.width('100%')
      }.alignItems(HorizontalAlign.Start)
    } else if (this.card.visual.kind === 'BodyMap') {
      Row() {
        Column({ space: 4 }) {
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE)
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
            Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
          }
          Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED)
        }.width(141).alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 0 }) {
          Row({ space: 4 }) {
            Image(AppImages.bodyFront()).width(52).height(108).objectFit(ImageFit.Contain)
            Image(AppImages.bodyBack()).width(52).height(108).objectFit(ImageFit.Contain)
          }
          Row({ space: 3 }) {
            ForEach(this.card.visual.metrics.slice(0, 2), (metric: HealthMetricData, index: number) => {
              if (index > 0) { Text('·').fontSize(11).fontColor(AppColors.MUTED) }
              Text(this.text(metric.labelKey)).fontSize(11).fontColor(AppColors.MUTED).maxLines(1)
            })
          }
        }.width(142).alignItems(HorizontalAlign.Center).clip(true)
      }.width('100%').alignItems(VerticalAlign.Center)
    }
  }

  build() {
    Row() {
      Column({ space: this.card.status === 'Empty' ? 12 : 8 }) {
        this.Header()
        if (this.card.status === 'Empty') {
          Text(this.card.summary).fontSize(14).lineHeight(18).fontColor(AppColors.MUTED)
        } else { this.Visual() }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .constraintSize({ minHeight: this.minimumCardHeight() })
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(AppColors.HEALTH_CARD).borderRadius(8).clip(true)
      .onClick(() => { if (this.onTap) { this.onTap(); } })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
  }
}
