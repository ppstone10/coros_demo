import { AppColors, AppTypography, AppImages } from '../../resources/AppResources';
import {
  HealthCardModel,
  HealthChartPointData,
  HealthMetricData,
  SleepStageData,
  WeeklyDayPlanData,
  localizedHealthText
} from '../HealthDashboardTypes';

@Component
export struct DashboardCardComp {
  @Prop card: HealthCardModel;
  onTap?: () => void;
  onWeeklyDaySelected?: (index: number) => void;
  @State selectedWeeklyDay: number = -1;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private contentMinimumHeight(): number {
    if (this.card.visual.kind === 'TodayActivity') return 58;
    if (this.card.visual.kind === 'WeeklyPlan') return 110;
    if (this.card.visual.kind === 'TrainingLoad') return 60;
    if (this.card.visual.kind === 'TrainingAssessment') return 130;
    if (this.card.visual.kind === 'RecoveryGauge' || this.card.visual.kind === 'AbilityGauge') return 78;
    if (this.card.visual.kind === 'TrendBars' ||
      this.card.visual.kind === 'RangeIndicator' ||
      this.card.visual.kind === 'SleepStages') return 60;
    if (this.card.visual.kind === 'HealthCheckGrid') return 114;
    if (this.card.visual.kind === 'BodyMap') return 121;
    return 0;
  }

  @Builder Header() {
    Row() {
      Image(this.card.id === 'TodayActivity' ? AppImages.todayHeader() : AppImages.healthCardIcon(this.card.id)).width(20).height(20).objectFit(ImageFit.Contain)
      Blank().width(5)
      Text(this.card.title).fontSize(16).fontColor(AppColors.HEALTH_CARD_TITLE).fontWeight(FontWeight.Medium).maxLines(1)
      Blank()
      if (this.card.id === 'HealthCheck' && this.card.visual.captionKey) {
        Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs))
          .fontSize(10).fontColor(AppColors.MUTED).maxLines(1)
      }
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

  private barColor(point: HealthChartPointData, index: number, highlightedIndex: number = -1): ResourceColor {
    if (this.card.visual.kind === 'TrainingLoad') return AppColors.VISUAL_CYAN;
    if (index === highlightedIndex) return AppColors.VISUAL_CYAN;
    if (index === this.card.visual.highlightedIndex) return AppColors.VISUAL_GREEN;
    if (point.level === 'High') return AppColors.HEALTH_WARNING;
    if (point.level === 'Elevated') return AppColors.VISUAL_ORANGE;
    if (point.level === 'Good') return AppColors.VISUAL_YELLOW;
    return AppColors.VISUAL_BAR;
  }

  private barHeight(point: HealthChartPointData, heightValue: number): number {
    let high: number = 1;
    this.card.visual.chartPoints.forEach((item: HealthChartPointData) => { if (item.value > high) high = item.value; });
    return point.value <= 0 ? 2 : Math.max(3, Math.round(heightValue * point.value / high));
  }

  private rangeFraction(): number {
    if (!this.card.visual.range) return 0.5;
    const range = this.card.visual.range;
    const width = Math.max(1, range.maximum - range.minimum);
    return Math.max(0, Math.min(1, (range.current - range.minimum) / width));
  }

  private rangeHeaderText(): string {
    if (this.card.id === 'RestingHeartRate') {
      return this.text(this.card.visual.detailKey, this.card.visual.detailArgs);
    }
    const range = this.card.visual.range;
    if (!range) return '';
    return this.text('health_visual_normal_range_short', [
      range.normalMin === undefined ? '--' : Math.round(range.normalMin).toString(),
      range.normalMax === undefined ? '--' : Math.round(range.normalMax).toString(),
      this.text(this.card.visual.primaryUnitKey)
    ]);
  }

  private weeklySelectedIndex(): number {
    if (this.selectedWeeklyDay >= 0) return Math.max(0, Math.min(6, this.selectedWeeklyDay));
    return Math.max(0, Math.min(6, this.card.visual.highlightedIndex || 0));
  }

  private weeklyPlan(): WeeklyDayPlanData | undefined {
    const selected: number = this.weeklySelectedIndex();
    return (this.card.visual.weeklyDayPlans || []).find((plan: WeeklyDayPlanData) => plan.dayIndex === selected);
  }

  private heartChartMinimum(): number {
    let result: number = Number.MAX_VALUE;
    this.card.visual.chartPoints.forEach((point: HealthChartPointData) => {
      result = Math.min(result, point.minimum === undefined ? point.value : point.minimum);
    });
    return result === Number.MAX_VALUE ? 0 : result;
  }

