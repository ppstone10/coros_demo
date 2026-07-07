export class LegalParagraph {
  text: string;
  isHeading: boolean;

  constructor(text: string, isHeading: boolean = false) {
    this.text = text;
    this.isHeading = isHeading;
  }
}

export const PRIVACY_POLICY_PARAGRAPHS: LegalParagraph[] = [
  new LegalParagraph('最后更新时间：2025年12月24日'),
  new LegalParagraph('导言'),
  new LegalParagraph('广东高驰运动科技有限公司（以下简称"COROS"或"我们"）非常重视用户（或"您"）的隐私和个人信息保护，我们将按照法律法规的要求，尽力保护您的个人信息安全。'),
  new LegalParagraph('本个人信息保护政策（以下简称"本政策"）适用于您通过 COROS 网站、COROS 移动应用程序（"COROS App"）及其他 COROS 产品和服务使用我们的产品与服务。'),
  new LegalParagraph('本政策解释了我们如何收集、存储、使用、提供、删除您的信息，以及您享有的权利。请您认真阅读并充分理解本政策，特别是涉及个人敏感信息、系统权限、第三方共享和账号注销的条款。'),
  new LegalParagraph('一、我们如何收集和使用您的个人信息', true),
  new LegalParagraph('1. 我们将逐一说明所收集的个人信息类型及其对应用途，以便您了解每一项功能所处理的具体个人信息类别、处理目的及处理方式。'),
  new LegalParagraph('2. 为了向您提供运动记录、设备连接、账号登录、安全保障和客户支持等服务，我们可能会在获得授权后处理账号信息、设备信息、运动数据、网络状态以及必要的日志信息。'),
  new LegalParagraph('二、我们如何提供和共享您的个人信息', true),
  new LegalParagraph('除非经过您的同意，我们不会主动将您的个人信息提供至 COROS 以外的第三方。如确需对外提供，或您需要我们向任何第三方提供信息时，我们会直接征得您的同意，但法律法规另有规定的除外。'),
  new LegalParagraph('三、您如何管理自己的个人信息', true),
  new LegalParagraph('您可以通过本政策所列途径查询、更新、复制、删除您的个人信息，也可以撤回同意、注销账号、投诉举报。我们会在符合法律法规要求的期限内处理您的请求。'),
  new LegalParagraph('四、系统权限和敏感信息', true),
  new LegalParagraph('为了依据本政策收集您的信息、向您提供服务、优化我们的服务并保障您的账号安全，我们可能需要向您索取相关系统权限；其中位置等敏感权限不会默认开启，只有在您明确同意后，我们才会在您同意的范围内调用或使用。'),
  new LegalParagraph('五、本政策如何更新', true),
  new LegalParagraph('我们会持续保护您的个人信息，并根据产品功能、法律法规或监管要求更新本政策。若本政策发生重大变化，我们会以合理方式向您提示。')
];

export const SERVICE_TERMS_PARAGRAPHS: LegalParagraph[] = [
  new LegalParagraph('最后更新日期：2023年9月4日'),
  new LegalParagraph('特别提示：'),
  new LegalParagraph('本《COROS 用户协议》（以下简称"本协议"）是您（或"用户"）与广东高驰运动科技股份有限公司（以下简称"COROS"或"我们"）签订的，就使用 COROS 网站、COROS 移动应用程序（"COROS App"）及其他 COROS 产品和服务（统称为"COROS产品和服务"）等事宜订立的协议。'),
  new LegalParagraph('请您认真阅读并充分理解本协议，特别是以加粗形式提示您注意的免除或减轻 COROS 责任的条款。您有权选择同意或不同意本协议，除非您接受本协议的全部条款，否则您无权注册、登录或使用 COROS 产品和服务。'),
  new LegalParagraph('一旦您点击"本人已阅读并同意接受本协议的全部内容"并完成注册流程，即视为您已充分阅读、理解并在您点击接受当时接受本协议的所有内容，本协议即在您与 COROS 之间成立并发生法律效力，您同意接受本协议各项条款的约束。'),
  new LegalParagraph('请注意，本协议内容包括所有我们已经发布或未来可能变更或发布的各类协议、规则、公告或通知。除非法律规定或本协议有相反规定，前述内容一经公布即自动生效并成为本协议不可分割的组成部分，无需另行通知。'),
  new LegalParagraph('如您不同意本协议的内容或在您同意本协议之后我们发布生效的任何协议、规则、公告或通知，您应立即取消登录、注销账号、停止使用 COROS 产品和服务；如您继续使用，则视为您始终同意本协议的所有内容并同意遵守。'),
  new LegalParagraph('一、服务范围', true),
  new LegalParagraph('1. 我们就使用 COROS 产品和服务给予您一项个人的、不可转让的、不可转授权的、非独占性的、可撤销的许可。'),
  new LegalParagraph('2. 您应按照法律法规、本协议以及 COROS 发布的规则使用产品和服务，不得利用服务从事违法违规或侵犯他人合法权益的行为。'),
  new LegalParagraph('3. 我们可能根据产品运营情况对服务内容进行调整、更新或优化，并会在合理范围内向您提供必要提示。'),
  new LegalParagraph('二、账号与安全', true),
  new LegalParagraph('1. 您应对您账号下的所有行为负责，并妥善保管账号、密码和验证码等信息。'),
  new LegalParagraph('2. 如发现账号存在异常使用、被盗用或其他安全风险，请及时联系我们处理。'),
  new LegalParagraph('三、协议变更', true),
  new LegalParagraph('我们可能根据法律法规变化、业务调整或服务优化需要修改本协议。更新后的协议公布后即生效；如您继续使用 COROS 产品和服务，视为您同意接受更新后的协议。')
];
