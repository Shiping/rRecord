import Foundation
import SwiftUI
import HealthKit
import Combine

@available(macOS 10.13, iOS 15.0, *)
public class HealthStore: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
        @Published var dailyNotes: [DailyNote] = [] {
            didSet {
                saveData()
                self.objectWillChange.send()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .init("NotesDidUpdate"), object: nil)
                }
            }
        }

// MARK: - Internal Properties
let healthStore = HKHealthStore()
var lastUpdate: Date?
    let fileManager = FileManager.default
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - File Storage URLs
    var documentsDirectory: URL {
        get {
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }
    }

    var profileURL: URL {
        documentsDirectory.appendingPathComponent("userProfile.json")
    }

    var recordsURL: URL {
        documentsDirectory.appendingPathComponent("healthRecords.json")
    }

    var notesURL: URL {
        documentsDirectory.appendingPathComponent("dailyNotes.json")
    }

    // MARK: - Initialization
    public override init() {
        super.init()
        print("Initializing HealthStore")
        do {
            try createDirectoryIfNeeded()
            loadData() // Load saved data from disk
        } catch {
            print("Error initializing storage: \(error)")
        }
    }
    
    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        }
    }
    
    @discardableResult
    func loadData() -> Bool {
        // Load profile
        if let profileData = try? Data(contentsOf: profileURL),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            DispatchQueue.main.async {
                self.userProfile = profile
            }
        }
        
        // Load records
        if let recordsData = try? Data(contentsOf: recordsURL),
           let records = try? JSONDecoder().decode([HealthRecord].self, from: recordsData) {
            DispatchQueue.main.async {
                self.healthRecords = records
            }
        }
        
        // Load notes
        if let notesData = try? Data(contentsOf: notesURL),
           let notes = try? JSONDecoder().decode([DailyNote].self, from: notesData) {
            DispatchQueue.main.async {
                self.dailyNotes = notes.sorted(by: { $0.date > $1.date })
            }
            return true
        }
        return false
    }

    func saveData() {
        do {
            if let profile = userProfile {
                let profileData = try JSONEncoder().encode(profile)
                try profileData.write(to: profileURL)
            }
            
            let recordsData = try JSONEncoder().encode(healthRecords)
            try recordsData.write(to: recordsURL)
            
            let notesData = try JSONEncoder().encode(dailyNotes)
            try notesData.write(to: notesURL)
        } catch {
            print("Error saving data: \(error)")
        }
    }

    // MARK: - Refresh Management
    private var isFetchingData = false

    private func fetchLatestHealthData() {
        print("fetchLatestHealthData called")
        DispatchQueue.main.async {
            print("fetchLatestHealthData - inside DispatchQueue.main.async")
        }
        fetchSteps()
        fetchHeartRate()
        fetchActiveEnergy()
        fetchRestingEnergy()
        fetchDistance()
        fetchBloodOxygen()
        fetchFlightsClimbed()
        fetchSleep()
        DispatchQueue.main.async {
            print("Data refreshed, notes count: \(self.dailyNotes.count)")
            self.isFetchingData = false
        }
    }

    private func fetchSteps() {
        print("fetchLatestHealthData - calling fetchSteps")
        print("Fetching steps data...")
        // Fetch steps data logic here
    }

    private func fetchHeartRate() {
        print("fetchLatestHealthData - calling fetchHeartRate")
        print("Fetching heart rate data...")
        // Fetch heart rate data logic here
    }

    private func fetchActiveEnergy() {
        print("fetchLatestHealthData - calling fetchActiveEnergy")
        print("Fetching active energy data...")
        // Fetch active energy data logic here
    }

    private func fetchRestingEnergy() {
        print("fetchLatestHealthData - calling fetchRestingEnergy")
        print("Fetching resting energy data...")
        // Fetch resting energy data logic here
    }

    private func fetchDistance() {
        print("fetchLatestHealthData - calling fetchDistance")
        print("Fetching distance data...")
        // Fetch distance data logic here
    }

    private func fetchBloodOxygen() {
        print("fetchLatestHealthData - calling fetchBloodOxygen")
        print("Fetching blood oxygen data...")
        // Fetch blood oxygen data logic here
    }

    private func fetchFlightsClimbed() {
        print("fetchLatestHealthData - calling fetchFlightsClimbed")
        print("Fetching flights climbed data...")
        // Fetch flights climbed data logic here
    }

    private func fetchSleep() {
        print("fetchLatestHealthData - calling fetchSleep")
        print("Fetching sleep data...")
        // Fetch sleep data logic here
    }
    
    // MARK: - iCloud Sync
    func manualSyncToICloud(completion: @escaping (Bool) -> Void) {
        do {
            // Save current data to local files first
            saveData()
            
            // Get file URLs to sync
            let filesToSync = [profileURL, recordsURL, notesURL]
            
            // Set up iCloud container
            guard let iCloudContainer = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                print("iCloud container not available")
                completion(false)
                return
            }
            
            // Create iCloud directory if needed
            let iCloudDirectory = iCloudContainer.appendingPathComponent("Documents")
            try FileManager.default.createDirectory(at: iCloudDirectory, withIntermediateDirectories: true)
            
            // Copy files to iCloud
            for fileURL in filesToSync {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let iCloudURL = iCloudDirectory.appendingPathComponent(fileURL.lastPathComponent)
                    try FileManager.default.removeItem(at: iCloudURL)
                    try FileManager.default.copyItem(at: fileURL, to: iCloudURL)
                }
            }
            
            print("iCloud sync completed successfully")
            completion(true)
        } catch {
            print("Error syncing to iCloud: \(error)")
            completion(false)
        }
    }
}
