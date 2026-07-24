import { AppColors } from '../../../resources/AppResources';
import { HealthChartPointData, HealthRangeData } from '../../HealthDashboardTypes';

export function barColor(kind: string, point: HealthChartPointData, index: number, highlightedIndex: number): ResourceColor {
  if (kind === 'TrainingLoad') return AppColors.VISUAL_CYAN;
  if (index === highlightedIndex) return AppColors.VISUAL_CYAN;
  if (point.level === 'High') return AppColors.HEALTH_WARNING;
  if (point.level === 'Elevated') return AppColors.VISUAL_ORANGE;
  if (point.level === 'Good') return AppColors.VISUAL_YELLOW;
  return AppColors.VISUAL_BAR;
}

export function barHeight(point: HealthChartPointData, containerHeight: number, chartPoints: HealthChartPointData[]): number {
  let high: number = 1;
  chartPoints.forEach((item: HealthChartPointData) => { if (item.value > high) high = item.value; });
  return point.value <= 0 ? 2 : Math.max(3, Math.round(containerHeight * point.value / high));
}

export function gaugeProgress(progress: number | undefined): number {
  return Math.max(0, Math.min(1, progress || 0));
}

export function gaugeArcPath(
  progress: number, centerXValue: number, centerYValue: number, radiusValue: number
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

export function abilitySegmentPath(index: number): string {
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

export function abilityNeedlePath(progress: number): string {
  const centerX: number = vp2px(60.5);
  const centerY: number = vp2px(55);
  const needleLength: number = vp2px(37);
  const angle: number = Math.PI + gaugeProgress(progress) * Math.PI;
  return `M${centerX} ${centerY} L${centerX + Math.cos(angle) * needleLength} ${centerY + Math.sin(angle) * needleLength}`;
}

export function rangeMarkerPath(): string {
  return `M${vp2px(4)} 0 L0 ${vp2px(7)} L${vp2px(8)} ${vp2px(7)} Z`;
}

export function rangeFraction(range: HealthRangeData | undefined): number {
  if (!range) return 0.5;
  const w = Math.max(1, range.maximum - range.minimum);
  return Math.max(0, Math.min(1, (range.current - range.minimum) / w));
}
