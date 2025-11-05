//
//  NationalitySelectionView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct NationalitySelectionView: View {
    @Binding var selectedNationality: Nationality?
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Choose Your Nation")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select a nationality to rule all villages of that nation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Nationality.getAll(), id: \.name) { nationality in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedNationality = nationality
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 20) {
                                Text(nationality.flag)
                                    .font(.system(size: 60))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(nationality.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Text("Rule the \(nationality.name) empire")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}
