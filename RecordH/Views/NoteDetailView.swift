import SwiftUI

struct NoteDetailView: View {
    let note: DailyNote
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Content
                Text(note.content)
                    .font(.body)
                    .foregroundColor(Theme.text)
                    .padding(.vertical)
                
                // Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.secondaryText)
                    Text(note.date.formatted(.dateTime.year().month().day().hour().minute()))
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }
                
                // Tags
                if !note.tags.isEmpty {
                    Text("标签")
                        .font(.headline)
                        .foregroundColor(Theme.text)
                        .padding(.top)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.accent.opacity(0.2))
                                .foregroundColor(Theme.text)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("笔记详情")
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var height: CGFloat = 0
        for row in rows {
            height += row.maxY
            if row !== rows.last {
                height += spacing
            }
        }
        
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            
            for item in row.items {
                let size = item.subview.sizeThatFits(proposal)
                item.subview.place(at: CGPoint(x: x, y: y), proposal: proposal)
                x += size.width + spacing
            }
            
            y += row.maxY
            if row !== rows.last {
                y += spacing
            }
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            
            if x + size.width > maxWidth && !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }
            
            currentRow.items.append(RowItem(subview: subview, size: size))
            x += size.width + spacing
        }
        
        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private class Row {
        var items: [RowItem] = []
        
        var maxY: CGFloat {
            items.map(\.size.height).max() ?? 0
        }
        
        init(items: [RowItem] = []) {
            self.items = items
        }
    }
    
    private class RowItem {
        let subview: LayoutSubview
        let size: CGSize
        
        init(subview: LayoutSubview, size: CGSize) {
            self.subview = subview
            self.size = size
        }
    }
}
