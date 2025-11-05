//
//  ContentView.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var showNationalitySelection = true

    var body: some View {
        if gameManager.playerNationality == nil && showNationalitySelection {
            NationalitySelectionView(
                selectedNationality: $gameManager.playerNationality,
                isPresented: $showNationalitySelection
            )
        } else {
            GameView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
