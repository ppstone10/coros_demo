import SwiftUI
import PhotosUI
import UIKit

private enum ProfilePicker: Identifiable {
    case birthDate
    case height
    case weight
    case unit
    case country

    var id: String {
        switch self {
        case .birthDate: return "birthDate"
        case .height: return "height"
        case .weight: return "weight"
        case .unit: return "unit"
        case .country: return "country"
        }
    }
}

struct ProfileCompletionView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var draft: ProfileDraft
    @State private var activePicker: ProfilePicker?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var localError: String?

    init(viewModel: LoginViewModel, router: AuthRouter) {
        self.viewModel = viewModel
        self.router = router
        let session = viewModel.state.currentSession
        let defaultName = session?.resolvedDisplayName ?? session?.account ?? ""
        self._draft = State(
            initialValue: ProfileDraft(
                avatarUri: nil,
                username: defaultName,
                birthDate: "",
                heightCm: nil,
                weightKg: nil,
                measurementSystem: .metric,
                phone: "",
                countryRegion: "中国",
                gender: nil
            )
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: backToEntrance) {
                        Text("‹")
                            .foregroundStyle(.white)
                            .font(.system(size: 44, weight: .light))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(height: 52)
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 22)
                        Text("完善个人信息")
                            .foregroundStyle(.white)
                            .font(.system(size: 36, weight: .light))
                        Spacer().frame(height: 12)
                        Text("以下信息可以帮助我们对体育科学做出更准确的预测，请仔细填写。")
                            .foregroundStyle(Color(red: 232 / 255, green: 232 / 255, blue: 236 / 255))
                            .font(.system(size: 18))
                            .lineSpacing(6)
                        Spacer().frame(height: 28)
                        ProfileAvatarButton(
                            avatarData: avatarData,
                            selectedPhoto: $selectedPhoto
                        )
                        .frame(maxWidth: .infinity)
                        Spacer().frame(height: 28)
                        ProfileTextRow(
                            label: "用户名",
                            required: true,
                            value: Binding(
                                get: { draft.username },
                                set: { draft.username = String($0.prefix(20)); localError = nil }
                            ),
                            placeholder: "输入用户名"
                        )
                        ProfileActionRow(
                            label: "出生日期",
                            required: true,
                            value: draft.birthDate,
                            placeholder: "去填写",
                            onTap: { activePicker = .birthDate }
                        )
                        ProfileActionRow(
                            label: "身高",
                            required: true,
                            value: draft.heightCm.map { "\($0) cm" } ?? "",
                            placeholder: "去填写",
                            onTap: { activePicker = .height }
                        )
                        ProfileActionRow(
                            label: "体重",
                            required: true,
                            value: draft.weightKg.map { String(format: "%.1f kg", $0) } ?? "",
                            placeholder: "去填写",
                            onTap: { activePicker = .weight }
                        )
                        ProfileActionRow(
                            label: "公英制",
                            required: false,
                            value: draft.measurementSystem.title,
                            placeholder: "",
                            onTap: { activePicker = .unit }
                        )
                        ProfileTextRow(
                            label: "手机",
                            required: false,
                            value: Binding(
                                get: { draft.phone },
                                set: { draft.phone = String($0.filter { $0.isNumber || $0 == "+" || $0 == "-" }.prefix(20)) }
                            ),
                            placeholder: "输入手机号",
                            keyboardType: .phonePad
                        )
                        ProfileActionRow(
                            label: "国家与地区",
                            required: false,
                            value: draft.countryRegion,
                            placeholder: "中国",
                            onTap: { activePicker = .country }
                        )
                        ProfileGenderRow(selected: draft.gender) {
                            draft.gender = $0
                            localError = nil
                        }
                        Spacer().frame(height: 18)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)

                VStack(spacing: 8) {
                    ErrorText(localError ?? viewModel.state.errorMessage)
                    CorosFilledButton(
                        text: "完成",
                        color: corosButtonRed,
                        enabled: viewModel.canSubmitProfile(draft),
                        isLoading: viewModel.state.isLoading,
                        buttonHeight: 56,
                        action: submitProfile
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 18)
                .background(Color.black)
            }
        }
        .sheet(item: $activePicker) { picker in
            ProfilePickerSheet(picker: picker, draft: $draft)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                let data = try? await newValue.loadTransferable(type: Data.self)
                await MainActor.run {
                    avatarData = data
                    draft.avatarUri = newValue.itemIdentifier
                }
            }
        }
    }

    private func submitProfile() {
        guard viewModel.canSubmitProfile(draft) else { return }
        viewModel.submitProfile(draft)
    }

    private func backToEntrance() {
        viewModel.clearSessionSilently()
        router.resetTo(.entrance)
    }
}

