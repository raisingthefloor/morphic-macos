// Copyright 2020 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import SwiftUI
import MorphicSettings

let color_spinner = Color(hue: 0.307, saturation: 0.976, brightness: 0.418)
let color_wrong = Color(hue: 0.307, saturation: 0.976, brightness: 0.418)

struct Loading: View {
    @Environment(\.colorScheme) var colorScheme
    @State public var active: Bool
    var body: some View {
        VStack {
            Image("Hourglass").resizable().frame(width: 15.0, height: 25.0)
        }
    }
}

struct SolutionSection: View {
    @ObservedObject var solution: SolutionCollection
    @State var active: Bool = false
    @State private var spin = false
    var body: some View {
        VStack(spacing: 0.0) {
            HStack {
                if self.active {
                    Text("\u{25bc}")
                        .font(.headline)
                } else {
                    Text("\u{25b6}")
                        .font(.headline)
                }
                Text(solution.name)
                    .font(.headline)
                Spacer()
                Button(action: {self.solution.captureSettings()}) {
                    Text("Refresh")
                }
            }
            .onTapGesture {
                self.active = !self.active
            }
            .padding(.all)
            Section() {
                ForEach(solution.settings) {setting in
                    if self.active {
                        Divider()
                        if setting.type == Setting.ValueType.boolean {
                            BooleanEntry(setting: setting)
                        } else if setting.type == Setting.ValueType.double {
                            DoubleEntry(setting: setting)
                        } else if setting.type == Setting.ValueType.integer {
                            IntegerEntry(setting: setting)
                        } else if setting.type == Setting.ValueType.string {
                            StringEntry(setting: setting)
                        }
                    }
                }
            }
            Divider()
        }
    }
    func toggleDrop() {
        self.active = !self.active
    }
}

struct BooleanEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            if setting.loading {
                Image("Hourglass").resizable().frame(width: 11.0, height: 20.0)
            }
            Text("Boolean:")
            Toggle("", isOn: $setting.displayBool)
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct IntegerEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            if setting.loading {
                Image("Hourglass").resizable().frame(width: 11.0, height: 20.0)
            }
            Text("Integer:")
            TextField("", text: $setting.displayVal, onEditingChanged: setting.checkVal)
                .frame(width: 300.0)
                .background(setting.wrong ? Color.red.opacity(0.2) : (setting.changed ? Color.green.opacity(0.2) : Color.clear))
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct DoubleEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            if setting.loading {
                Image("Hourglass").resizable().frame(width: 11.0, height: 20.0)
            }
            Text("Double:")
            TextField("", text: $setting.displayVal, onEditingChanged: setting.checkVal)
                .frame(width: 300.0)
                .background(setting.wrong ? Color.red.opacity(0.2) : (setting.changed ? Color.green.opacity(0.2) : Color.clear))
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct StringEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            if setting.loading {
                Image("Hourglass").resizable().frame(width: 11.0, height: 20.0)
            }
            Text("String:")
            TextField("", text: $setting.displayVal, onEditingChanged: setting.checkVal)
                .frame(width: 300.0)
                .background(setting.wrong ? Color.red.opacity(0.2) : (setting.changed ? Color.green.opacity(0.2) : Color.clear))
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct SolutionViews_Previews: PreviewProvider {
    static var previews: some View {
        let solution = SolutionCollection(solutionName: "morphic.solution.name")
        solution.settings.append(SettingControl(name: "FIRST SETTING", solname: "solution", type: .boolean))
        solution.settings.append(SettingControl(name: "SECOND SETTING", solname: "solution", type: .integer))
        solution.settings.append(SettingControl(name: "THIRD SETTING", solname: "solution", type: .double))
        solution.settings.append(SettingControl(name: "FOURTH SETTING", solname: "solution", type: .string))
        let sec = SolutionSection(solution: solution)
        sec.active = true
        return sec
    }
}
