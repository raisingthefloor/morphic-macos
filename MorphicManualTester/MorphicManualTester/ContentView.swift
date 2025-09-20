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

let color_bg = Color(hue: 0.307, saturation: 0.976, brightness: 0.418)

struct ContentView: View {
    @ObservedObject var manager: RegistryManager = registry
    var body: some View {
        VStack(spacing: 0.0) {
            VStack() {
                HStack(alignment: .center) {
                    Text("Manual Settings Tester")
                        .font(.headline)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.leading)
                        .padding()
                    Spacer()
                    Button(action: registry.loadSolution) {
                        Text("Load a Different Registry")
                    }
                    .padding([.top, .bottom, .trailing])
                }
                .padding(.vertical, 0.0)
                .frame(height: 40.0)
                HStack() {
                    Text(registry.load)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.bottom, 10.0)
                
            }
            .background(color_bg)
            ScrollView() {
                ForEach(registry.solutions) { solution in
                    SolutionSection(solution: solution)
                }
            }
            HStack() {
                Spacer()
                Toggle(isOn: $manager.autoApply) {
                    Text("Auto Apply")
                }.toggleStyle(SwitchToggleStyle())
                .padding(.vertical)
                HStack {
                    if(!manager.autoApply) {
                        Button(action: registry.applyAllSettings) {
                            Text("Apply Settings")
                        }
                    }
                    else {
                        Button(action: {}) {
                            Text("Apply Settings")
                        }.hidden()
                    }
                }
                .padding(.horizontal)
            }
            .background(color_bg)
        }
        .frame(width: 800.0, height: 800.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
