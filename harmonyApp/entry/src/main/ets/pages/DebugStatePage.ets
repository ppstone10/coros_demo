import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { LoginViewModel } from '../login/LoginViewModel';
import { AuthMode, LoginAction, LoginActionType } from '../login/LoginState';
import {
  COROS_RED,
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_MUTED,
  COROS_LINE
} from '../login/components/AuthColors';
import {
  CorosButton,
  UnderlineInput,
  AuthHeader,
  ErrorText
} from '../login/components/AuthComponents';

@Entry
@Component
struct DebugStatePage {
  private viewModel: LoginViewModel = new LoginViewModel();
  private logLines: string[] = [];

  @State testInput: string = '';
  @State testInput2: string = '';
  @State compButtonClickCount: number = 0;
  @State rawButtonClickCount: number = 0;
  @State structBuilderClickCount: number = 0;
  @State toggleState: boolean = false;
  @State customEnabled: boolean = false;
  @State customLoading: boolean = false;
  @State showLog: boolean = true;

  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State loginActionEnabled: boolean = false;
  @State phoneCodeActionEnabled: boolean = false;

  aboutToAppear(): void {
    this.log('调试页面已加载');
    this.log('viewModel.state.username="' + this.viewModel.state.username + '"');
    this.log('viewModel.state.isLoading=' + this.viewModel.state.isLoading);
    this.refreshActionStates();
  }

