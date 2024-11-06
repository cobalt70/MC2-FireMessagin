//
//  ContentView.swift
//  fcmNotificationServer
//
//  Created by Giwoo Kim on 5/25/24.
//

import SwiftUI

struct ContentView: View {
    @State private var showMessage = false
    let sendNotificaiton = SendNotification()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button(action: {
                sendNotificaiton.sendPushNotification()
                showMessage = true
                sleep(3)
                showMessage = false
                
            }) {
                Label("Send Remote MSG", systemImage: "plus")
            }
            
            if showMessage {
                Text("Hidden message sent!")
                    .font(.headline)
                    .foregroundColor(.green)
               
                
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