  private heartChartMaximum(): number {
    let result: number = -Number.MAX_VALUE;
    this.card.visual.chartPoints.forEach((point: HealthChartPointData) => {
      result = Math.max(result, point.maximum === undefined ? point.value : point.maximum);
    });
    return result === -Number.MAX_VALUE ? 1 : result;
  }

  private gaugeProgress(): number {
    return Math.max(0, Math.min(1, this.card.visual.progress || 0));
  }

  private gaugeArcPath(
    progress: number,
    centerXValue: number,
    centerYValue: number,
    radiusValue: number
  ): string {
    const centerX: number = vp2px(centerXValue);
    const centerY: number = vp2px(centerYValue);
    const radius: number = vp2px(radiusValue);
    const sweep: number = 180 * Math.max(0, Math.min(1, progress));
    const startRadians: number = Math.PI;
    const endRadians: number = (180 + sweep) * Math.PI / 180;
    const startX: number = centerX + radius * Math.cos(startRadians);
    const startY: number = centerY + radius * Math.sin(startRadians);
    const endX: number = centerX + radius * Math.cos(endRadians);
    const endY: number = centerY + radius * Math.sin(endRadians);
    return `M${startX} ${startY} A${radius} ${radius} 0 0 1 ${endX} ${endY}`;
  }

  private abilitySegmentPath(index: number): string {
    const centerX: number = vp2px(60.5);
    const centerY: number = vp2px(55);
    const radius: number = vp2px(48);
    const startDegrees: number = 180 + index * 6;
    const endDegrees: number = startDegrees + 4.08;
    const startRadians: number = startDegrees * Math.PI / 180;
    const endRadians: number = endDegrees * Math.PI / 180;
    return `M${centerX + radius * Math.cos(startRadians)} ${centerY + radius * Math.sin(startRadians)} ` +
      `A${radius} ${radius} 0 0 1 ${centerX + radius * Math.cos(endRadians)} ${centerY + radius * Math.sin(endRadians)}`;
  }

  private abilityNeedlePath(): string {
    const centerX: number = vp2px(60.5);
    const centerY: number = vp2px(55);
    const needleLength: number = vp2px(37);
    const angle: number = Math.PI + this.gaugeProgress() * Math.PI;
    return `M${centerX} ${centerY} ` +
      `L${centerX + Math.cos(angle) * needleLength} ${centerY + Math.sin(angle) * needleLength}`;
  }

  private rangeMarkerPath(): string {
    return `M${vp2px(4)} 0 L0 ${vp2px(7)} L${vp2px(8)} ${vp2px(7)} Z`;
  }

  private gaugeAccent(): ResourceColor {
    if (this.card.id === 'RunningAbility') return AppColors.VISUAL_ORANGE;
    if (this.card.id === 'CyclingAbility') return AppColors.VISUAL_GREEN;
    return AppColors.VISUAL_CYAN;
  }

  private stressBarIndexes(): number[] {
    const result: number[] = [];
    for (let index: number = 0; index < 83; index++) result.push(index);
    return result;
  }

  private stressValue(index: number): number {
    const values: HealthChartPointData[] = this.card.visual.chartPoints;
    if (values.length === 0) return 0;
    const position: number = index / 82 * Math.max(0, values.length - 1);
    const left: number = Math.max(0, Math.min(values.length - 1, Math.floor(position)));
    const right: number = Math.min(values.length - 1, left + 1);
    const fraction: number = position - left;
    return values[left].value + (values[right].value - values[left].value) * fraction;
  }

  private stressHeight(index: number): number {
    return Math.max(2, 56 * this.stressValue(index) / 100);
  }

  private stressColor(index: number): ResourceColor {
    const value: number = this.stressValue(index);
    if (value >= 80) return AppColors.VISUAL_ORANGE;
    if (value >= 60) return AppColors.VISUAL_YELLOW;
    if (value >= 35) return AppColors.STRESS_GOOD;
    return AppColors.STRESS_LOW;
  }

  private sleepTotalMinutes(): number {
    let total: number = 1;
    this.card.visual.sleepStages.forEach((stage: SleepStageData) => {
      total = Math.max(total, stage.startMinute + stage.durationMinutes);
    });
    return total;
  }

  private sleepStageTop(stage: SleepStageData): number {
    if (stage.stage === 'Awake') return 0;
    if (stage.stage === 'Rem') return 16;
    if (stage.stage === 'Deep') return 48;
    return 32;
  }

