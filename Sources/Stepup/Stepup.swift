import SwiftUI

public enum StepupViewState {
    case collapsed, expanded
}
public protocol StepupPageViewProvidable {
    var gradientColor1: Color { get }
    var gradientColor2: Color { get }
    @MainActor func contentView(isCollapsed: Bool) -> AnyView
}

public struct StepupView: View {
    @State var currentPageIndex: Int
    var collapsedStateHeightFraction: CGFloat
    var pages: [StepupPageViewProvidable]
    
    public init(currentPageIndex: Int = 0, collapsedStateHeightFraction: CGFloat = 0.1, pages: [StepupPageViewProvidable]) {
        self.currentPageIndex = currentPageIndex
        self.collapsedStateHeightFraction = collapsedStateHeightFraction
        self.pages = pages
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                ForEach(pages.indices, id: \.self) { index in
                    let page = pages[index]
                    let offset = (geometry.size.height * collapsedStateHeightFraction * CGFloat(index))
                    let height = geometry.size.height - offset
                    StepupPageView(currentPageIndex: $currentPageIndex, page: page, pageIndex: index, totalPages: pages.count)
                        .frame(width: geometry.size.width, height: height)
                        .offset(y: offset + (index <= currentPageIndex ? 0 : height + geometry.safeAreaInsets.bottom))
                        .animation(.easeInOut, value: currentPageIndex)
                }
            }
        }
    }
}

struct StepupPageView: View {
    @Binding var currentPageIndex:Int
    let page: StepupPageViewProvidable
    let pageIndex: Int
    let totalPages: Int
    @State private var viewState: StepupViewState
    
    init(currentPageIndex: Binding<Int>, page: StepupPageViewProvidable, pageIndex: Int, totalPages: Int) {
        self._currentPageIndex = currentPageIndex
        self.page = page
        self.pageIndex = pageIndex
        self.totalPages = totalPages
        self._viewState = State(initialValue: currentPageIndex.wrappedValue > pageIndex ? .collapsed : .expanded)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack {
                page.contentView(isCollapsed: viewState == .collapsed)
                Spacer()
                formButtons
            }
            .padding(20)
            .overlay(overlayButton)
            .onChange(of: currentPageIndex) { oldValue, newValue in
                viewState = newValue > pageIndex ? .collapsed : .expanded
            }
        }
    }
    
    var formButtons: some View {
        HStack {
            let nextTitle = currentPageIndex < totalPages - 1 ? "Next" : "Start"
            FormButton(nextTitle) {
                currentPageIndex += 1
            }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
    var overlayButton: some View {
        Button {
            currentPageIndex = pageIndex
        } label: {
            Color.clear
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .disabled(viewState == .expanded)
        .opacity(viewState == .expanded ? 0 : 1)
    }
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [page.gradientColor1, page.gradientColor2]),
            startPoint: viewState == .collapsed ? .leading : .top, endPoint: viewState == .collapsed ? .trailing : .bottom)
        .animation(.easeInOut, value: viewState)
        .ignoresSafeArea()
    }
}

private struct FormButton: View {
    let text: String
    let onAction: () -> Void
    init(_ text: String, onAction: @escaping () -> Void) {
        self.text = text
        self.onAction = onAction
    }
    var body: some View {
        Button {
            onAction()
        } label: {
            Text(text)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.primary)
        
    }
}

public struct MockStepupPageView: StepupPageViewProvidable {
    public var gradientColor1: Color
    public var gradientColor2: Color
    public init(_ c1: Color = .red, _ c2: Color = .green) {
        gradientColor1 = c1
        gradientColor2 = c2
    }
    public func contentView(isCollapsed: Bool) -> AnyView {
        if isCollapsed {
            return AnyView(collapsedView)
        } else {
            return AnyView(expandedView)
        }
    }
    var expandedView: some View {
        Text("ExpandedView")
    }
    var collapsedView: some View {
        Text("CollapsedView")
    }
}
public struct MockSingleStepupPageView: StepupPageViewProvidable {
    public var gradientColor1: Color
    public var gradientColor2: Color
    public init(_ c1: Color = .red, _ c2: Color = .green) {
        gradientColor1 = c1
        gradientColor2 = c2
    }
    @MainActor
    public func contentView(isCollapsed: Bool) -> AnyView {
        AnyView(body(isCollapsed: isCollapsed))
    }
    @MainActor
    private func body(isCollapsed: Bool) -> some View {
        VStack {
            Text("Dette er en tekst")
                .frame(alignment: isCollapsed ? .leading : .center)
            Text("Text 2")
            Spacer()
            Text("Text 3")
        }
        .animation(.easeInOut, value: isCollapsed)
    }
}

#Preview {
    StepupView(pages: [
        MockStepupPageView(.red, .green),
        MockSingleStepupPageView(.cyan, .black),
        MockStepupPageView(.blue, .white),
        MockStepupPageView(.pink, .black),
        MockStepupPageView(.purple, .brown),
        MockStepupPageView()]
    )
}
