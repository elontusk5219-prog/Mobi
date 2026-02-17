//
//  MemoryDiaryView.swift
//  Mobi
//
//  Diary modal: daily summary with handwritten style + sentiment doodle.
//  含「Star 教会了我」铭印区块（C5）。
//

import SwiftUI

struct MemoryDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: DiaryEntry?
    @State private var isLoading = true

    private static let maxImprintsToShow = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if isLoading {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let entry = entry {
                        diaryContent(entry)
                        imprintSection
                    } else {
                        Text("暂无记录")
                            .font(.custom("Georgia", size: 18))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                        imprintSection
                    }
                }
                .padding()
            }
            .navigationTitle("日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                entry = await MemoryDiaryService.fetchYesterdaySummary()
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private var imprintSection: some View {
        let imprints = ImprintService.getCurrentUserImprints().prefix(Self.maxImprintsToShow)
        VStack(alignment: .leading, spacing: 12) {
            Text("Star 教会了我")
                .font(.custom("Georgia", size: 16))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            if imprints.isEmpty {
                Text("还没有铭印")
                    .font(.custom("Georgia", size: 15))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(Array(imprints.enumerated()), id: \.offset) { idx, rec in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.custom("Georgia", size: 18))
                        Text(rec.content)
                            .font(.custom("Georgia", size: 16))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(idx == 0 ? Color.accentColor.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                    .modifier(ImprintHighlightModifier(isFirst: idx == 0))
                }
            }
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private func diaryContent(_ e: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(e.date, style: .date)
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                sentimentDoodle(e.sentiment)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(e.bullets.enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.custom("Georgia", size: 18))
                        Text(bullet)
                            .font(.custom("Georgia", size: 18))
                            .lineSpacing(4)
                    }
                }
            }
        }
    }

    private struct ImprintHighlightModifier: ViewModifier {
        let isFirst: Bool
        @State private var scale: CGFloat = 0.95
        func body(content: Content) -> some View {
            content
                .scaleEffect(isFirst ? scale : 1.0)
                .onAppear {
                    if isFirst {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { scale = 1.0 }
                    }
                }
        }
    }

    @ViewBuilder
    private func sentimentDoodle(_ s: DiarySentiment) -> some View {
        Group {
            switch s {
            case .sun:
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            case .moon:
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
            case .heart:
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
            }
        }
    }
}