  private sleepStageColor(stage: SleepStageData): ResourceColor {
    if (stage.stage === 'Awake') return AppColors.VISUAL_YELLOW;
    if (stage.stage === 'Rem') return AppColors.VISUAL_CYAN;
    if (stage.stage === 'Deep') return AppColors.VISUAL_DEEP_BLUE;
    return AppColors.VISUAL_BLUE;
  }

  @Builder GaugeOverview() {
    if (this.card.id === 'Recovery') {
      Column({ space: 2 }) {
        Stack({ alignContent: Alignment.Top }) {
          Path()
            .commands(this.gaugeArcPath(1, 57, 55, 52))
            .width(114).height(58).fill(AppColors.TRANSPARENT)
            .stroke(AppColors.RANGE_TRACK).strokeWidth(4)
          if (this.gaugeProgress() > 0) {
            Path()
              .commands(this.gaugeArcPath(this.gaugeProgress(), 57, 55, 52))
              .width(114).height(58).fill(AppColors.TRANSPARENT)
              .stroke(AppColors.VISUAL_CYAN).strokeWidth(4)
          }
          Image(AppImages.recoveryStatus()).width(21).height(30).objectFit(ImageFit.Contain).margin({ top: 20 })
        }
        .width(114).height(58)
        Text(this.text(this.gaugeProgress() >= 0.7 ? 'health_visual_recovery_ready' : 'health_visual_recovery_low'))
          .fontSize(11).fontColor(AppColors.HEALTH_CARD_TITLE)
      }
      .width(114).height(78).alignItems(HorizontalAlign.Center)
    } else {
      Column({ space: 0 }) {
        Stack({ alignContent: Alignment.TopStart }) {
          ForEach([
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
            20, 21, 22, 23, 24, 25, 26, 27, 28, 29
          ], (index: number) => {
            Path()
              .commands(this.abilitySegmentPath(index))
              .width(121).height(60).fill(AppColors.TRANSPARENT)
              .stroke((index + 0.5) / 30 <= this.gaugeProgress() ? this.gaugeAccent() : AppColors.RANGE_TRACK)
              .strokeWidth(3)
          })
          Path()
            .commands(this.abilityNeedlePath())
            .width(121).height(60).fill(AppColors.TRANSPARENT)
            .stroke(AppColors.HEALTH_CARD_TITLE).strokeWidth(2)
          Circle().width(5).height(5).fill(AppColors.HEALTH_CARD_TITLE).margin({ left: 58, top: 52.5 })
        }
        .width(121).height(60)
        Row() {
          Text('0').fontSize(10).fontColor(AppColors.MUTED)
          Blank()
          Text('100').fontSize(10).fontColor(AppColors.MUTED)
        }
        .width(121)
      }
      .width(121).height(71)
    }
  }

