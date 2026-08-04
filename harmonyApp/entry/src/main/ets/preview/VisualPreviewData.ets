import {
  HealthChartPointData,
  HealthMetricData,
  HealthRangeSegmentData,
  HealthVisualData,
  SleepStageData,
  WeeklyDayPlanData
} from '../health/HealthDashboardTypes';

const emptyChartPoints: HealthChartPointData[] = [];
const emptyMetrics: HealthMetricData[] = [];
const emptySleepStages: SleepStageData[] = [];

const weekPoints: HealthChartPointData[] = [
  { label: 'health_visual_day_mon', value: 42, level: 'Normal' },
  { label: 'health_visual_day_tue', value: 68, level: 'Good' },
  { label: 'health_visual_day_wed', value: 55, level: 'Normal' },
  { label: 'health_visual_day_thu', value: 81, level: 'Elevated' },
  { label: 'health_visual_day_fri', value: 63, level: 'Good' },
  { label: 'health_visual_day_sat', value: 35, level: 'Normal' },
  { label: 'health_visual_day_sun', value: 20, level: 'Normal' }
];

export function abilityPreviewVisual(): HealthVisualData {
  return { kind: 'Gauge', primaryValue: '82', captionKey: 'health_visual_marathon_prediction', progress: 0.82,
    chartPoints: emptyChartPoints, metrics: emptyMetrics, sleepStages: emptySleepStages };
}

export function activityPreviewVisual(): HealthVisualData {
  return { kind: 'Activity', primaryValue: '8.6', primaryUnitKey: 'health_unit_kilometers',
    detailKey: 'health_visual_activity_pace', detailArgs: ['5:18'], captionKey: 'health_visual_activity_easy_run',
    chartPoints: emptyChartPoints, metrics: emptyMetrics, sleepStages: emptySleepStages };
}

export function bodyPreviewVisual(): HealthVisualData {
  return { kind: 'Body', primaryValue: '68.2', primaryUnitKey: 'health_unit_kilograms',
    captionKey: 'health_visual_weight', detailKey: 'health_visual_measured_date', detailArgs: ['08-04'],
    footerKey: 'health_visual_weekly_primary_muscles',
    highlightedBodyRegions: ['chest_front', 'shoulders_front', 'latissimus_dorsi_back', 'glutes_back'],
    chartPoints: emptyChartPoints, metrics: emptyMetrics, sleepStages: emptySleepStages };
}

export function healthGridPreviewVisual(): HealthVisualData {
  const metrics: HealthMetricData[] = [
    { labelKey: 'health_visual_heart_rate', value: '62', unitKey: 'health_unit_bpm' },
    { labelKey: 'health_visual_hrv', value: '48', unitKey: 'health_unit_milliseconds' },
    { labelKey: 'health_visual_stress', value: '24' },
    { labelKey: 'health_visual_respiratory_rate', value: '15', unitKey: 'health_unit_per_minute' },
    { labelKey: 'health_visual_blood_oxygen', value: '98', unitKey: 'health_unit_percent' }
  ];
  return { kind: 'Metrics', chartPoints: emptyChartPoints, sleepStages: emptySleepStages, metrics: metrics };
}

export function hrvPreviewVisual(): HealthVisualData {
  const segments: HealthRangeSegmentData[] = [
    { minimum: 20, maximum: 32, level: 'VeryLow' }, { minimum: 32, maximum: 42, level: 'Low' },
    { minimum: 42, maximum: 68, level: 'Normal' }, { minimum: 68, maximum: 90, level: 'High' }
  ];
  return { kind: 'Range', captionKey: 'health_visual_hrv_balanced', detailKey: 'health_visual_hrv_average',
    primaryUnitKey: 'health_unit_milliseconds', chartPoints: emptyChartPoints, metrics: emptyMetrics,
    sleepStages: emptySleepStages,
    range: { minimum: 20, maximum: 90, current: 52, normalMin: 42, normalMax: 68, segments: segments } };
}

export function recoveryPreviewVisual(): HealthVisualData {
  return { kind: 'Gauge', primaryValue: '78', primaryUnitKey: 'health_unit_percent',
    captionKey: 'health_visual_recovery_after_hours', captionArgs: ['4'], progress: 0.78,
    chartPoints: emptyChartPoints, metrics: emptyMetrics, sleepStages: emptySleepStages };
}

