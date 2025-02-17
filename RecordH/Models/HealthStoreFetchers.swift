import Foundation
import HealthKit

extension HealthStore {
    // MARK: - Health Data Fetching Methods
    func fetchSteps(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching steps data...")
        group.enter()
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let stepsUnit = HKUnit.count()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching steps: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity()?.doubleValue(for: stepsUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .steps,
                        value: quantity,
                        unit: "count"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }

            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchBloodOxygen(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching blood oxygen data...")
        group.enter()
        if let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let percentUnit = HKUnit.percent()

            let query = HKStatisticsCollectionQuery(
                quantityType: oxygenType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching blood oxygen: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.averageQuantity()?.doubleValue(for: percentUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .bloodOxygen,
                        value: quantity,
                        unit: "percent"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }

            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchActiveEnergy(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching active energy data...")
        group.enter()
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let calorieUnit = HKUnit.kilocalorie()

            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching active energy: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity()?.doubleValue(for: calorieUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .activeEnergy,
                        value: quantity,
                        unit: "kilocalorie"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }

            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchRestingEnergy(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching resting energy data...")
        group.enter()
        if let energyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let calorieUnit = HKUnit.kilocalorie()

            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching resting energy: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity()?.doubleValue(for: calorieUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .restingEnergy,
                        value: quantity,
                        unit: "kilocalorie"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }

            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchDistance(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching distance data...")
        group.enter()
        if let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let meterUnit = HKUnit.meter()

            let query = HKStatisticsCollectionQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching distance: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity()?.doubleValue(for: meterUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .distance,
                        value: quantity,
                        unit: "meter"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }

            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchFlightsClimbed(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching flights climbed data...")
        group.enter()
        if let flightsType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let flightsUnit = HKUnit.count()

            let query = HKStatisticsCollectionQuery(
                quantityType: flightsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching flights climbed: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity()?.doubleValue(for: flightsUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .flightsClimbed,
                        value: quantity,
                        unit: "flights"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }
            
            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchHeartRate(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching heart rate data...")
        group.enter()
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] (query: HKStatisticsCollectionQuery, results: HKStatisticsCollection?, error: Error?) in
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let statisticsCollection = results else {
                    group.leave()
                    return
                }

                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.averageQuantity()?.doubleValue(for: beatsPerMinuteUnit) else { return }

                    let record = HealthRecord(
                        date: statistics.startDate,
                        type: .heartRate,
                        value: quantity,
                        unit: "beats per minute"
                    )
                    self?.addHealthRecord(record)
                }
                group.leave()
            }

            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    func fetchSleep(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching sleep data...")
        group.enter()
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)],
                resultsHandler: { [weak self] query, samples, error in
                    if let error = error {
                        print("Error fetching sleep: \(error.localizedDescription)")
                        group.leave()
                        return
                    }

                    guard let self = self else {
                        group.leave()
                        return
                    }

                    let sleepSamples = samples as? [HKCategorySample] ?? []

                    // Group samples by day (using 9 AM cutoff)
                    var dailySleepDurations: [Date: TimeInterval] = [:]

                    for sample in sleepSamples {
                        let isAsleep: Bool
                        if #available(iOS 16.0, *) {
                            isAsleep = sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                        } else {
                            isAsleep = sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                        }
                        if isAsleep {
                            let calendar = Calendar.current

                            // Create 9 AM reference date for the sleep day
                            var components = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
                            components.hour = 9
                            components.minute = 0
                            components.second = 0
                            guard let cutoffDate = calendar.date(from: components) else { continue }

                            // If the sample start time is before 9 AM, it belongs to the previous day
                            let dateKey = sample.startDate < cutoffDate ?
                                calendar.date(byAdding: .day, value: -1, to: cutoffDate)! :
                                cutoffDate

                            let duration = sample.endDate.timeIntervalSince(sample.startDate)
                            dailySleepDurations[dateKey, default: 0] += duration
                        }
                    }

                    // Create records for each day, sorted by date (newest first)
                    for (date, duration) in dailySleepDurations.sorted(by: { $0.key > $1.key }) {
                        let record = HealthRecord(
                            date: date,
                            type: .sleep,
                            value: duration / 3600.0,
                            unit: "hour"
                        )
                        self.addHealthRecord(record)
                    }

                    group.leave()
                }
            )
            self.healthStore.execute(query)
        } else {
            group.leave()
        }
    }
}
