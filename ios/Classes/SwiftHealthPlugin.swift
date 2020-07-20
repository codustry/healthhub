import Flutter
import UIKit
import HealthKit

public class SwiftHealthPlugin: NSObject, FlutterPlugin {
    
    let healthStore = HKHealthStore()
    var healthDataTypes = [HKSampleType]()
    var heartRateEventTypes = Set<HKSampleType>()
    var allDataTypes = Set<HKSampleType>()
    var dataTypesDict: [String: HKSampleType] = [:]
    var unitDict: [String: HKUnit] = [:]

    /***********************************************************
                        Health Data Type Keys
    ***********************************************************/
    // Body Measurements
    let WEIGHT = "WEIGHT"
    let HEIGHT = "HEIGHT"
    let BODY_MASS_INDEX = "BODY_MASS_INDEX"
    let BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
    let WAIST_CIRCUMFERENCE = "WAIST_CIRCUMFERENCE"
    // Activity
    let STEPS = "STEPS"
    let BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
    let ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
    let BODY_TEMPERATURE = "BODY_TEMPERATURE"
    // Blood
    let BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
    let BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
    let BLOOD_OXYGEN = "BLOOD_OXYGEN"
    let BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
    let BLOOD_ALCOHOL = "BLOOD_ALCOHOL"
    // Respiratory
    let RESPIRATORY_RATE = "RESPIRATORY_RATE"
    let VO2MAX = "VO2MAX"
    // Heart Rates
    let HEART_RATE = "HEART_RATE"
    let RESTING_HEART_RATE = "RESTING_HEART_RATE"
    let WALKING_HEART_RATE = "WALKING_HEART_RATE"
    let HIGH_HEART_RATE_EVENT = "HIGH_HEART_RATE_EVENT"
    let LOW_HEART_RATE_EVENT = "LOW_HEART_RATE_EVENT"
    let IRREGULAR_HEART_RATE_EVENT = "IRREGULAR_HEART_RATE_EVENT"
    let HRV_SDNN_HEART_RATE_EVENT = "HRV_SDNN_HEART_RATE_EVENT"
    // Lab and Test Results
    let ELECTRODERMAL_ACTIVITY = "ELECTRODERMAL_ACTIVITY"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_health", binaryMessenger: registrar.messenger())
        let instance = SwiftHealthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Set up all data types
        initializeTypes()
        
        /// Handle checkIfHealthDataAvailable
        if (call.method.elementsEqual("checkIfHealthDataAvailable")){
            checkIfHealthDataAvailable(call: call, result: result)
        }
        /// Handle requestAuthorization
        else if (call.method.elementsEqual("requestAuthorization")){
            requestAuthorization(call: call, result: result)
        }