export function restingHeartRatePreviewVisual(): HealthVisualData {
  return { kind: 'Range', primaryValue: '52', primaryUnitKey: 'health_unit_bpm',
    captionKey: 'health_visual_thirty_day_average', detailKey: 'health_visual_measured_at', detailArgs: ['07:30'],
    range: { minimum: 40, maximum: 80, current: 52, average: 55 }, chartPoints: emptyChartPoints,
    metrics: emptyMetrics, sleepStages: emptySleepStages };
}

export function sleepPreviewVisual(): HealthVisualData {
  const sleepStages: SleepStageData[] = [
    { stage: 'Awake', startMinute: 0, durationMinutes: 22 },
    { stage: 'Rem', startMinute: 22, durationMinutes: 78 },
    { stage: 'Light', startMinute: 100, durationMinutes: 210 },
    { stage: 'Deep', startMinute: 310, durationMinutes: 146 }
  ];
  return { kind: 'Sleep', primaryValue: '7', primaryUnitKey: 'health_unit_hours_short',
    secondaryValue: '36', secondaryUnitKey: 'health_unit_minutes_short', startTime: '22:48', endTime: '06:24',
    chartPoints: emptyChartPoints, metrics: emptyMetrics, sleepStages: sleepStages };
}

export function trainingAssessmentPreviewVisual(): HealthVisualData {
  const metrics: HealthMetricData[] = [
    { labelKey: 'health_visual_short_term_load', value: '68' },
    { labelKey: 'health_visual_long_term_load', value: '61' },
    { labelKey: 'health_visual_load_ratio', value: '1.1' }
  ];
  return { kind: 'Metrics', captionKey: 'health_visual_assessment_maintaining',
    detailKey: 'health_visual_assessment_maintaining_detail', chartPoints: emptyChartPoints,
    sleepStages: emptySleepStages, metrics: metrics };
}

export function trainingLoadPreviewVisual(): HealthVisualData {
  return { kind: 'Bars', primaryValue: '68', captionKey: 'health_visual_training_load_short',
    highlightedIndex: 3, chartPoints: weekPoints, metrics: emptyMetrics, sleepStages: emptySleepStages };
}

export function heartRatePreviewVisual(): HealthVisualData {
  const chartPoints: HealthChartPointData[] = [
    { label: '0', value: 112, minimum: 92, maximum: 128, average: 112, level: 'Normal' },
    { label: '1', value: 138, minimum: 108, maximum: 166, average: 138, level: 'Elevated' },
    { label: '2', value: 126, minimum: 101, maximum: 151, average: 126, level: 'Normal' },
    { label: '3', value: 145, minimum: 116, maximum: 174, average: 145, level: 'High' }
  ];
  return { kind: 'TrendBars', primaryValue: '132', primaryUnitKey: 'health_unit_bpm',
    captionKey: 'health_visual_average_heart_rate', metrics: emptyMetrics, sleepStages: emptySleepStages,
    chartPoints: chartPoints };
}

export function stressPreviewVisual(): HealthVisualData {
  const chartPoints: HealthChartPointData[] = [
    { label: '0', value: 20, level: 'Normal' }, { label: '1', value: 48, level: 'Good' },
    { label: '2', value: 32, level: 'Normal' }, { label: '3', value: 72, level: 'Elevated' },
    { label: '4', value: 28, level: 'Normal' }
  ];
  return { kind: 'TrendBars', primaryValue: '36', captionKey: 'health_visual_average_stress',
    metrics: emptyMetrics, sleepStages: emptySleepStages, chartPoints: chartPoints };
}

export function weeklyPlanPreviewVisual(): HealthVisualData {
  const weeklyDayPlans: WeeklyDayPlanData[] = [
    { dayIndex: 0 },
    { dayIndex: 1, workoutNameKey: 'health_visual_workout_easy_run', workoutDurationMinutes: 45, workoutTrainingLoad: 68 },
    { dayIndex: 2 }, { dayIndex: 3, workoutNameKey: 'health_visual_activity_tempo_run', workoutDurationMinutes: 35,
      workoutTrainingLoad: 81 }, { dayIndex: 4 }, { dayIndex: 5 }, { dayIndex: 6 }
  ];
  return { kind: 'WeeklyPlan', highlightedIndex: 1, chartPoints: weekPoints, metrics: emptyMetrics,
    sleepStages: emptySleepStages, weeklyDayPlans: weeklyDayPlans };
}
