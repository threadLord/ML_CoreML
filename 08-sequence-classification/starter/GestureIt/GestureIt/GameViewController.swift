/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import AVFoundation
import CoreMotion

class GameViewController: UIViewController, AVSpeechSynthesizerDelegate {
  // MARK: - Constants

  // Utterances struct stores all the phrases the app speaks
  struct Utterances {
    static let getReady = AVSpeechUtterance(string: "Ready?...Set?...")
    static let chopIt = AVSpeechUtterance(string: "Chop it!")
    static let driveIt = AVSpeechUtterance(string: "Drive it!")
    static let shakeIt = AVSpeechUtterance(string: "Shake it!")
    static let great = AVSpeechUtterance(string: "Great!")
    static let super_ = AVSpeechUtterance(string: "Super!")
    static let nice = AVSpeechUtterance(string: "Nice!")
    static let awesome = AVSpeechUtterance(string: "Awesome!")
    static let sweet = AVSpeechUtterance(string: "Sweet!")
    static let thatsIt = AVSpeechUtterance(string: "That's it!")
    static let timeout = AVSpeechUtterance(string: "Sorry, but time's run out!")
    static let error = AVSpeechUtterance(string: "An error has occurred.")
  }
  
  // Config struct stores constants that control app's ML
  struct Config {
    static let chopItValue = "chop_it"
    static let driveItValue = "drive_it"
    static let shakeItValue = "shake_it"
    static let restItValue = "rest_it"

    // Seconds available to respond with gesture. Increase this if you have trouble
    // responding in time, and decrease it for more challenge. However, you can't
    // decrease it too low because the absolute minimum time necessary is however
    // long it takes to fill one complete prediction window, plus a bit more to give the
    // app time to process the event before the timer ends. I find I can still play at 0.9
    static let gestureTimeout = 1.5
    static let doubleSize = MemoryLayout<Double>.stride
  }

  // MARK: - Core Motion properties

  let motionManager = CMMotionManager()
  let queue = OperationQueue()

  // MARK: - Core ML properties

  
  // MARK: - Gameplay properties
  
  var expectedGesture: String?
  var timer: Timer?
  var score = 0
  
  // MARK: - UI

  let speechSynth = AVSpeechSynthesizer()

  @IBOutlet var scoreLabel: UILabel!
  @IBOutlet var dismissButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    enableMotionUpdates()
    
    if motionManager.isDeviceMotionAvailable {
      speechSynth.delegate = self
      speechSynth.speak(Utterances.getReady, after: 1.0)
    }
  }
  
  @IBAction func dismiss() {
    dismiss(animated: true, completion: nil)
  }
  
  // Helper function to let player know they app won't run for some reason
  func displayFatalError(error: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      
      let alert = UIAlertController(title: "Unable to Play", message: error, preferredStyle: UIAlertController.Style.alert)
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
        self.dismiss()
      }))
      self.present(alert, animated: true, completion: nil)
    }
  }

  // MARK: - Gameplay methods
  
  // Returns a random gesture
  func randomGesture() -> String {
    switch Int.random(in: 1...3) {
    case 1: return Config.chopItValue
    case 2: return Config.driveItValue
    default: return Config.shakeItValue
    }
  }

  // sets the gesture expected of the player and starts the timeout timer
  func startTimerForGesture(gesture: String) {
    expectedGesture = gesture
    
    timer = Timer(timeInterval: Config.gestureTimeout, repeats: false) { [weak self] timer in
      guard let self = self else {
        return
      }
      self.gameOver()
    }
    RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
  }
  
  // Called when the app finishes speaking. Announces a random next gesture.
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    switch utterance {
      case Utterances.getReady, Utterances.great, Utterances.super_, Utterances.nice, Utterances.awesome, Utterances.sweet, Utterances.thatsIt:
        switch randomGesture() {
        case Config.chopItValue: speechSynth.speak(Utterances.chopIt, after: 0.2)
        case Config.driveItValue: speechSynth.speak(Utterances.driveIt, after: 0.2)
        case Config.shakeItValue: speechSynth.speak(Utterances.shakeIt, after: 0.2)
        default: speechSynth.speak(Utterances.error, after: 0.2)
        }

    case Utterances.chopIt:
      startTimerForGesture(gesture: Config.chopItValue)
      
    case Utterances.driveIt:
      startTimerForGesture(gesture: Config.driveItValue)

    case Utterances.shakeIt:
      startTimerForGesture(gesture: Config.shakeItValue)

    default:
      break
    }
  }
  
  // Adds 1 to the score and speaks out a congratulatory message
  func updateScore() {
    timer?.invalidate()
    
    score += 1
    if score > 999 {
      disableMotionUpdates()
      speechSynth.speak(AVSpeechUtterance(string: "Ok, nice job. But seriously, you've played this for way too long. It was just a demo!"), after: 0.0)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else {
          return
        }
        self.dismissButton.isHidden = false
      }
    } else {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else {
          return
        }
        self.scoreLabel.text = "Score: \(String(format: "%03d", self.score))"
        
        switch Int.random(in: 1...6) {
        case 1: self.speechSynth.speak(Utterances.great)
        case 2: self.speechSynth.speak(Utterances.super_)
        case 3: self.speechSynth.speak(Utterances.nice)
        case 4: self.speechSynth.speak(Utterances.awesome)
        case 5: self.speechSynth.speak(Utterances.sweet)
        default: self.speechSynth.speak(Utterances.thatsIt)
        }
      }
    }
  }
  
  // Disables motion updates and notifies the player the game is over
  func gameOver(incorrectPrediction: String? = nil) {
    timer?.invalidate()
    
    disableMotionUpdates()

    if let incorrectPredition = incorrectPrediction {
      var wePredicted = ""
      switch incorrectPredition {
      case Config.chopItValue: wePredicted = "chopped it"
      case Config.driveItValue: wePredicted = "drove it"
      case Config.shakeItValue: wePredicted = "shook it"
      default: wePredicted = "did something I didn't recognize"
      }

      var weWanted = ""
      switch expectedGesture {
      case Config.chopItValue: weWanted = "chopped it"
      case Config.driveItValue: weWanted = "driven it"
      case Config.shakeItValue: weWanted = "shaken it"
      default: weWanted = "done something I did recognize"
      }

      expectedGesture = nil
      
      speechSynth.speak(AVSpeechUtterance(string: "Oops. Sorry, it seems you \(wePredicted) when you should have \(weWanted)."), after: 0.0)
    } else if expectedGesture != nil {
      speechSynth.speak(Utterances.timeout)
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      self.dismissButton.isHidden = false
    }
  }
  
  // MARK: - Core Motion methods
  
  // Enables Core Motion updates if available, and calls processMotionData to handle motion updates
  func enableMotionUpdates() {
    guard motionManager.isDeviceMotionAvailable else {
      displayFatalError(error: "Device motion data is unavailable")
      return
    }
    
    motionManager.startDeviceMotionUpdates(
      using: .xArbitraryZVertical,
      to: queue, withHandler: { [weak self] motionData, error in
        guard let self = self, let motionData = motionData else {
          if let error = error {
            // Just display error for local testing.
            // A more robust solution would include better error logging and
            // stop the game if too many errors occur.
            print("Device motion update error: \(error.localizedDescription)")
          }
          return
        }
        self.processMotionData(motionData)
    })
  }
  
  func disableMotionUpdates() {
    motionManager.stopDeviceMotionUpdates()
  }

  // MARK: - Core ML methods
  
  func processMotionData(_ motionData: CMDeviceMotion) {
  }
}
