import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CustomerViewModel()

    var body: some View {
        CustomerListView()
            .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
