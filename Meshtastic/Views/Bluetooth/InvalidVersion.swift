//
//  InvalidVersion.swift
//  Meshtastic
//
//  Copyright(c) Garth Vander Houwen 7/13/22.
//
import SwiftUI

struct InvalidVersion: View {
	
	@State var minimumVersion = ""
	@State var version = ""

	var body: some View {
		
		VStack {
			
			Text("Update your firmware")
				.font(.largeTitle)
				.foregroundColor(.orange)
			
			Divider()
			
			VStack {
				
				if version != "1.2.65" {
					
					Text("The Meshtastic Apple apps support firmware version \(minimumVersion) and above. You are running version \(version)")
						.font(.title2)
						.padding(.bottom)
					
				} else {
					
					Text("The Meshtastic Apple apps support firmware version \(minimumVersion) and above.")
						.font(.title2)
						.padding(.bottom)
				}
				
				Link("Firmware update docs", destination: URL(string: "https://meshtastic.org/docs/getting-started/flashing-firmware/")!)
					.font(.title)
					.padding()
				
				Link("Additional help", destination: URL(string: "https://meshtastic.org/docs/faq")!)
					.font(.title)
					.padding()
				
			
			}
			.padding()
			
			if version == "1.2.65" {
				
				Divider()
					.padding(.top)
				
				VStack{
					
					Text("🦕 End of life Version 🦖 ☄️")
						.font(.title3)
						.foregroundColor(.orange)
						.padding(.bottom)
					
					Text("Version \(minimumVersion) includes breaking changes to devices and the client apps. Only nodes version \(minimumVersion) and above are supported.")
						.font(.caption)
						.padding([.leading, .trailing])
					
					Text("There is a build for 1.2 EOL under Other Versions in TestFlight that will be available until the end of November 2022.")
						.font(.caption)
						.padding()
					
					Link("Version 1.2 End of life (EOL) Info", destination: URL(string: "https://meshtastic.org/docs/1.2-End-of-life/")!)
						.font(.callout)
					
				}.padding()
			}
		}
	}
}
