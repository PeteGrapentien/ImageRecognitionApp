//
//  ContentView.swift
//  PhotoUpload
//
//  Created by Peter Grapentien on 1/20/23.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var camera = Camera()
    
    var body: some View {
        
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                Spacer()
                Label(camera.textPrediction, systemImage: "")
                    .background(Color.white)
                    .multilineTextAlignment(.center)
                
                HStack{
                    Button(action: {
                        camera.isTaken.toggle()
                    }, label: {
                        ZStack {
                            if camera.isTaken {
                                Button(action: {
                                    camera.isTaken = false
                                }, label: {
                                    Text("Save")
                                        .foregroundColor(.black)
                                        .fontWeight(.semibold)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                            
                                }).padding(.leading)
                                
                                Spacer()
                                
                            } else {
                                Circle()
                                    .fill(Color(camera.cameraButtonColor as! CGColor))
                                    .frame(width: 65, height: 70)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        }
                    })
                }
                
            }
        }
        .onAppear(perform: {
            camera.checkCameraPermission()
            
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
