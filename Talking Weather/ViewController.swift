//
//  ViewController.swift
//  Talking Weather
//
//  Created by SPASOV DIMITROV Vladimir on 21/8/18.
//  Copyright © 2018 SPASOV DIMITROV Vladimir. All rights reserved.
//

import UIKit
import CoreLocation
import Speech

class ViewController: UIViewController {
    
    @IBOutlet weak var stateLabel: UILabel!
    
    
    var locationManager: CLLocationManager!
    var weatherData: OpenWeatherResponse?
    
    var timer: Timer?
    
    var isIntro = true
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var speechResult = SFSpeechRecognitionResult()
    
    let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestLocationAutorization()
        requestSpeachAutorization()
        determineMyCurrentLocation()
        synthesizer.delegate = self
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    
    func requestSpeachAutorization() {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined || status == .denied || status == .restricted {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Access to mic and voice recognition is needed", message: "Please enable it in settings", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func requestLocationAutorization() {
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied || status == .restricted {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Accxess to GPS is needed", message: "Please enable it in settings", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func startRecording() throws {
        print("Listening ...")
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.timerEnded), userInfo: nil, repeats: false)
        if !audioEngine.isRunning {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                //TODO: check if AVAudioSessionCategoryPlayAndRecord works
                try audioSession.setCategory(AVAudioSessionCategoryRecord)
                try audioSession.setMode(AVAudioSessionModeMeasurement)
                try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to set record audioSession mode")
            }
       
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
//            guard let inputNode = audioEngine.inputNode else { fatalError("There was a problem with the audio engine") }
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create the recognition request") }
            let inputNode = audioEngine.inputNode
            
            // Configure request so that results are returned before audio recording is finished
            recognitionRequest.shouldReportPartialResults = true
            
            // A recognition task is used for speech recognition sessions
            // A reference for the task is saved so it can be cancelled
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    print("result: \(result.isFinal)")
                    isFinal = result.isFinal
                    
                    self.speechResult = result
                    
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }
            
            print("Begin recording")
            audioEngine.prepare()
            try audioEngine.start()
        }
        
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            if(self.audioEngine.isRunning) {
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.audioEngine.inputNode.reset()
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
                if let recognitionTask = self.recognitionTask {
                    recognitionTask.cancel()
                    self.recognitionTask = nil
                }
                
            }
        }

    }
    
    @objc func timerEnded() {
        print("Timer ended")
        timer?.invalidate()
        if audioEngine.isRunning {
            stopRecording()
        }
        checkForActionPhrases()
    }
    
    func checkForActionPhrases() {
        print("Checking ...")
        var isWeatherCommand = false
        
        var lastString: String = ""
        for segment in speechResult.bestTranscription.segments {
            let best = speechResult.bestTranscription.formattedString
            let indexTo = best.index(best.startIndex, offsetBy: segment.substringRange.location)

            lastString = best.substring(from: indexTo)
            
            isWeatherCommand = (lastString.lowercased().contains("weather") || lastString.lowercased().contains("forecast"))
        }
        
        if (!lastString.isEmpty) {
            if isWeatherCommand {
                speekForcast()
            } else{
                speekDidntUnderstood()
            }
        } else
            {
            do {
                try self.startRecording()
                self.stateLabel.text = "Waiting for orders"
            } catch {
                print("There was a problem starting the speech recorder")
            }
        }
    }
    func speekIntro(){
        self.stateLabel.text = "Prepairing synth"
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeDefault)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set playback audioSession mode")
        }
        
        let utterance = AVSpeechUtterance(string: "I only understand two commands, Weather and Forecast.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
    }
    
    func speekDidntUnderstood(){
        self.stateLabel.text = "Prepairing synth"
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeDefault)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set playback audioSession mode")
        }
        
        let utterance = AVSpeechUtterance(string: "Sorry, I deidn't understood your command")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        
        synthesizer.speak(utterance)
    }
    
    func speekForcast() {
        self.stateLabel.text = "Prepairing synth"
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeDefault)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set playback audioSession mode")
        }
        
        if let place = self.weatherData?.name{
            let temperature = String(format: "%.01f", (self.weatherData?.main.temp)!)
            print("Temperature in \(String(describing: place)) is \(temperature) degrees")
            
            let utterance = AVSpeechUtterance(string: "Temperature in \(String(describing: place)) is \(temperature) degrees")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            
            synthesizer.speak(utterance)
        }
        else {
            print("There was a problem treating the weather data.")
        }
    }
    
}

//MARK: CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        manager.stopUpdatingLocation()
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
        
        OpenWeatherMapClient.shared.getWeather(latitude: latitude, longitude: longitude) { result in
            self.weatherData = result.value
            if let place = self.weatherData?.name{
                let temperature = String(format: "%.01f", (self.weatherData?.main.temp)!)
                print("Temperature in \(String(describing: place)) is \(temperature) degrees")
            }
        }
        

    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
}

extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isIntro {
            isIntro = false
            return
        }
        do {
            speechResult = SFSpeechRecognitionResult()
            try self.startRecording()
            self.stateLabel.text = "Waiting for orders"
        } catch {
            print("There was a problem starting the speech recorder")
        }
    }
}

