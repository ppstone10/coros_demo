export class AppColors {
  static readonly BLACK: string = '#000000';
  static readonly WHITE: string = '#FFFFFF';
  static readonly HEALTH_CARD: string = '#191919';
  static readonly MUTED: string = '#777777';
  static readonly ACCOUNT_MUTED: string = '#8A8A8E';
  static readonly GAUGE: string = '#FFB735';
  static readonly STEPS: string = '#00DF7B';
  static readonly CALORIES: string = '#FFC928';
  static readonly ACTIVE: string = '#D72BCC';
  static readonly ACTION: string = '#F0003C';
  static readonly ADD_ACTION: string = '#00DF7B';
  static readonly RISK: string = '#FFA34A';
  static readonly DIVIDER: string = '#303030';
  static readonly HEALTH_EDIT_TEXT: string = '#DDDDDD';
  static readonly HEALTH_DATE: string = '#8C8C8C';
  static readonly HEALTH_METRIC_UNIT: string = '#898989';
  static readonly HEALTH_CARD_TITLE: string = '#E8E8E8';
  static readonly HEALTH_CHEVRON: string = '#666666';
  static readonly HEALTH_WARNING: string = '#FF4B55';
  static readonly HEALTH_EDITOR_TITLE: string = '#ECECEC';
  static readonly HEALTH_PLACEHOLDER: string = '#BBBBBB';
  static readonly VISUAL_GREEN: string = '#00DF7B';
  static readonly VISUAL_YELLOW: string = '#FFC928';
  static readonly VISUAL_ORANGE: string = '#FF9F30';
  static readonly VISUAL_PURPLE: string = '#B769FF';
  static readonly VISUAL_BLUE: string = '#42A5F5';
  static readonly VISUAL_CYAN: string = '#2DCDD3';
  static readonly VISUAL_PINK: string = '#E82D8A';
  static readonly VISUAL_DEEP_BLUE: string = '#3156B8';
  static readonly STRESS_LOW: string = '#449AFA';
  static readonly STRESS_GOOD: string = '#AADB37';
  static readonly VISUAL_BAR: string = '#626262';
  static readonly RANGE_TRACK: string = '#454545';
  static readonly ACTIVITY_TILE: string = '#223C32';
  static readonly COMPLETE: string = '#19C875';
  static readonly INCOMPLETE: string = '#FFB735';
  static readonly DESTRUCTIVE: string = '#FF4053';
  static readonly NAV_BAR: string = '#F21A1A1C';
  static readonly NAV_UNSELECTED: string = '#85868A';
  static readonly TRANSPARENT: string = '#00000000';
  static readonly AUTH_DISABLED_BACKGROUND: string = '#1D1D1D';
  static readonly AUTH_ENTRANCE_BUTTON: string = '#424242';
  static readonly AUTH_INPUT_TEXT: string = '#D8D8DD';
  static readonly AUTH_LOADING: string = '#3A3A3C';
  static readonly AUTH_DIALOG: string = '#222224';
  static readonly AUTH_INPUT_BORDER: string = '#3A3A3D';
  static readonly AUTH_THIRD_PARTY_BORDER: string = '#303036';
  static readonly AUTH_CHECKMARK: string = '#D0D0D0';
  static readonly AUTH_OVERLAY_SOFT: string = '#B8000000';
  static readonly AUTH_SHEET: string = '#1A1A1B';
  static readonly AUTH_LEGAL_TEXT: string = '#C9C9CC';
  static readonly PROFILE_DESCRIPTION: string = '#E8E8EC';
  static readonly PROFILE_AVATAR: string = '#171719';
  static readonly PROFILE_VALUE: string = '#DADAE0';
  static readonly PROFILE_CONTROL: string = '#19191B';
  static readonly PROFILE_SELECTED_BORDER: string = '#38383C';
  static readonly PROFILE_WHEEL_NEAR: string = '#CFCFD4';
  static readonly PROFILE_WHEEL_FAR: string = '#77777D';
  static readonly PROFILE_WHEEL_BORDER: string = '#34343A';
  static readonly PROFILE_ACTION_SHEET: string = '#18181A';
  static readonly PROFILE_ACTION_DIVIDER: string = '#101012';
  static readonly PROFILE_SAVE_DISABLED: string = '#5F001C';
  static readonly ACCOUNT_AVATAR: string = '#303034';
  static readonly ACCOUNT_DIVIDER: string = '#2B2B2D';
  static readonly ACCOUNT_DIALOG: string = '#202023';
  static readonly ACCOUNT_DIALOG_SECONDARY: string = '#343438';
  static readonly NAV_PLACEHOLDER: string = '#B3B5BA';
  static readonly OVERLAY_60: string = '#99000000';
  static readonly OVERLAY_62: string = '#0000009E';
  static readonly OVERLAY_42: string = '#6B000000';
  static readonly DIALOG_ALT: string = '#222225';
}

