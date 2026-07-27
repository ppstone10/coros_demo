export enum HealthPullRefreshPhase {
  Idle,
  Dragging,
  Armed,
  Refreshing,
  Resetting
}

export const PULL_REFRESH_THRESHOLD: number = 80;
export const PULL_REFRESH_HOLD_OFFSET: number = 34;
export const PULL_INDICATOR_BODY_GAP: number = 80;
export const PULL_REFRESH_RESISTANCE: number = 0.4;
export const PULL_REFRESH_SETTLE_DURATION: number = 300;
export const PULL_REFRESH_SYNC_DURATION: number = 4460;

export function pullRefreshPhaseForOffset(offset: number): HealthPullRefreshPhase {
  if (offset <= 0) return HealthPullRefreshPhase.Idle;
  return offset >= PULL_REFRESH_THRESHOLD ?
    HealthPullRefreshPhase.Armed :
    HealthPullRefreshPhase.Dragging;
}

export function pullRefreshIndicatorTop(
  bodyTop: number,
  indicatorHeight: number
): number {
  return bodyTop - indicatorHeight - PULL_INDICATOR_BODY_GAP;
}
