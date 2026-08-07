// 认证共享枚举与纯函数助手。
// 交互式 UI 组件已按职责拆分到：
// - AuthBranding.ets（AuthTitle / AuthHeader）
// - AuthInputs.ets（ErrorText / CorosButton / UnderlineInput / PhoneInputComp /
//   DisabledUnderlineValue / AgreementRowComp / CodeBoxesComp / ThirdPartyAreaComp）
// - AuthOverlays.ets（BlockingLoadingOverlay / LegalDocumentPage）

export enum TermsPromptAction {
  None,
  Login,
  PhoneCode,
  EmailCode
}

export enum VerifyTargetKind {
  Phone,
  Email
}

export function verifyCodeMessage(account: string, targetKind: VerifyTargetKind): ResourceStr {
  if (targetKind === VerifyTargetKind.Email) {
    return $r('app.string.auth_verification_sent_email', account);
  }
  return $r('app.string.auth_verification_sent_phone', account);
}
