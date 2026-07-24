import { CardEntry, HealthCardModel, HealthSnapshot, cardIconIndex, createDefaultHealthCards, localizedHealthText } from './HealthDashboardTypes';
import { getService } from '../login/HarmonyServiceProvider';

@Observed
export class HealthDashboardViewModel {
  healthCards: HealthCardModel[] = createDefaultHealthCards();
  healthSteps: number = 0;
  healthCalories: number = 0;
  healthActiveMinutes: number = 0;
  healthDateLabel: string = '';
  healthDataCorrupted: boolean = false;
  refreshing: boolean = false;
  currentScenario: string = 'Normal';
  dashboardVersion: number = 0;
  effectMessage: string | undefined = undefined;

  load(context?: object): void {
    this.clearEffectMessage();
    try {
      this.applySnapshot(context);
      this.dashboardVersion++;
    } catch (e) {
      // keep defaults
    }
  }

  refresh(context?: object): void {
    this.clearEffectMessage();
    try {
      const service = getService();
      const json = service.refreshHealthSnapshot();
      if (json && json !== '{}') {
        const result: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
        if (result['error'] === 'CorruptedData') {
          this.healthDataCorrupted = true;
          this.effectMessage = 'Refresh failed';
        } else {
          this.applySnapshotFromJson(json, context);
        }
        this.dashboardVersion++;
      }
    } catch (e) {
      this.healthDataCorrupted = true;
      this.effectMessage = 'Refresh failed';
    }
  }

  selectScenario(scenario: string): void {
    try {
      if (getService().selectHealthScene(scenario) === 'true') {
        this.currentScenario = scenario;
      }
    } catch (e) { }
  }

  saveCardConfiguration(types: string[], context?: object): void {
    try {
      const result: string = getService().saveCardConfig(JSON.stringify(types));
      const parsed: object = JSON.parse(result);
      if (parsed && (parsed as Record<string, Object>)['error']) {
        this.effectMessage = 'Save failed';
        return;
      }
      this.load(context);
    } catch (e) {
      this.effectMessage = 'Save failed';
    }
  }

  consumeEffectMessage(): string | undefined {
    const m = this.effectMessage;
    this.effectMessage = undefined;
    return m;
  }

  clearEffectMessage(): void {
    this.effectMessage = undefined;
  }

  private applySnapshot(context?: object): void {
    const service = getService();
    const json = service.loadHealthSnapshot();
    this.applySnapshotFromJson(json, context);
  }

  private applySnapshotFromJson(json: string, context?: object): void {
    if (!json || json === '{}') return;
    const data: HealthSnapshot = JSON.parse(json) as HealthSnapshot;
    if (data.error === 'CorruptedData') {
      this.healthDataCorrupted = true;
      return;
    }
    if (!data.cards || data.cards.length === 0) return;
    this.healthDataCorrupted = false;
    this.currentScenario = data.scenario || 'Normal';
    this.healthSteps = data.steps || 0;
    this.healthCalories = data.calories || 0;
    this.healthActiveMinutes = data.activeMinutes || 0;
    if (context) {
      this.healthDateLabel = localizedHealthText(context, data.dateLabelKey || 'health_demo_date', []);
      const cards: HealthCardModel[] = [];
      for (let i = 0; i < data.cards.length; i++) {
        const c: CardEntry = data.cards[i];
        cards.push(new HealthCardModel(
          c.type,
          localizedHealthText(context, c.titleKey, []),
          localizedHealthText(context, c.summaryKey, c.summaryArgs || []),
          cardIconIndex(c.type),
          c.isRisk,
          c.status,
          c.visual
        ));
      }
      this.healthCards = cards;
    }
  }
}
