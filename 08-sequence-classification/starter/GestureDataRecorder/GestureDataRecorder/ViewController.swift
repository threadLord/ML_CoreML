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

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {
  
  // MARK: - Constants
  
  // Utterances struct stores all the phrases the app speaks
  struct Utterances {
    static let phonePlacement = AVSpeechUtterance(string: "Please hold your phone in your right hand, with the home button at the bottom. The screen should be facing out, so you can see it, not facing toward your hand.")
    static let sessionStart = AVSpeechUtterance(string: "The session will begin in 5...4...3...2...1...")
    static let driveIt = AVSpeechUtterance(string: "Position the phone out in front of you, with your wrist turned so the phone's screen is facing the ground. When the countdown ends, please begin rocking the phone back and forth, as if you are pretending to drive a car while trying to look cool.")
    static let shakeIt = AVSpeechUtterance(string: "Position the phone vertically, with the screen facing to your left.... Hold it firmly, and when the countdown ends, shake the phone vigorously in short bursts.")
    static let chopIt = AVSpeechUtterance(string: "Position the phone vertically, with the screen facing to your left.... When the countdown ends, please begin making a steady chopping motion by bending your arm at your elbow. Be sure your wrist is bent so you are chopping with the phone, not stabbing.")
    
    static let begin = AVSpeechUtterance(string: "Begin in 3...2...1.")
    static let sessionComplete = AVSpeechUtterance(string: "This recording session is now complete.")
    static let error = AVSpeechUtterance(string: "An error has occurred.")
    
    static let twenty = AVSpeechUtterance(string: "20")
    static let fifteen = AVSpeechUtterance(string: "15")
    static let ten = AVSpeechUtterance(string: "10")
    static let nine = AVSpeechUtterance(string: "9")
    static let eight = AVSpeechUtterance(string: "8")
    static let seven = AVSpeechUtterance(string: "7")
    static let six = AVSpeechUtterance(string: "6")
    static let five = AVSpeechUtterance(string: "5")
    static let four = AVSpeechUtterance(string: "4")
    static let three = AVSpeechUtterance(string: "3")
    static let two = AVSpeechUtterance(string: "2")
    static let one = AVSpeechUtterance(string: "1")
    static let stop = AVSpeechUtterance(string: "And stop.")
    static let rest = AVSpeechUtterance(string: "Now rest for a few seconds.")
    static let ok = AVSpeechUtterance(string: "Ok, I hope you're ready.")
    static let again = AVSpeechUtterance(string: "When the countdown ends, please perform the same activity as before.")
  }

  // Config struct stores constants that control app behavior
  struct Config {
    static let countdownPace = 0.75
    static let countdownSkip5 = 5.0
    static let secondsBetweenSetupInstructions = 1.0
  }
  
  // ActivityType enum specifies what human activity we are currently recording
  enum ActivityType: Int {
    case none = 0, driveIt, shakeIt, chopIt
  }
  
  // MARK: - Activity properties
  
  var sessionId: String!
  var numActionsRecorded = 0
  var currActivity = ActivityType.none
  var isRecording = false
  
  // MARK: - Core Motion properties
  
  
  // MARK: - UI
  
  let speechSynth = AVSpeechSynthesizer()
  
  @IBOutlet var sessionStartButton: UIButton!
  @IBOutlet var activityChooser: UISegmentedControl!
  @IBOutlet var numRecordingsChooser: UISegmentedControl!
  @IBOutlet var userIdField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // register this object to respond to speech synthesizer events
    speechSynth.delegate = self
  }
  
  @IBAction func dismissKeypad() {
    view.endEditing(true)
  }
  
  @IBAction func userIdChanged() {
    let isGoodId = userIdField.text != nil && userIdField.text!.count > 0
    sessionStartButton.isEnabled = isGoodId
  }
  
  func enableUI(isEnabled: Bool) {
    sessionStartButton.isEnabled = isEnabled
    userIdField.isEnabled = isEnabled
    activityChooser.isEnabled = isEnabled
    numRecordingsChooser.isEnabled = isEnabled
    UIApplication.shared.isIdleTimerDisabled = !isEnabled
  }
  
  func numActionsToRecord() -> Int {
    return numRecordingsChooser.selectedSegmentIndex+1
  }
  
  func selectedActivity() -> ActivityType {
    switch activityChooser.selectedSegmentIndex {
    case 0: return .driveIt
    case 1: return .shakeIt
    case 2: return .chopIt
    default: return .none // should never happen
    }
  }
  
  func selectedActivityName() -> String {
    switch activityChooser.selectedSegmentIndex {
    case 0: return "drive-it"
    case 1: return "shake-it"
    case 2: return "chop-it"
    default: return "Nothing" // should never happen
    }
  }
  
  func isUserIdInUse() -> Bool {
    do {
      let files = try FileManager.default.contentsOfDirectory(
        at: FileManager.documentDirectoryURL, includingPropertiesForKeys: [.isRegularFileKey])

      for file in files {
        if file.lastPathComponent.starts(with: "u\(userIdField.text!)") {
          return true
        }
      }
    } catch {
      print("Error reading contents of document folder \(FileManager.documentDirectoryURL): \(error.localizedDescription)")
    }
    return false
  }
  
  func confirmUserIdAndStartRecording() {
    let confirmDialog = UIAlertController(title: "User ID Already Exists",
                                          message: "Data will be added to this user's files. If this is not you, please choose a different ID.",
                                          preferredStyle: UIAlertController.Style.alert)
    confirmDialog.addAction(
      UIAlertAction(title: "That's me!", style: .default,
                    handler: { (_: UIAlertAction!) in
                      self.startRecording()
      }))
    confirmDialog.addAction(
      UIAlertAction(title: "Change ID", style: .cancel,
                    handler: { (_: UIAlertAction!) in
                      self.userIdField.becomeFirstResponder()
      }))
    present(confirmDialog, animated: true, completion: nil)
  }
  
  @IBAction func startRecordingSession() {
    /* TODO: REMOVE THIS LINE
    guard motionManager.isDeviceMotionAvailable else {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else {
          return
        }
        let alert = UIAlertController(title: "Unable to Record",
                                      message: "Device motion data is unavailable",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
      }
      return
    }
    TODO: REMOVE THIS LINE */
    
    if isUserIdInUse() {
      confirmUserIdAndStartRecording()
    } else {
      startRecording()
    }
  }
  
  func startRecording() {
    enableUI(isEnabled: false)
    
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = .withInternetDateTime
    sessionId = dateFormatter.string(from: Date())
    
    numActionsRecorded = 0
    speechSynth.speak(Utterances.phonePlacement)
  }
  
  func randomRecordTimeCountdown() -> AVSpeechUtterance {
    // choose a random amount of time to perform activity to mix up the data
    switch Int.random(in: 1...2) {
    case 1: return Utterances.fifteen
    default: return Utterances.twenty
    }
  }
  
  func randomRestTimeCountDown() -> AVSpeechUtterance {
    // choose a random amount of time to rest just to keep life interesting
    switch Int.random(in: 1...3) {
    case 1: return Utterances.five
    case 2: return Utterances.six
    default: return Utterances.four
    }
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    switch utterance {
    case Utterances.phonePlacement:
      speechSynth.speak(Utterances.sessionStart, after: Config.secondsBetweenSetupInstructions)
      
    case Utterances.sessionStart:
      // TODO: enable Core Motion
      queueNextActivity()
      
    case Utterances.driveIt, Utterances.shakeIt, Utterances.chopIt:
      speechSynth.speak(Utterances.begin, after: Config.countdownPace)
      
    case Utterances.begin:
      isRecording = true
      speechSynth.speak(randomRecordTimeCountdown(), after: Config.countdownPace)
      
    case Utterances.twenty:
      speechSynth.speak(Utterances.fifteen, after: Config.countdownSkip5)
    case Utterances.fifteen:
      speechSynth.speak(Utterances.ten, after: Config.countdownSkip5)
    case Utterances.ten:
      speechSynth.speak(Utterances.nine, after: Config.countdownPace)
    case Utterances.nine:
      speechSynth.speak(Utterances.eight, after: Config.countdownPace)
    case Utterances.eight:
      speechSynth.speak(Utterances.seven, after: Config.countdownPace)
    case Utterances.seven:
      speechSynth.speak(Utterances.six, after: Config.countdownPace)
    case Utterances.six:
      speechSynth.speak(Utterances.five, after: Config.countdownPace)
    case Utterances.five:
      speechSynth.speak(Utterances.four, after: Config.countdownPace)
    case Utterances.four:
      speechSynth.speak(Utterances.three, after: Config.countdownPace)
    case Utterances.three:
      speechSynth.speak(Utterances.two, after: Config.countdownPace)
    case Utterances.two:
      speechSynth.speak(Utterances.one, after: Config.countdownPace)
    case Utterances.one:
      if isRecording {
        speechSynth.speak(Utterances.stop, after: Config.countdownPace)
      } else {
        speechSynth.speak(Utterances.ok, after: Config.countdownPace)
      }
      
    case Utterances.stop:
      isRecording = false
      
      if numActionsRecorded >= numActionsToRecord() {
        speechSynth.speak(Utterances.sessionComplete, after: Config.secondsBetweenSetupInstructions)
      } else {
        speechSynth.speak(Utterances.rest, after: Config.secondsBetweenSetupInstructions)
      }
      
    case Utterances.rest:
      speechSynth.speak(randomRestTimeCountDown(), after: Config.countdownPace)
      
    case Utterances.ok:
      queueNextActivity()
      
    case Utterances.again:
      speechSynth.speak(Utterances.begin, after: Config.countdownPace)
      
    case Utterances.sessionComplete:
      DispatchQueue.main.async { [weak self] in
        guard let self = self else {
          return
        }
        self.saveActivityData()

        self.enableUI(isEnabled: true)
      }
      
    default:
      // This should never happen, but can be useful for debugging if you
      // add a new utterance and forget to handle it above.
      print("WARNING: Unhandled utterance.")
    }
  }
  
  func utteranceForActivity(activity: ActivityType) -> AVSpeechUtterance {
    switch activity {
    case .driveIt: return Utterances.driveIt
    case .shakeIt: return Utterances.shakeIt
    case .chopIt: return Utterances.chopIt
    default: return Utterances.error
    }
  }
  
  func queueNextActivity() {
    if numActionsRecorded >= numActionsToRecord() {
      speechSynth.speak(Utterances.sessionComplete, after: Config.secondsBetweenSetupInstructions)
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      self.numActionsRecorded += 1
      self.currActivity = self.selectedActivity()
      if self.numActionsRecorded > 1 {
        self.speechSynth.speak(Utterances.again)
      } else {
        self.speechSynth.speak(self.utteranceForActivity(activity: self.currActivity))
      }
    }
  }
  
  func saveActivityData() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      let confirmDialog = UIAlertController(title: "Session Complete",
                                            message: "Save or discard data from this session?",
                                            preferredStyle: UIAlertController.Style.actionSheet)
      confirmDialog.addAction(
        UIAlertAction(title: "Save", style: .default,
                      handler: { (_: UIAlertAction!) in
                        let dataURL =
                          FileManager.documentDirectoryURL
                            .appendingPathComponent("u\(self.userIdField.text!)-\(self.selectedActivityName())-data")
                            .appendingPathExtension("csv")
                        do {
                          print("Appended to file \(dataURL.path)")
                        } catch {
                          print("Error writing file to \(dataURL): \(error.localizedDescription)")
                        }
        }))
      confirmDialog.addAction(UIAlertAction(title: "Discard", style: .cancel))
      self.present(confirmDialog, animated: true, completion: nil)
    }
  }
  
  // MARK: - Core Motion methods
  
}
