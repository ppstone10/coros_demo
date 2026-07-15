export class AppText {
  static readonly NAV_FITNESS: string = '体能';
  static readonly NAV_RECORDS: string = '记录';
  static readonly NAV_EXPLORE: string = '探索';
  static readonly NAV_ME: string = '我';
  static readonly TODAY: string = '今天';
  static readonly DATE: string = '7月14日 星期二';
  static readonly EDIT_CARDS: string = '编辑卡片';
  static readonly MANAGE_CARDS: string = '管理卡片顺序（最少展示3项）';
  static readonly MINIMUM_CARDS: string = '最少展示三项日常数据';
  static readonly MORE_DATA: string = '更多日常数据';
  static readonly RESTORE_DEFAULTS: string = '恢复默认数据';
  static readonly NOT_SET: string = '未设置';
  static readonly PERSONAL_INFO: string = '个人信息';
  static readonly USERNAME: string = '用户名';
  static readonly BIRTH_DATE: string = '出生日期';
  static readonly HEIGHT: string = '身高';
  static readonly WEIGHT: string = '体重';
  static readonly COUNTRY: string = '国家与地区';
  static readonly ACCOUNT: string = '账号';
  static readonly LOGIN_ACCOUNT: string = '登录账号';
  static readonly LOGOUT: string = '退出登录';
  static readonly DELETE_ACCOUNT: string = '注销账户';
}

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
  static readonly COMPLETE: string = '#19C875';
  static readonly INCOMPLETE: string = '#FFB735';
  static readonly DESTRUCTIVE: string = '#FF4053';
  static readonly NAV_BAR: string = '#F21A1A1C';
  static readonly NAV_UNSELECTED: string = '#85868A';
}

export class AppImages {
  static calendar(): Resource { return $r('app.media.icon_calendar'); }
  static device(): Resource { return $r('app.media.icon_device_sportting'); }
  static steps(): Resource { return $r('app.media.steps_icon'); }
  static calories(): Resource { return $r('app.media.icon_calories'); }
  static activeDuration(): Resource { return $r('app.media.sport_time_icon'); }
  static editorAdd(): Resource { return $r('app.media.data_screen_edit_add'); }
  static editorRemove(): Resource { return $r('app.media.delete'); }

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