export class AppTypography {
  static readonly CAPTION: number = 11;
  static readonly SUPPORTING: number = 12;
  static readonly LABEL: number = 13;
  static readonly ACTION: number = 14;
  static readonly EDITOR_ROW: number = 15;
  static readonly CARD_TITLE: number = 16;
  static readonly SECTION_TITLE: number = 19;
  static readonly HERO_TITLE: number = 28;
}

export class AppSpacing {
  static readonly X_SMALL: number = 5;
  static readonly SMALL: number = 8;
  static readonly MEDIUM: number = 10;
  static readonly CAPTION_BOTTOM: number = 11;
  static readonly CONTENT_VERTICAL: number = 12;
  static readonly LABEL_VERTICAL: number = 14;
  static readonly CARD_CONTENT: number = 15;
  static readonly SCREEN: number = 16;
  static readonly LARGE: number = 18;
  static readonly PAGE: number = 20;
  static readonly SECTION: number = 24;
  static readonly ACTION_HORIZONTAL: number = 28;
}

export class AppImages {
  static calendar(): Resource { return $r('app.media.icon_calendar'); }
  static device(): Resource { return $r('app.media.icon_device_sportting'); }
  static steps(): Resource { return $r('app.media.steps_icon'); }
  static calories(): Resource { return $r('app.media.icon_calories'); }
  static activeDuration(): Resource { return $r('app.media.sport_time_icon'); }
  static editorAdd(): Resource { return $r('app.media.data_screen_edit_add'); }
  static editorRemove(): Resource { return $r('app.media.delete'); }
  static activityMap(): Resource { return $r('app.media.health_activity_map'); }
  static todayHeader(): Resource { return $r('app.media.health_today_header'); }
  static todayRunner(): Resource { return $r('app.media.health_today_runner'); }
  static bodyFront(): Resource { return $r('app.media.health_body_front'); }
  static bodyBack(): Resource { return $r('app.media.health_body_back'); }
  static recoveryStatus(): Resource { return $r('app.media.health_recovery_status'); }

  static healthCardIcon(typeName: string): Resource {
    switch (typeName) {
      case 'TodayActivity': return $r('app.media.icon_small_training_effect');
      case 'WeeklyPlan': return $r('app.media.icon_small_plan');
      case 'TrainingLoad': return $r('app.media.icon_small_training_load');
      case 'TrainingAssessment': return $r('app.media.icon_small_training_effect');
      case 'Recovery': return $r('app.media.icon_recovery_sports');
      case 'RunningAbility': return $r('app.media.icon_small_running_ability');
      case 'CyclingAbility': return $r('app.media.icon_small_cycling');
      case 'HeartRate': return $r('app.media.icon_small_heart_rate');
      case 'Stress': return $r('app.media.icon_small_stress');
      case 'Sleep': return $r('app.media.icon_small_sleep');
      case 'HrvAssessment': return $r('app.media.icon_small_sleep_hrv');
      case 'RestingHeartRate': return $r('app.media.icon_small_rhr');
      case 'HealthCheck': return $r('app.media.icon_small_health_detection');
      case 'BodyManagement': return $r('app.media.icon_small_body');
      default: return $r('app.media.icon_small_heart_rate');
    }
  }

  static healthIcon(index: number): Resource {
    if (index === 0) return $r('app.media.icon_small_plan');
    if (index === 1) return $r('app.media.icon_small_training_load');
    if (index === 2) return $r('app.media.icon_small_training_effect');
    if (index === 3) return $r('app.media.icon_recovery_sports');
    if (index === 4) return $r('app.media.icon_small_running_ability');
    if (index === 5) return $r('app.media.icon_small_cycling');
    if (index === 6) return $r('app.media.icon_small_heart_rate');
    if (index === 7) return $r('app.media.icon_small_stress');
    if (index === 8) return $r('app.media.icon_small_sleep');
    if (index === 9) return $r('app.media.icon_small_sleep_hrv');
    if (index === 10) return $r('app.media.icon_small_rhr');
    if (index === 11) return $r('app.media.icon_small_health_detection');
    return $r('app.media.icon_small_body');
  }

  static navigation(index: number, selected: boolean): Resource {
    if (index === 0) return selected ? $r('app.media.icon_tab_home_selected') : $r('app.media.icon_tab_home');
    if (index === 1) return selected ? $r('app.media.icon_tab_workout_list_selected') : $r('app.media.icon_tab_workout_list');
    if (index === 2) return selected ? $r('app.media.icon_tab_explore_selected') : $r('app.media.icon_tab_explore');
    return selected ? $r('app.media.icon_tab_me_selected') : $r('app.media.icon_tab_me');
  }

  static navigationNormal(index: number): Resource {
    if (index === 0) return $r('app.media.icon_tab_home');
    if (index === 1) return $r('app.media.icon_tab_workout_list');
    if (index === 2) return $r('app.media.icon_tab_explore');
    return $r('app.media.icon_tab_me');
  }

  static navigationSelected(index: number): Resource {
    if (index === 0) return $r('app.media.icon_tab_home_selected');
    if (index === 1) return $r('app.media.icon_tab_workout_list_selected');
    if (index === 2) return $r('app.media.icon_tab_explore_selected');
    return $r('app.media.icon_tab_me_selected');
  }
}
