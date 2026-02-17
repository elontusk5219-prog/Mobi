//
//  CoffeeCupDoodle.swift
//  Mobi
//
//  Simple coffee cup doodle for Evolution coffee slot.
//

import SwiftUI

struct CoffeeCupDoodle: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .stroke(Color.brown.opacity(0.8), lineWidth: 3)
                .frame(width: 36, height: 12)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.brown.opacity(0.8), lineWidth: 3)
                .frame(width: 28, height: 40)
            Rectangle()
                .fill(Color.brown.opacity(0.3))
                .frame(width: 24, height: 32)
                .offset(y: -4)
        }
    }
}
