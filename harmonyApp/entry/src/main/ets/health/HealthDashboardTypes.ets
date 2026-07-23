import { healthResource } from '../resources/HealthLocalization';

export interface CardEntry {
  type: string;
  titleKey: string;
  summaryKey: string;
  summaryArgs: string[];
  status: string;
  isRisk: boolean;
  visual: HealthVisualData;
}

export interface HealthChartPointData {
  label: string;
  value: number;
  level: string;
  minimum?: number;
  maximum?: number;
  average?: number;
}
export interface HealthMetricData { labelKey: string; value: string; unitKey?: string; }
export interface WeeklyDayPlanData {
  dayIndex: number;
  workoutNameKey?: string;
  workoutDurationMinutes?: number;
  workoutTrainingLoad?: number;
}
export interface HealthRangeData { minimum: number; maximum: number; current: number; normalMin?: number; normalMax?: number; average?: number; }
export interface SleepStageData { stage: string; startMinute: number; durationMinutes: number; }
export interface HealthVisualData {
  kind: string;
  primaryValue?: string; primaryUnitKey?: string;
  secondaryValue?: string; secondaryUnitKey?: string;
  captionKey?: string; captionArgs?: string[];
  detailKey?: string; detailArgs?: string[];
  progress?: number; highlightedIndex?: number;
  weeklyDayPlans?: WeeklyDayPlanData[];
  chartPoints: HealthChartPointData[]; metrics: HealthMetricData[];
  range?: HealthRangeData; sleepStages: SleepStageData[];
  startTime?: string; endTime?: string; assetKey?: string;
}

export interface HealthSnapshot {
  error?: string;
  scenario: string;
  dateLabelKey: string;
  steps: number;
  calories: number;
  activeMinutes: number;
  cards: CardEntry[];
  enabledTypes: string;
}

export class HealthCardModel {
  id: string;
  title: ResourceStr;
  summary: ResourceStr;
  iconIndex: number;
  isRisk: boolean;
  status: string;
  visual: HealthVisualData;

  constructor(id: string, title: ResourceStr, summary: ResourceStr, iconIndex: number, isRisk: boolean = false,
    status: string = 'Empty',
    visual: HealthVisualData = { kind: 'TrendBars', chartPoints: [], metrics: [], sleepStages: [] }) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.iconIndex = iconIndex;
    this.isRisk = isRisk;
    this.status = status;
    this.visual = visual;
  }
}

export function createDefaultHealthCards(): HealthCardModel[] {
  return [
    new HealthCardModel('TodayActivity', $r('app.string.health_card_today_activity_title'), $r('app.string.health_summary_activity_empty'), 2),
    new HealthCardModel('WeeklyPlan', $r('app.string.health_card_weekly_plan_title'), $r('app.string.health_summary_weekly_empty'), 0),
    new HealthCardModel('TrainingLoad', $r('app.string.health_card_training_load_title'), $r('app.string.health_summary_training_load_empty'), 1),
    new HealthCardModel('TrainingAssessment', $r('app.string.health_card_training_assessment_title'), $r('app.string.health_summary_training_assessment_empty'), 2),
    new HealthCardModel('Recovery', $r('app.string.health_card_recovery_title'), $r('app.string.health_summary_recovery_empty'), 3),
    new HealthCardModel('RunningAbility', $r('app.string.health_card_running_ability_title'), $r('app.string.health_summary_running_empty'), 4),
    new HealthCardModel('CyclingAbility', $r('app.string.health_card_cycling_ability_title'), $r('app.string.health_summary_cycling_empty'), 5),
    new HealthCardModel('HeartRate', $r('app.string.health_card_heart_rate_title'), $r('app.string.health_summary_heart_rate_empty'), 6),
    new HealthCardModel('Stress', $r('app.string.health_card_stress_title'), $r('app.string.health_summary_stress_empty'), 7),
    new HealthCardModel('Sleep', $r('app.string.health_card_sleep_title'), $r('app.string.health_summary_sleep_empty'), 8),
    new HealthCardModel('HrvAssessment', $r('app.string.health_card_hrv_assessment_title'), $r('app.string.health_summary_hrv_empty'), 9),
    new HealthCardModel('RestingHeartRate', $r('app.string.health_card_resting_heart_rate_title'), $r('app.string.health_summary_resting_hr_empty'), 10),
    new HealthCardModel('HealthCheck', $r('app.string.health_card_health_check_title'), $r('app.string.health_summary_health_check_empty'), 11),
    new HealthCardModel('BodyManagement', $r('app.string.health_card_body_management_title'), $r('app.string.health_summary_body_empty'), 12)
  ];
}

export function cardIconIndex(typeName: string): number {
  switch (typeName) {
    case 'WeeklyPlan': return 0;
    case 'TrainingLoad': return 1;
    case 'TrainingAssessment': return 2;
    case 'Recovery': return 3;
    case 'RunningAbility': return 4;
    case 'CyclingAbility': return 5;
    case 'HeartRate': return 6;
    case 'Stress': return 7;
    case 'Sleep': return 8;
    case 'HrvAssessment': return 9;
    case 'RestingHeartRate': return 10;
    case 'HealthCheck': return 11;
    case 'BodyManagement': return 12;
    case 'TodayActivity': return 2;
    default: return 6;
  }
}

export function localizedHealthText(context: object, key: string, args: string[]): string {
  let resource: Resource = healthResource(key);
  let manager = getContext(context).resourceManager;
  if (args.length === 0) return manager.getStringSync(resource.id);
  if (args.length === 1) return manager.getStringSync(resource.id, args[0]);
  if (args.length === 2) return manager.getStringSync(resource.id, args[0], args[1]);
  return manager.getStringSync(resource.id, args[0], args[1], args[2]);
}

export function resourceText(context: object, value: ResourceStr): string {
  if (typeof value === 'string') return value;
  return getContext(context).resourceManager.getStringSync(value.id);
}