        /// Handle getData
        else if (call.method.elementsEqual("getData")){
            getData(call: call, result: result)
        }
    }

    func checkIfHealthDataAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(HKHealthStore.isHealthDataAvailable())
    }

    func requestAuthorization(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKeys = (arguments?["dataTypeKeys"] as? Array) ?? []
        var dataTypesToRequest = Set<HKSampleType>()
        
        for key in dataTypeKeys {
            let keyString = "\(key)"
            dataTypesToRequest.insert(dataTypeLookUp(key: keyString))
        }

        if #available(iOS 11.0, *) {
            healthStore.requestAuthorization(toShare: nil, read: allDataTypes) { (success, error) in
                result(success)
            }
        } 
        else {
            result(false)// Handle the error here.
        }
    }

    func getData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKey = (arguments?["dataTypeKey"] as? String) ?? "DEFAULT"
        let startDate = (arguments?["startDate"] as? NSNumber) ?? 0
        let endDate = (arguments?["endDate"] as? NSNumber) ?? 0

        // Convert dates from milliseconds to Date()
        let dateFrom = Date(timeIntervalSince1970: startDate.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endDate.doubleValue / 1000)

        let dataType = dataTypeLookUp(key: dataTypeKey)
        let predicate = HKQuery.predicateForSamples(withStart: dateFrom, end: dateTo, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: dataType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
            x, samplesOrNil, error in

            guard let samples = samplesOrNil as? [HKQuantitySample] else {
                result(FlutterError(code: "FlutterHealth", message: "Results are null", details: "\(error)"))
                return
            }

            if (samples != nil){
                result(samples.map { sample -> NSDictionary in
                    let unit = self.unitLookUp(key: dataTypeKey)
                    
                    return [
                        "value": sample.quantity.doubleValue(for: unit),
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                    ]
                })
            }
            return
        }
        HKHealthStore().execute(query)
    }

    func unitLookUp(key: String) -> HKUnit {
        guard let unit = unitDict[key] else {
            return HKUnit.count()
        }
        return unit
    }

    func dataTypeLookUp(key: String) -> HKSampleType {
        guard let dataType_ = dataTypesDict[key] else {
            return HKSampleType.quantityType(forIdentifier: .bodyMass)!
        }
        return dataType_
    }

    func initializeTypes() {
        
        // Body Measurements
        unitDict[HEIGHT] = HKUnit.meter()
        unitDict[WEIGHT] = HKUnit.gramUnit(with: .kilo)
        unitDict[BODY_MASS_INDEX] = HKUnit.init(from: "")
        unitDict[BODY_FAT_PERCENTAGE] = HKUnit.percent()
        unitDict[WAIST_CIRCUMFERENCE] = HKUnit.meter()

        // Activity
        unitDict[STEPS] = HKUnit.count()
        unitDict[BASAL_ENERGY_BURNED] = HKUnit.kilocalorie()
        unitDict[ACTIVE_ENERGY_BURNED] = HKUnit.kilocalorie()
        unitDict[BODY_TEMPERATURE] = HKUnit.degreeCelsius()

        // Blood
        unitDict[BLOOD_PRESSURE_SYSTOLIC] = HKUnit.millimeterOfMercury()
        unitDict[BLOOD_PRESSURE_DIASTOLIC] = HKUnit.millimeterOfMercury()
        unitDict[BLOOD_OXYGEN] = HKUnit.percent()
        unitDict[BLOOD_GLUCOSE] = HKUnit.init(from: "mg/dl")
        // unitDict[BLOOD_PRESSURE] = HKUnit.percent() // .bloodPressure (iOS 8.0+)
        unitDict[BLOOD_ALCOHOL] = HKUnit.percent() // .bloodAlcoholContent (iOS 8.0+)

        // Respiratory
        unitDict[RESPIRATORY_RATE] = HKUnit.init(from: "count/min")
        unitDict[VO2MAX] = HKUnit.init(from: "ml/kg*min")

        // Heart Rates
        unitDict[HEART_RATE] = HKUnit.init(from: "count/min")
        unitDict[RESTING_HEART_RATE] = HKUnit.init(from: "count/min")
        unitDict[WALKING_HEART_RATE] = HKUnit.init(from: "count/min")
        unitDict[HRV_SDNN_HEART_RATE_EVENT] = HKUnit.secondUnit(from: .milli)
        // + 3 more (HIGH_HEART_RATE_EVENT, LOW_HEART_RATE_EVENT, IRREGULAR_HEART_RATE_EVENT)
        
        // Hearing
        // --- ENV_AUDIO_EXPOSURE, // .environmentalAudioExposure (iOS 13.0+)
        // --- HEADPHONE_AUDIO_EXPOSURE, // .headphoneAudioExposure (iOS 13.0+)

        // Lab and Test Results
        unitDict[ELECTRODERMAL_ACTIVITY] = HKUnit.siemen()

        // Set up iOS 11 specific types (ordinary health data types)
        if #available(iOS 11.0, *) { 
            // Body Measurements
            dataTypesDict[HEIGHT] = HKSampleType.quantityType(forIdentifier: .height)!
            dataTypesDict[WEIGHT] = HKSampleType.quantityType(forIdentifier: .bodyMass)!
            dataTypesDict[BODY_MASS_INDEX] = HKSampleType.quantityType(forIdentifier: .bodyMassIndex)!
            dataTypesDict[BODY_FAT_PERCENTAGE] = HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!
            dataTypesDict[WAIST_CIRCUMFERENCE] = HKSampleType.quantityType(forIdentifier: .waistCircumference)!
            // Activity
            dataTypesDict[STEPS] = HKSampleType.quantityType(forIdentifier: .stepCount)!
            dataTypesDict[BASAL_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!
            dataTypesDict[ACTIVE_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
            dataTypesDict[BODY_TEMPERATURE] = HKSampleType.quantityType(forIdentifier: .bodyTemperature)!
            // Blood
            dataTypesDict[BLOOD_PRESSURE_SYSTOLIC] = HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!
            dataTypesDict[BLOOD_PRESSURE_DIASTOLIC] = HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!
            dataTypesDict[BLOOD_OXYGEN] = HKSampleType.quantityType(forIdentifier: .oxygenSaturation)!
            dataTypesDict[BLOOD_GLUCOSE] = HKSampleType.quantityType(forIdentifier: .bloodGlucose)!
            // dataTypesDict[BLOOD_PRESSURE] = HKSampleType.quantityType(forIdentifier: .bloodPressure)!
            dataTypesDict[BLOOD_ALCOHOL] = HKSampleType.quantityType(forIdentifier: .bloodAlcoholContent)!
            // Heart Rates + 3 more (HIGH_HEART_RATE_EVENT, LOW_HEART_RATE_EVENT, IRREGULAR_HEART_RATE_EVENT)
            dataTypesDict[HEART_RATE] = HKSampleType.quantityType(forIdentifier: .heartRate)!
            dataTypesDict[RESTING_HEART_RATE] = HKSampleType.quantityType(forIdentifier: .restingHeartRate)!
            dataTypesDict[WALKING_HEART_RATE] = HKSampleType.quantityType(forIdentifier: .walkingHeartRateAverage)!
            dataTypesDict[HRV_SDNN_HEART_RATE_EVENT] = HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            // Lab and Test Results
            dataTypesDict[ELECTRODERMAL_ACTIVITY] = HKSampleType.quantityType(forIdentifier: .electrodermalActivity)!
            

            healthDataTypes = Array(dataTypesDict.values)
        }
        // Set up heart rate data types specific to the apple watch, requires iOS 12
        if #available(iOS 12.2, *){
            dataTypesDict[HIGH_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!
            dataTypesDict[LOW_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!
            dataTypesDict[IRREGULAR_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!

            heartRateEventTypes =  Set([
                HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!,
                HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!,
                HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!,
                ])
        }

        // Set up iOS 13.0 specific types
        // if #available(iOS 13.0, *){

        //     // Hearing
        //     dataTypesDict[ENV_AUDIO_EXPOSURE] = HKSampleType.quantityType(forIdentifier: .environmentalAudioExposure)!
        //     dataTypesDict[HEADPHONE_AUDIO_EXPOSURE] = HKSampleType.quantityType(forIdentifier: .headphoneAudioExposure)!

        //     hearingEventTypes =  Set([
        //         HKSampleType.categoryType(forIdentifier: .environmentalAudioExposure)!,
        //         HKSampleType.categoryType(forIdentifier: .headphoneAudioExposure)!,
        //         ])
        // }

        // Concatenate heart events and health data types (both may be empty)
        allDataTypes = Set(heartRateEventTypes + healthDataTypes)
        // allDataTypes = Set(heartRateEventTypes + healthDataTypes + hearingEventTypes)
    }
    
}




