import SwiftUI

struct ValueInputField: View {
    let label: String
    @Binding var value: Double?
    @Binding var isEditing: Bool
    let unit: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            isEditing = true
        }) {
            HStack {
                Text(label)
                Spacer()
                HStack(spacing: 4) {
                    if let value = value {
                        Text(String(format: "%.1f", value))
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    } else {
                        Text("点击输入")
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    }
                    Text(unit)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
                .frame(minWidth: 100, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isEditing) {
            NumberInput(value: $value, isPresented: $isEditing, label: label, unit: unit)
        }
    }
}

struct NumberInput: View {
    @Binding var value: Double?
    @Binding var isPresented: Bool
    let label: String
    let unit: String
    @State private var textValue: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Value display
                    HStack(spacing: 8) {
                        Text(textValue.isEmpty ? "请输入数值" : textValue)
                            .font(.system(size: 42, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        Text(unit)
                            .font(.title2)
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .padding()
                    .background(Theme.color(.cardBackground, scheme: colorScheme))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Number pad
                    VStack(spacing: 15) {
                        ForEach([["7","8","9"], ["4","5","6"], ["1","2","3"], [".","0","⌫"]], id: \.self) { row in
                            HStack(spacing: 15) {
                                ForEach(row, id: \.self) { key in
                                    NumberButton(key: key) {
                                        handleInput(key)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarTitle(label, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空") {
                        textValue = ""
                        value = nil
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        if let doubleValue = Double(textValue) {
                            value = doubleValue
                        }
                        isPresented = false
                    }
                    .disabled(textValue.isEmpty)
                }
            }
            .onAppear {
                if let value = value {
                    textValue = String(format: "%.1f", value)
                }
            }
        }
    }
    
    private func handleInput(_ input: String) {
        switch input {
        case "⌫":
            if !textValue.isEmpty {
                textValue.removeLast()
            }
        case ".":
            if !textValue.contains(".") {
                textValue += textValue.isEmpty ? "0." : "."
            }
        default:
            if textValue.contains(".") {
                let parts = textValue.split(separator: ".")
                if parts.count > 1 && parts[1].count >= 1 {
                    return
                }
            }
            textValue += input
        }
    }
}

struct NumberButton: View {
    let key: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Theme.color(.cardBackground, scheme: colorScheme))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                if key == "⌫" {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                } else {
                    Text(key)
                        .font(.title)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .frame(width: 75, height: 75)
    }
}

#Preview {
    ValueInputField(
        label: "收缩压",
        value: .constant(nil),
        isEditing: .constant(false),
        unit: "mmHg"
    )
}