  build() {
    Column() {
      AuthHeader({ showBack: true, showFeedback: false, onBack: () => { this.handleBack(); } });

      Scroll() {
        Column({ space: 16 }) {
          // ===== 第 1 区：原生 Button onClick 测试 =====
          this.SectionTitle('1. 原生 Button onClick 测试');
          Text('点击次数: ' + this.rawButtonClickCount)
            .fontSize(16).fontColor(COROS_WHITE)
          Button('原生按钮 - 点我', { type: ButtonType.Normal })
            .fontSize(18).fontColor(COROS_WHITE).width('100%').height(48)
            .borderRadius(9).backgroundColor(COROS_BUTTON_RED)
            .onClick(() => {
              this.rawButtonClickCount += 1;
              this.log('原生 Button onClick 触发 #' + this.rawButtonClickCount);
            })

          // ===== 第 2 区：@Component CorosButton 测试 =====
          this.SectionTitle('2. @Component CorosButton 测试');
          Text('点击次数: ' + this.compButtonClickCount)
            .fontSize(16).fontColor(COROS_WHITE)
          CorosButton({ textValue: 'Component按钮', color: COROS_BUTTON_RED, enabledValue: true, loading: false,
            onTap: () => {
              this.compButtonClickCount += 1;
              this.log('CorosButton onClick 触发 #' + this.compButtonClickCount);
            } });
          CorosButton({ textValue: '禁用态按钮(enabled=false)', color: COROS_BUTTON_RED, enabledValue: false, loading: false,
            onTap: () => { this.log('禁用态按钮被点击了！这不应该发生'); } });

          // ===== 第 3 区：struct 成员 @Builder 按钮测试（对照） =====
          this.SectionTitle('3. struct 成员 @Builder 按钮测试（对照）');
          Text('点击次数: ' + this.structBuilderClickCount)
            .fontSize(16).fontColor(COROS_WHITE)
          this.StructCorosButton('struct Builder按钮', COROS_BUTTON_RED, true, false, () => {
            this.structBuilderClickCount += 1;
            this.log('struct @Builder onClick 触发 #' + this.structBuilderClickCount);
          });

          // ===== 第 4 区：动态 enabled 切换测试 =====
          this.SectionTitle('4. 动态 enabled 状态切换');
          Text('customEnabled=' + this.customEnabled + ' customLoading=' + this.customLoading)
            .fontSize(14).fontColor(COROS_MUTED)
          Row({ space: 12 }) {
            Button('切换 enabled', { type: ButtonType.Normal })
              .fontSize(14).fontColor(COROS_WHITE).height(40).backgroundColor('#333333')
              .onClick(() => {
                this.customEnabled = !this.customEnabled;
                this.log('customEnabled 切换为 ' + this.customEnabled);
              })
            Button('切换 loading', { type: ButtonType.Normal })
              .fontSize(14).fontColor(COROS_WHITE).height(40).backgroundColor('#333333')
              .onClick(() => {
                this.customLoading = !this.customLoading;
                this.log('customLoading 切换为 ' + this.customLoading);
              })
          }
          CorosButton({ textValue: '@Component动态按钮', color: COROS_BUTTON_RED,
            enabledValue: this.customEnabled, loading: this.customLoading,
            onTap: () => { this.log('@Component 动态按钮被点击'); } });
          this.StructCorosButton('@Builder动态按钮', COROS_BUTTON_RED, this.customEnabled, this.customLoading, () => {
            this.log('@Builder 动态按钮被点击');
          });

          // ===== 第 5 区：@Component UnderlineInput onChange 测试 =====
          this.SectionTitle('5. @Component UnderlineInput onChange 测试');
          Text('testInput="' + this.testInput + '"').fontSize(14).fontColor(COROS_MUTED)
          UnderlineInput({ placeholder: '输入测试文字', textValue: this.testInput,
            inputType: InputType.Normal, isPassword: false, passwordVisible: false,
            onChange: (value: string) => {
              this.testInput = value;
              this.log('UnderlineInput onChange: "' + value + '"');
            } });

          // ===== 第 6 区：原生 TextInput onChange 测试 =====
          this.SectionTitle('6. 原生 TextInput onChange 测试');
          Text('testInput2="' + this.testInput2 + '"').fontSize(14).fontColor(COROS_MUTED)
          TextInput({ placeholder: '输入测试文字2', text: this.testInput2 })
            .type(InputType.Normal).fontSize(17).fontColor(COROS_WHITE)
            .placeholderColor(COROS_MUTED).caretColor(COROS_RED).backgroundColor(COROS_BLACK)
            .height(48).width('100%')
            .onChange((value: string) => {
              this.testInput2 = value;
              this.log('原生 TextInput onChange: "' + value + '"');
            })
          Divider().color(COROS_LINE)

          // ===== 第 7 区：镜像 LoginPage 登录表单 =====
          this.SectionTitle('7. 镜像登录表单 - 按钮使能状态');
          Text('username="' + this.username + '"').fontSize(14).fontColor(COROS_MUTED)
          Text('password="' + this.password + '"').fontSize(14).fontColor(COROS_MUTED)
          Text('isLoading=' + this.isLoading).fontSize(14).fontColor(COROS_MUTED)
          Text('loginActionEnabled=' + this.loginActionEnabled)
            .fontSize(16).fontColor(this.loginActionEnabled ? COROS_RED : COROS_MUTED)
          Text('phoneCodeActionEnabled=' + this.phoneCodeActionEnabled)
            .fontSize(16).fontColor(this.phoneCodeActionEnabled ? COROS_RED : COROS_MUTED)

          UnderlineInput({ placeholder: '输入手机号或邮箱', textValue: this.username,
            inputType: InputType.Email, isPassword: false, passwordVisible: false,
            onChange: (value: string) => {
              this.username = value;
              this.refreshActionStates();
              this.log('username onChange: "' + value + '" → loginActionEnabled=' + this.loginActionEnabled);
            } });
          Blank().height(8)
          UnderlineInput({ placeholder: '密码', textValue: this.password,
            inputType: InputType.Password, isPassword: true, passwordVisible: false,
            onChange: (value: string) => {
              this.password = value;
              this.refreshActionStates();
              this.log('password onChange: "' + value + '" → loginActionEnabled=' + this.loginActionEnabled);
            },
            onPasswordToggle: () => { this.log('密码可见切换被点击'); } });

          Blank().height(12)
          CorosButton({ textValue: '登录(@Component)', color: COROS_BUTTON_RED,
            enabledValue: this.loginActionEnabled, loading: this.isLoading,
            onTap: () => {
              this.log('登录按钮被点击! loginActionEnabled=' + this.loginActionEnabled);
              let action: LoginAction = new LoginAction();
              action.type = LoginActionType.SubmitClicked;
              this.viewModel.dispatch(action);
              this.log('viewModel.dispatch 已调用');
            } });
          this.StructCorosButton('登录(@Builder对照)', COROS_BUTTON_RED, this.loginActionEnabled, this.isLoading,
            () => { this.log('@Builder 登录按钮被点击!'); });

          ErrorText({ message: this.localValidationError() });

          // ===== 第 8 区：toggle 测试 =====
          this.SectionTitle('8. 协议勾选 toggle 测试');
          Text('toggleState=' + this.toggleState).fontSize(14).fontColor(COROS_MUTED)
          Row({ space: 12 }) {
            Text(this.toggleState ? '✓' : '')
              .fontSize(9).fontColor(COROS_WHITE).textAlign(TextAlign.Center)
              .width(18).height(18)
              .border({ width: 1, color: this.toggleState ? COROS_RED : '#D0D0D0', radius: 9 })
              .backgroundColor(this.toggleState ? COROS_RED : COROS_BLACK)
              .onClick(() => {
                this.toggleState = !this.toggleState;
                this.log('toggle 切换为 ' + this.toggleState);
              })
            Text('点击勾选框测试 onClick')
              .fontSize(16).fontColor(COROS_WHITE)
              .onClick(() => {
                this.toggleState = !this.toggleState;
                this.log('文字 onClick toggle 切换为 ' + this.toggleState);
              })
          }

          // ===== 第 9 区：日志输出 =====
          this.SectionTitle('9. 事件日志');
          if (this.showLog) {
            Button('隐藏日志', { type: ButtonType.Normal })
              .fontSize(14).fontColor(COROS_MUTED).height(36).backgroundColor('#222222')
              .onClick(() => { this.showLog = false; })
            Column({ space: 4 }) {
              ForEach(this.logLines, (line: string, index: number) => {
                Text('[' + index + '] ' + line)
                  .fontSize(12).fontColor(COROS_WHITE).width('100%')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#1A1A1A').borderRadius(4)
              }, (line: string, index: number) => index.toString())
            }
            .width('100%')
          } else {
            Button('显示日志', { type: ButtonType.Normal })
              .fontSize(14).fontColor(COROS_MUTED).height(36).backgroundColor('#222222')
              .onClick(() => { this.showLog = true; })
          }

          Blank().height(40)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .backgroundColor(COROS_BLACK)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  @Builder
  private SectionTitle(title: string) {
    Text(title)
      .fontSize(18).fontWeight(FontWeight.Bold).fontColor(COROS_RED)
      .margin({ top: 16, bottom: 4 }).width('100%')
  }

  // struct 成员 @Builder 按钮实现，用于和 @Component 对比
  @Builder
  private StructCorosButton(textValue: string, color: string, enabledValue: boolean, loading: boolean, onTap: () => void) {
    Button(loading ? '处理中' : textValue, { type: ButtonType.Normal })
      .fontSize(18)
      .fontColor(enabledValue ? COROS_WHITE : '#FFFFFF66')
      .width('100%').height(48).borderRadius(9)
      .backgroundColor(enabledValue ? color : this.structDisabledColor(color))
      .enabled(!loading && enabledValue)
      .onClick(() => {
        if (enabledValue) {
          onTap();
        }
      })
  }

  private structDisabledColor(color: string): string {
    if (color === COROS_BUTTON_RED) return '#5C001B';
    if (color === COROS_RED) return '#74001E';
    return '#1D1D1D';
  }

  private refreshActionStates(): void {
    this.loginActionEnabled = !this.isLoading && this.username.trim().length > 0 && this.password.length >= 6;
    this.phoneCodeActionEnabled = !this.isLoading && this.localValidatePhone(this.username).length === 0;
  }

  private localValidatePhone(account: string): string {
    let digits: string = '';
    for (let i = 0; i < account.length; i++) {
      let ch: string = account.charAt(i);
      if (ch >= '0' && ch <= '9') digits += ch;
    }
    if (digits.length !== 11) return '请输入11位手机号';
    return '';
  }

  private localValidationError(): string {
    if (this.username.trim().length === 0) return '请输入账号';
    if (this.password.length === 0) return '请输入密码';
    if (this.password.length < 6) return '密码需要为6-20位';
    return '';
  }

  private handleBack(): void {
    this.log('返回按钮被点击');
    router.back();
  }

  private log(msg: string): void {
    let timestamp: string = new Date().toLocaleTimeString();
    let entry: string = timestamp + ' ' + msg;
    this.logLines.push(entry);
    if (this.logLines.length > 30) {
      this.logLines.shift();
    }
    console.log('[DebugStatePage] ' + entry);
  }
}