private struct ProfileAvatarButton: View {
    let avatarData: Data?
    @Binding var selectedPhoto: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack {
                if let avatarData, let image = UIImage(data: avatarData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(Circle())
                } else {
                    Image("icon_camera")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileTextRow: View {
    let label: String
    let required: Bool
    @Binding var value: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            RequiredLabel(label: label, required: required)
            TextField("", text: $value, prompt: Text(placeholder).foregroundStyle(corosMuted))
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .font(.system(size: 19))
                .multilineTextAlignment(.trailing)
                .tint(corosRed)
        }
        .frame(height: 66)
        .overlay(alignment: .bottom) { Rectangle().fill(corosLine).frame(height: 1) }
    }
}

private struct ProfileActionRow: View {
    let label: String
    let required: Bool
    let value: String
    let placeholder: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RequiredLabel(label: label, required: required)
                Spacer(minLength: 16)
                Text(value.isEmpty ? placeholder : value)
                    .foregroundStyle(value.isEmpty ? corosMuted : Color.white.opacity(0.78))
                    .font(.system(size: 19))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image("right_more")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .frame(height: 66)
            .overlay(alignment: .bottom) { Rectangle().fill(corosLine).frame(height: 1) }
        }
        .buttonStyle(.plain)
    }
}

private struct RequiredLabel: View {
    let label: String
    let required: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(label).foregroundStyle(.white).font(.system(size: 19))
            if required { Text("*").foregroundStyle(corosRed).font(.system(size: 17)) }
        }
        .frame(minWidth: 96, alignment: .leading)
    }
}

private struct ProfileGenderRow: View {
    let selected: ProfileGender?
    let onSelected: (ProfileGender) -> Void

    var body: some View {
        HStack(spacing: 12) {
            RequiredLabel(label: "性别", required: true)
            Spacer()
            ForEach(ProfileGender.allCases, id: \.self) { gender in
                Button(action: { onSelected(gender) }) {
                    HStack(spacing: 8) {
                        Image(gender.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text(gender.title)
                    }
                    .foregroundStyle(selected == gender ? corosRed : .white)
                    .font(.system(size: 18))
                    .frame(width: 86, height: 48)
                    .background(Color(red: 27 / 255, green: 27 / 255, blue: 29 / 255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selected == gender ? corosRed : .clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 72)
    }
}

private struct ProfilePickerSheet: View {
    let picker: ProfilePicker
    @Binding var draft: ProfileDraft
    @Environment(\.dismiss) private var dismiss

    @State private var date = Calendar.current.date(from: DateComponents(year: 2002, month: 11, day: 17)) ?? Date()
    @State private var height = 175
    @State private var weightTenths = 600
    @State private var unit: ProfileMeasurementSystem = .metric
    @State private var country = "中国"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image("ic_profile_close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(title).foregroundStyle(.white).font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: confirm) {
                    Image("ic_profile_check")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)
            .frame(height: 58)
            .padding(.horizontal, 20)

            switch picker {
            case .birthDate:
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
            case .height:
                Picker("", selection: $height) {
                    ForEach(90...230, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            case .weight:
                Picker("", selection: $weightTenths) {
                    ForEach(300...2200, id: \.self) { value in
                        Text(String(format: "%.1f", Double(value) / 10.0))
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            case .unit:
                Picker("", selection: $unit) {
                    ForEach(ProfileMeasurementSystem.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            case .country:
                Picker("", selection: $country) {
                    ForEach(["中国", "美国", "英国", "日本"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            }
            Spacer(minLength: 0)
        }
        .background(Color(red: 27 / 255, green: 27 / 255, blue: 29 / 255).ignoresSafeArea())
        .onAppear {
            height = draft.heightCm ?? 175
            weightTenths = Int(((draft.weightKg ?? 60.0) * 10).rounded())
            unit = draft.measurementSystem
            country = draft.countryRegion
        }
    }

    private var title: String {
        switch picker {
        case .birthDate: return "出生日期"
        case .height: return "身高 (cm)"
        case .weight: return "体重 (kg)"
        case .unit: return "公英制"
        case .country: return "国家与地区"
        }
    }

    private func confirm() {
        switch picker {
        case .birthDate:
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            draft.birthDate = "\(components.year ?? 2002)年\(components.month ?? 1)月\(components.day ?? 1)日"
        case .height:
            draft.heightCm = height
        case .weight:
            draft.weightKg = Double(weightTenths) / 10.0
        case .unit:
            draft.measurementSystem = unit
        case .country:
            draft.countryRegion = country
        }
        dismiss()
    }
}
