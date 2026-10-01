import Foundation
import SPAGCore
import SwiftUI

/// The shared root screen plus login card links, which only the School app handles.
public struct SchoolRootView: View {
    @Bindable var classServices: SchoolClassServices

    public init(classServices: SchoolClassServices) {
        self.classServices = classServices
    }

    public var body: some View {
        RootView()
            .sheet(item: $classServices.pendingJoin) { details in
                NavigationStack {
                    JoinClassView(prefilled: details)
                }
            }
            .onOpenURL { classServices.handle(url: $0) }
    }
}
