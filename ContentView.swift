import SwiftUI
import Combine
import Foundation

// Needs keys because each sol is its own key, not integrated inside an array

// Each day or sol has its own data
struct MarsWeather: Identifiable {
    let id: String
    let sol: String
    let temperature: Double
    let windSpeed: Double
    let pressure: Double
}

// Helps to store temp, wind speed, and pressure
// var names are denoted by the JSON format of the API data
struct SolData: Codable {
    let AT: WeatherData?
    let HWS: WeatherData?
    let PRE: WeatherData?
}

// For the display of averages of weather data
struct WeatherData: Codable {
    let av: Double?
}

// Main area where decoding of API response occurs
struct MarsWeatherResponse: Decodable {
    let sol_keys: [String]
    let sols: [String: SolData]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sol_keys = try container.decode([String].self, forKey: .sol_keys)

        let fullContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)

        sols = try sol_keys.reduce(into: [String: SolData]()) { result, solKey in
            guard let codingKey = DynamicCodingKeys(stringValue: solKey) else {
                print("Failed to create key for sol: \(solKey)")
                return
            }
            result[solKey] = try fullContainer.decode(SolData.self, forKey: codingKey)
        }
    }

    enum CodingKeys: String, CodingKey {
        case sol_keys
    }

    struct DynamicCodingKeys: CodingKey {
        let stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        let intValue: Int? = nil
        init?(intValue: Int) { return nil }
    }
}

class MarsWeatherFetcher: ObservableObject {
    @Published var weather: [MarsWeather] = []
    @Published var isLoading = true

    func fetchData() {
        // API connections
        guard let url = URL(string: "https://api.nasa.gov/insight_weather/?api_key=2a8FODFGhDLVkiIxC4KjGE9Mua8Ld7L9doyP0rS0&feedtype=json&ver=1.0".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            print("Invalid URL")
            return
        }

        print("Fetching data from: \(url)")

        // For debugging purposes and for tracking the API
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status Code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // JSON decoded into the MarsWeather struct to be processed
                let response = try JSONDecoder().decode(MarsWeatherResponse.self, from: data)
                
                print("Successfully decoded: \(response)")

                DispatchQueue.main.async {
                    print("sol_keys: \(response.sol_keys)")
                    
                    self.weather = response.sol_keys.compactMap { solKey in
                        guard let solData = response.sols[solKey] else {
                            print("Missing sol data for key: \(solKey)")
                            return nil
                        }
                        
                        print("Sol \(solKey) - AT: \(solData.AT?.av), HWS: \(solData.HWS?.av), PRE: \(solData.PRE?.av)")
                        
                        return MarsWeather(
                            id: solKey,
                            sol: solKey,
                            temperature: solData.AT?.av ?? 0.0,
                            windSpeed: solData.HWS?.av ?? 0.0,
                            pressure: solData.PRE?.av ?? 0.0
                        )
                    }
                    
                    self.isLoading = false
                }
            } catch {
                print("Error decoding: \(error.localizedDescription)")
            }

            do {
                let response = try JSONDecoder().decode(MarsWeatherResponse.self, from: data)
                print("Decoded response: \(response)")

                // Main thread updates UI with the info that has been decoded
                DispatchQueue.main.async {
                    self.weather = response.sol_keys.compactMap { solKey in
                        guard let solData = response.sols[solKey] else { return nil }
                        return MarsWeather(
                            id: solKey,
                            sol: solKey,
                            temperature: solData.AT?.av ?? 0.0,
                            windSpeed: solData.HWS?.av ?? 0.0,
                            pressure: solData.PRE?.av ?? 0.0
                        )
                    }
                    self.isLoading = false
                }
            } catch {
                print("Error decoding: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct ContentView: View {
    @StateObject private var fetcher = MarsWeatherFetcher()

    var body: some View {
        
        // Structure that was implemented
        // Might use TabView to separate all the different weather data
        NavigationView {
            VStack {
                // Implements this type of string for user "interaction"
                if fetcher.isLoading {
                    Text("Loading Mars weather data...")
                } else if fetcher.weather.isEmpty {
                    Text("No Mars weather data available.")
                } else {
                    // Weather data displayed
                    List(fetcher.weather) { weather in
                        VStack(alignment: .leading) {
                            Text("Sol: \(weather.sol)")
                                .font(.headline)
                            Text("Temperature: \(weather.temperature, specifier: "%.1f") °C")
                            Text("Wind Speed: \(weather.windSpeed, specifier: "%.1f") m/s")
                            Text("Pressure: \(weather.pressure, specifier: "%.1f") Pa")
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mars Weather")
            
            // Calls fetch data when the actual view appears
            .onAppear {
                fetcher.fetchData()
            }
        }
    }
}
