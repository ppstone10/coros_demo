import { HealthCardModel, createDefaultHealthCards } from '../health/HealthDashboardTypes';
import { HeroTopRowComp } from '../health/components/HeroTopRowComp';
import { MetricComp } from '../health/components/MetricComp';
import { DashboardCardComp } from '../health/components/DashboardCardComp';
import { AccountOverviewComp } from '../home/account/AccountOverviewComp';
import { BottomNavBarComp } from '../home/BottomNavBarComp';
import { CardEditorComp } from '../health/editor/CardEditorComp';
import { HealthDetailComp } from '../health/detail/HealthDetailComp';
import { AppColors, AppImages } from '../core/resources/AppResources';

/**
 * Pure Preview hosts keep required @Prop/@Link values in a parent component.
 * Health data still enters ArkUI through the production KNOI JSON mapping path.
 */
@Preview
@Component
struct HealthComponentPreviewCatalog {
  @State cards: HealthCardModel[] = createDefaultHealthCards();

  build() {
    Column() {
      HeroTopRowComp({ dateLabel: $r('app.string.health_demo_date'), isSyncing: false })
      Row() {
        MetricComp({ icon: AppImages.steps(), value: '8769', unit: $r('app.string.health_unit_steps') })
        MetricComp({ icon: AppImages.calories(), value: '769', unit: $r('app.string.health_unit_calories') })
        MetricComp({ icon: AppImages.activeDuration(), value: '69', unit: $r('app.string.health_unit_minutes') })
      }
      .width('100%').justifyContent(FlexAlign.SpaceEvenly).padding({ top: 16, bottom: 16 })
      Scroll() {
        Column() {
          ForEach(this.cards, (card: HealthCardModel) => {
            DashboardCardComp({ card: card });
          }, (card: HealthCardModel) => card.id)
        }
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(AppColors.HEALTH_DATE)
  }
}

@Preview
@Component
struct AccountAndNavigationPreviewCatalog {
  build() {
    Column() {
      AccountOverviewComp({
        displayName: 'COROS user',
        sessionAccount: 'preview@example.com',
        profileComplete: true,
        birthDate: '1995-08-03',
        heightText: '175 cm',
        weightText: '68.2 kg',
        countryRegion: 'CN'
      })
      BottomNavBarComp({ selectedTab: 3 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.HEALTH_DATE)
  }
}

@Preview
@Component
struct CardEditorPreviewHost {
  @State cards: HealthCardModel[] = createDefaultHealthCards();

  build() {
    CardEditorComp({
      healthCards: this.cards,
      onSave: (_typeNamesCsv: string) => {},
      onCancel: () => {}
    })
  }
}

@Preview
@Component
struct HealthDetailPreviewHost {
  @State cards: HealthCardModel[] = createDefaultHealthCards();

  build() {
    HealthDetailComp({
      cardId: 'TodayActivity',
      healthCards: this.cards,
      backAction: () => {}
    })
  }
}
