/*
 Abstract:
 A view showing the details for a node.
 */

import SwiftUI
import WeatherKit
import MapKit
import CoreLocation

struct NodeDetail: View {
	
	@Environment(\.managedObjectContext) var context
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	@State var satsInView = 0
	@State private var mapType: MKMapType = .standard
	@State var waypointCoordinate: CLLocationCoordinate2D?
	@State var editingWaypoint: Int = 0
	@State private var showingDetailsPopover = false
	@State private var showingShutdownConfirm: Bool = false
	@State private var showingRebootConfirm: Bool = false
	@State private var presentingWaypointForm = false
	@State private var showOverlays: Bool = true
	@State private var overlays: [MapViewSwiftUI.Overlay] = []
	@State private var customMapOverlay: MapViewSwiftUI.CustomMapOverlay? = MapViewSwiftUI.CustomMapOverlay(
			mapName: "offlinemap",
			tileType: "png",
			canReplaceMapContent: true
		)
	
	var node: NodeInfoEntity
	
	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: false)],
				  predicate: NSPredicate(
					format: "expire == nil || expire >= %@", Date() as NSDate
				  ), animation: .easeIn)
	private var waypoints: FetchedResults<WaypointEntity>
	
	/// The current weather condition for the city.
	@State private var condition: WeatherCondition?
	@State private var temperature: Measurement<UnitTemperature>?
	@State private var symbolName: String = "cloud.fill"
	
	@State private var attributionLink: URL?
	@State private var attributionLogo: URL?
	
	var body: some View {
		
		let hwModelString = node.user?.hwModel ?? "UNSET"
		
		NavigationStack {
			GeometryReader { bounds in
				VStack {
					if node.positions?.count ?? 0 > 0 {
						let mostRecent = node.positions?.lastObject as! PositionEntity
						ZStack {
							let annotations = node.positions?.array as! [PositionEntity]
							ZStack {
								MapViewSwiftUI(onLongPress: { coord in
									waypointCoordinate = coord
									editingWaypoint = 0
									presentingWaypointForm = true
								}, onWaypointEdit: { wpId in
									if wpId > 0 {
										editingWaypoint = wpId
										presentingWaypointForm = true
									}
								}, positions: annotations, waypoints: Array(waypoints), mapViewType: mapType,
									centerOnPositionsOnly: true,
									customMapOverlay: self.customMapOverlay,
									overlays: self.overlays
									
								)
								VStack (alignment: .leading) {
									Spacer()
									HStack (alignment: .bottom, spacing: 1) {
							
										Picker("Map Type", selection: $mapType) {
											ForEach(MeshMapType.allCases) { map in
												Text(map.description).tag(map.MKMapTypeValue())
											}
										}
										.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
										.pickerStyle(.menu)
										.padding(5)
										VStack {
											if mostRecent.satsInView > 0 {
												Text("Sats: \(mostRecent.satsInView)")
													.font(.caption)
													.padding(.bottom, 1)
											}
											Label(temperature?.formatted() ?? "??", systemImage: symbolName)
												.font(.caption)
										}
										.padding(10)
										.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
										.padding(5)
									}
								}
							}
							.ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
							.frame(idealWidth: bounds.size.width, minHeight: bounds.size.height / 1.65)
						}
					} else {
						HStack {
						}
						.padding([.top], 20)
					}
					
					ScrollView {
						Divider()
						if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
							HStack {
								VStack(alignment: .center) {
									CircleText(text: node.user?.shortName ?? "???", color: .accentColor, circleSize: 75, fontSize: 26)
								}
								Divider()
								VStack {
									if node.user != nil {
										Image(hwModelString)
											.resizable()
											.aspectRatio(contentMode: .fill)
											.frame(width: 100, height: 100)
											.cornerRadius(5)
										
										Text(String(hwModelString))
											.foregroundColor(.gray)
											.font(.largeTitle).fixedSize()
									}
								}
								
								if node.snr > 0 {
									Divider()
									VStack(alignment: .center) {
										
										Image(systemName: "waveform.path")
											.font(.title)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
											.padding(.bottom, 10)
										Text("SNR").font(.largeTitle).fixedSize()
										Text("\(String(format: "%.2f", node.snr)) dB")
											.font(.largeTitle)
											.foregroundColor(.gray)
											.fixedSize()
									}
								}
								
								if node.telemetries?.count ?? 0 >= 1 {
									
									let mostRecent = node.telemetries?.lastObject as! TelemetryEntity
									Divider()
									VStack(alignment: .center) {
										BatteryGauge(batteryLevel: Double(mostRecent.batteryLevel))
										if mostRecent.voltage > 0 {
											
											Text(String(format: "%.2f", mostRecent.voltage) + " V")
												.font(.title)
												.foregroundColor(.gray)
												.fixedSize()
										}
									}
									.padding()
								}
							}
							.padding()
							
							Divider()
							HStack(alignment: .center) {
								
								VStack {
									HStack {
										Image(systemName: "person")
											.font(.title)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("user").font(.title)+Text(":").font(.title)
									}
									Text("!\(String(format:"%02x", node.num))")
										.font(.title).foregroundColor(.gray)
								}
								Divider()
								VStack {
									HStack {
										Image(systemName: "number")
											.font(.title2)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("Node Number:").font(.title)
									}
									Text(String(node.num)).font(.title).foregroundColor(.gray)
								}
								Divider()
								VStack{
									HStack {
										Image(systemName: "globe")
											.font(.title)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("MAC Address: ").font(.title)
										
									}
									Text(String(node.user?.macaddr?.macAddressString ?? "not a valid mac address"))
										.font(.title)
										.foregroundColor(.gray)
								}
								Divider()
								VStack{
									HStack {
										Image(systemName: "clock.badge.checkmark.fill")
											.font(.title)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("heard.last").font(.title)+Text(":").font(.title)
										
									}
									DateTimeText(dateTime: node.lastHeard)
										.font(.title3)
										.foregroundColor(.gray)
								}
							}
							Divider()
							
						} else {
							
							HStack {
								
								VStack(alignment: .center) {
									CircleText(text: node.user?.shortName ?? "???", color: .accentColor)
								}
								Divider()
								VStack {
									if node.user != nil {
										Image(node.user!.hwModel ?? NSLocalizedString("unset", comment: "Unset"))
											.resizable()
											.frame(width: 75, height: 75)
											.cornerRadius(5)
										Text(String(node.user!.hwModel ?? NSLocalizedString("unset", comment: "Unset")))
											.font(.callout).fixedSize()
									}
								}
								
								if node.snr > 0 {
									Divider()
									VStack(alignment: .center) {
										
										Image(systemName: "waveform.path")
											.font(.title)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("SNR").font(.title2).fixedSize()
										Text("\(String(format: "%.2f", node.snr)) dB")
											.font(.title2)
											.foregroundColor(.gray)
											.fixedSize()
									}
								}
								
								if node.telemetries?.count ?? 0 >= 1 {
									let mostRecent = node.telemetries?.lastObject as! TelemetryEntity
									Divider()
									VStack(alignment: .center) {
										BatteryGauge(batteryLevel: Double(mostRecent.batteryLevel))
										if mostRecent.voltage > 0 {
											
											Text(String(format: "%.2f", mostRecent.voltage) + " V")
												.font(.callout)
												.foregroundColor(.gray)
												.fixedSize()
										}
									}
								}
							}
							Divider()
							HStack(alignment: .center) {
								VStack {
									HStack {
										Image(systemName: "person")
											.font(.title2)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("User Id:").font(.title2)
									}
									Text(node.user?.userId ?? "??????").font(.title3).foregroundColor(.gray)
								}
								Divider()
								VStack {
									HStack {
										Image(systemName: "number")
											.font(.title2)
											.foregroundColor(.accentColor)
											.symbolRenderingMode(.hierarchical)
										Text("Node Number:").font(.title2)
									}
									Text(String(node.num)).font(.title3).foregroundColor(.gray)
								}
							}
							Divider()
							HStack {
								Image(systemName: "globe")
									.font(.headline)
									.foregroundColor(.accentColor)
									.symbolRenderingMode(.hierarchical)
								Text("MAC Address: ")
								Text(String(node.user?.macaddr?.macAddressString ?? "not a valid mac address")).foregroundColor(.gray)
							}
							.padding([.bottom], 10)
							Divider()
						}
						
						VStack {
							
							if (node.positions?.count ?? 0) > 0 {
								
								NavigationLink {
									PositionLog(node: node)
								} label: {
									
									Image(systemName: "building.columns")
										.symbolRenderingMode(.hierarchical)
										.font(.title)
									
									Text("Position Log")
										.font(.title3)
								}
								.fixedSize(horizontal: false, vertical: true)
								Divider()
							}
							
							if (node.telemetries?.count ?? 0) > 0 {
								
								NavigationLink {
									DeviceMetricsLog(node: node)
								} label: {
									
									Image(systemName: "flipphone")
										.symbolRenderingMode(.hierarchical)
										.font(.title)
									
									Text("Device Metrics Log")
										.font(.title3)
								}
								Divider()
								NavigationLink {
									EnvironmentMetricsLog(node: node)
								} label: {
									
									Image(systemName: "chart.xyaxis.line")
										.symbolRenderingMode(.hierarchical)
										.font(.title)
									
									Text("Environment Metrics Log")
										.font(.title3)
								}
								Divider()
							}
						}
						
						if self.bleManager.connectedPeripheral != nil && self.bleManager.connectedPeripheral.num == node.num && self.bleManager.connectedPeripheral.num == node.num {
							
							HStack {
								
								if node.metadata != nil && node.metadata?.canShutdown ?? false {
									
									Button(action: {
										showingShutdownConfirm = true
									}) {
										
										Label("Power Off", systemImage: "power")
									}
									.buttonStyle(.bordered)
									.buttonBorderShape(.capsule)
									.controlSize(.large)
									.padding()
									.confirmationDialog(
										"are.you.sure",
										isPresented: $showingShutdownConfirm
									) {
										Button("Shutdown Node?", role: .destructive) {
											if !bleManager.sendShutdown(fromUser: node.user!, toUser: node.user!) {
												print("Shutdown Failed")
											}
										}
									}
								}
								
								Button(action: {
									showingRebootConfirm = true
								}) {
									Label("reboot", systemImage: "arrow.triangle.2.circlepath")
								}
								.buttonStyle(.bordered)
								.buttonBorderShape(.capsule)
								.controlSize(.large)
								.padding()
								.confirmationDialog("are.you.sure",
													isPresented: $showingRebootConfirm
								) {
									Button("reboot.node", role: .destructive) {
										if !bleManager.sendReboot(fromUser: node.user!, toUser: node.user!) {
											print("Reboot Failed")
										}
									}
								}
							}
							.padding(5)
							Divider()
						}
						
						VStack {
							AsyncImage(url: attributionLogo) { image in
								image
									.resizable()
									.scaledToFit()
							} placeholder: {
								ProgressView()
									.controlSize(.mini)
							}
							.frame(height: 15)
							
							Link("Other data sources", destination: attributionLink ?? URL(string: "https://weather-data.apple.com/legal-attribution.html")!)
						}
						.font(.footnote)
					}
				}
				.edgesIgnoringSafeArea([.leading, .trailing])
				.sheet(isPresented: $presentingWaypointForm ) {//,  onDismiss: didDismissSheet) {
					WaypointFormView(coordinate: waypointCoordinate ?? LocationHelper.DefaultLocation, waypointId: editingWaypoint)
							.presentationDetents([.medium, .large])
							.presentationDragIndicator(.automatic)
				}
				.navigationBarTitle(String(node.user?.longName ?? NSLocalizedString("unknown", comment: "")), displayMode: .inline)
				.navigationBarItems(trailing:
					ZStack {
					ConnectedDevice(
						bluetoothOn: bleManager.isSwitchedOn,
						deviceConnected: bleManager.connectedPeripheral != nil,
						name: (bleManager.connectedPeripheral != nil) ? bleManager.connectedPeripheral.shortName : "????")
				})
				.onAppear {
					self.bleManager.context = context
				}
				.task(id: node.num) {
					do {
						
						if node.positions?.count ?? 0 > 0 {
							
							let mostRecent = node.positions?.lastObject as! PositionEntity
							
							let weather = try await WeatherService.shared.weather(for: mostRecent.nodeLocation!)
							condition = weather.currentWeather.condition
							temperature = weather.currentWeather.temperature
							symbolName = weather.currentWeather.symbolName
							
							let attribution = try await WeatherService.shared.attribution
							attributionLink = attribution.legalPageURL
							attributionLogo = colorScheme == .light ? attribution.combinedMarkLightURL : attribution.combinedMarkDarkURL
							
						}
						
					} catch {
						print("Could not gather weather information...", error.localizedDescription)
						condition = .clear
						symbolName = "cloud.fill"
					}
				}
			}
		}
	}
}