  @Builder HeartRateIntervalOverview() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.card.visual.chartPoints, (point: HealthChartPointData, index: number) => {
        Row()
          .width(1)
          .height(Math.max(1, 38 *
            ((point.maximum === undefined ? point.value : point.maximum) -
              (point.minimum === undefined ? point.value : point.minimum)) /
            Math.max(1, this.heartChartMaximum() - this.heartChartMinimum())))
          .backgroundColor(AppColors.VISUAL_PINK)
          .margin({
            left: this.card.visual.chartPoints.length <= 1 ? 0 :
              index * 165 / (this.card.visual.chartPoints.length - 1),
            top: 3 + 38 * (1 -
              ((point.maximum === undefined ? point.value : point.maximum) - this.heartChartMinimum()) /
              Math.max(1, this.heartChartMaximum() - this.heartChartMinimum()))
          })
      })
    }
    .width(166).height(44).clip(true)
  }

  @Builder RangeIndicatorOverview() {
    Column({ space: 4 }) {
      Text(this.rangeHeaderText())
        .fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.card.id === 'HrvAssessment') {
          Row({ space: 0 }) {
            Row().width(23).height(4).backgroundColor(AppColors.HEALTH_WARNING)
            Row().width(26).height(4).backgroundColor(AppColors.VISUAL_YELLOW)
            Row().width(49).height(4).backgroundColor(AppColors.VISUAL_GREEN)
            Row().layoutWeight(1).height(4).backgroundColor(AppColors.VISUAL_ORANGE)
          }
          .width(130).height(4).borderRadius(2).clip(true)
        } else {
          Row().width(130).height(4).backgroundColor(AppColors.VISUAL_PINK).borderRadius(2)
        }
        this.RangeMarker()
      }
      .width(130).height(20)
      if (this.card.id === 'HrvAssessment') {
        Row({ space: 4 }) {
          Circle().width(5).height(5).fill(AppColors.VISUAL_GREEN)
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs))
            .fontSize(10).fontColor(AppColors.MUTED).maxLines(1)
        }
      }
    }
    .width(130)
  }

  @Builder RangeMarker() {
    Path()
      .commands(this.rangeMarkerPath())
      .width(8).height(7)
      .fill(AppColors.WHITE)
      .stroke(AppColors.WHITE).strokeWidth(1)
      .margin({ left: Math.max(0, Math.min(122, 130 * this.rangeFraction() - 4)), top: 7 })
  }

  @Builder Bars(
    widthValue: number = 130,
    heightValue: number = 54,
    highlightedIndex: number = -1,
    showTrack: boolean = false
  ) {
    Row({ space: 5 }) {
      ForEach(this.card.visual.chartPoints, (point: HealthChartPointData, index: number) => {
        Stack({ alignContent: Alignment.Bottom }) {
          if (showTrack) {
            Row().width('100%').height(heightValue).backgroundColor(AppColors.RANGE_TRACK).borderRadius(2)
          }
          Row().width('100%').height(this.barHeight(point, heightValue))
            .backgroundColor(this.barColor(point, index, highlightedIndex)).borderRadius(2)
        }
        .height(heightValue).layoutWeight(1)
      })
    }.height(heightValue).width(widthValue).alignItems(VerticalAlign.Bottom).clip(true)
  }

  @Builder LoadOverview() {
    Column({ space: 4 }) {
      this.Bars(130, 36, this.card.visual.highlightedIndex, true)
      Row() {
        ForEach(this.card.visual.chartPoints.slice(0, 7), (point: HealthChartPointData, index: number) => {
          Text(this.text(point.label)).fontSize(9)
            .fontColor(index === this.card.visual.highlightedIndex ? AppColors.WHITE : AppColors.MUTED)
          if (index < 6) { Blank() }
        })
      }.width(130)
    }.width(130)
  }

  @Builder StressOverview() {
    Row({ space: 1 }) {
      ForEach(this.stressBarIndexes(), (index: number) => {
        Row().width(1).height(this.stressHeight(index)).backgroundColor(this.stressColor(index))
      })
    }.width(166).height(56).alignItems(VerticalAlign.Bottom).clip(true)
  }

  @Builder SleepOverview() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.card.visual.sleepStages, (stage: SleepStageData) => {
        Row()
          .width(Math.max(2, 130 * stage.durationMinutes / this.sleepTotalMinutes() - 2))
          .height(7)
          .backgroundColor(this.sleepStageColor(stage))
          .borderRadius(2)
          .margin({
            left: 130 * stage.startMinute / this.sleepTotalMinutes(),
            top: this.sleepStageTop(stage)
          })
      })
    }.width(130).height(56).clip(true)
  }

  @Builder HealthCheckGrid() {
    Column({ space: 7 }) {
      Row({ space: 18 }) {
        ForEach(this.card.visual.metrics.slice(0, 3), (metric: HealthMetricData) => {
          Column() { this.Metric(metric) }.width(92).alignItems(HorizontalAlign.Start)
        })
      }.width('100%')
      Row({ space: 18 }) {
        ForEach(this.card.visual.metrics.slice(3, 5), (metric: HealthMetricData) => {
          Column() { this.Metric(metric) }.width(92).alignItems(HorizontalAlign.Start)
        })
      }.width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder VisualContent() {
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
      }.width('100%').height(48).alignItems(VerticalAlign.Center).margin({ top: 10 })
    } else if (this.card.visual.kind === 'WeeklyPlan') {
      Column({ space: 8 }) {
        Row() {
          ForEach(this.card.visual.chartPoints.slice(0, 7), (point: HealthChartPointData, index: number) => {
            Text(this.text(point.label)).fontSize(14).fontColor(index === this.weeklySelectedIndex() ? AppColors.WHITE : AppColors.MUTED)
              .width(28).height(28).textAlign(TextAlign.Center)
              .backgroundColor(index === this.weeklySelectedIndex() ? AppColors.ACTION : AppColors.TRANSPARENT).borderRadius(14)
              .onClick(() => {
                this.selectedWeeklyDay = index;
                if (this.onWeeklyDaySelected) this.onWeeklyDaySelected(index);
              })
            if (index < 6) { Blank() }
          })
        }.width('100%')
        Row({ space: 8 }) {
          Image(AppImages.todayRunner()).width(20).height(20).objectFit(ImageFit.Contain)
          Column({ space: 2 }) {
            Text(this.weeklyPlan()?.workoutNameKey ?
              this.text(this.weeklyPlan()?.workoutNameKey) : this.text('health_visual_weekly_rest_day'))
              .fontSize(14).fontColor(AppColors.WHITE).maxLines(1)
            Row() {
              Text(this.weeklyPlan()?.workoutDurationMinutes?.toString() || '--')
                .fontSize(12).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE)
              if (this.weeklyPlan()?.workoutDurationMinutes !== undefined) {
                Text(this.text('health_unit_minutes_long'))
                  .fontSize(12).fontFamily('COROSAPPBold').fontColor(AppColors.MUTED).margin({ left: 2 })
              }
              if (this.weeklyPlan()?.workoutTrainingLoad !== undefined) {
                Text(`  ${this.weeklyPlan()?.workoutTrainingLoad} ${this.text('health_visual_training_load_short')}`)
                  .fontSize(11).fontColor(AppColors.MUTED)
              }
            }
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Blank()
          this.Bars(80, 36, this.weeklySelectedIndex())
        }.width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor(AppColors.ACTIVITY_TILE).borderRadius(6)
      }.margin({ top: 8 })
    } else if (this.card.visual.kind === 'TrainingLoad') {
      Row() {
        Column() {
          Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold')
            .fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs))
            .fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
        Blank()
        this.LoadOverview()
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'TrendBars') {
      Row() {
        Column() {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
            if (this.card.visual.primaryUnitKey) { Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
          }
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
        Blank()
        if (this.card.id === 'HeartRate') {
          this.HeartRateIntervalOverview()
        } else {
          this.StressOverview()
        }
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'TrainingAssessment') {
      Column({ space: 4 }) {
        Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(20).fontColor(AppColors.VISUAL_ORANGE).fontWeight(FontWeight.Medium)
        Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE).maxLines(2)
        Row() {
          ForEach(this.card.visual.metrics.slice(0, 3), (metric: HealthMetricData, index: number) => {
            Column() { this.Metric(metric) }.width(82).alignItems(HorizontalAlign.Start)
            if (index < 2) { Blank(); Divider().vertical(true).height(42).color(AppColors.DIVIDER); Blank() }
          })
        }.width('100%').margin({ top: 12 })
      }.alignItems(HorizontalAlign.Start).margin({ top: 8 })
    } else if (this.card.visual.kind === 'RecoveryGauge' || this.card.visual.kind === 'AbilityGauge') {
      Row() {
        Column({ space: 0 }) {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
            if (this.card.visual.primaryUnitKey) { Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
          }
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
          Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
        Blank()
        this.GaugeOverview()
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'RangeIndicator') {
      Row() {
        Column({ space: 0 }) {
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
            if (this.card.visual.primaryUnitKey) { Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
          }
          Text(this.text(
            this.card.id === 'RestingHeartRate' ? this.card.visual.captionKey : this.card.visual.detailKey,
            this.card.id === 'RestingHeartRate' ? this.card.visual.captionArgs : this.card.visual.detailArgs
          )).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
        Blank()
        this.RangeIndicatorOverview()
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
        }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
        Blank()
        this.SleepOverview()
      }.width('100%').alignItems(VerticalAlign.Center)
    } else if (this.card.visual.kind === 'HealthCheckGrid') {
      Column() {
        this.HealthCheckGrid()
      }.width('100%').alignItems(HorizontalAlign.Start).margin({ top: 8 })
    } else if (this.card.visual.kind === 'BodyMap') {
      Row() {
        Column({ space: 4 }) {
          Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE)
          Row() {
            Text(this.card.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
            Text(this.text(this.card.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
          }
          Text(this.text(this.card.visual.detailKey, this.card.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED)
        }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
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
      Column({ space: 0 }) {
        this.Header()
        if (this.card.status === 'Empty') {
          Text(this.card.summary).fontSize(14).lineHeight(18).fontColor(AppColors.MUTED).margin({ top: 12 })
        } else {
          Column() {
            this.VisualContent()
          }
          .width('100%')
          .constraintSize({ minHeight: this.contentMinimumHeight() })
          .alignItems(HorizontalAlign.Start)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(AppColors.HEALTH_CARD).borderRadius(8).clip(true)
      .onClick(() => { if (this.onTap) { this.onTap(); } })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
  }
}
