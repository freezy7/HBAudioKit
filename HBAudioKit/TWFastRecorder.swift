//
//  TWFastRecorder.swift
//  HBAudioKit
//
//  Created by HolidayBomb on 2024/6/27.
//

import Foundation
import Speech

func getDocumentRootPath() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    return paths[0]
}

func getPathWithDirectory(rootDirectory: String, path: String) -> String? {
    let directoryPath = rootDirectory.appending("/" + path)
    if !FileManager.default.fileExists(atPath: directoryPath) {
        do {
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes:[FileAttributeKey.protectionKey: FileProtectionType.none])
        } catch {
            print("create path error \(error.localizedDescription), \(rootDirectory + path)")
            return nil
        }
    }
    return directoryPath
}

typealias TWFastRecorderDurationBlock = (Double) -> Void
typealias TWFastRecorderSpeechBlock = (String) -> Void

class TWFastRecorder: NSObject {
    var audioEngine: AVAudioEngine!
    var audioFile: AVAudioFile!
    var recording: Bool = false
    
    var speechRecognizer: SFSpeechRecognizer?
    var recognitionRequest:SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
    @objc var savePath: String
    @objc var audioFilePath: String
    var progressBlock: TWFastRecorderDurationBlock?
    var speechBlock: TWFastRecorderSpeechBlock?
    
    var totalFrameLength: AVAudioFrameCount = 0
    var duration: Double = 0
    
    @objc var audioFormat: AVAudioFormat?
    var saveFormat: AVAudioFormat!
    
    override init() {
        self.savePath = getPathWithDirectory(rootDirectory: getDocumentRootPath(), path: "audioRecord/temp") ?? ""
        self.audioFilePath = savePath + "/audio.pcm"
        super.init()
    }
    
    @objc func startRecording(progressBlock: @escaping TWFastRecorderDurationBlock, speechBlock: @escaping TWFastRecorderSpeechBlock) {
        if !recording {
            self.progressBlock = progressBlock
            self.speechBlock = speechBlock
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Audio session properties weren't set because of an error.")
            }
            
            audioEngine = AVAudioEngine()
            
            let inputNode = audioEngine.inputNode
            let bus = 0
            let recordingFormat = inputNode.outputFormat(forBus: bus)
            audioFormat = recordingFormat
            
            saveFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
            let converter = AVAudioConverter(from: recordingFormat, to: saveFormat)!
            
            do {
                let audioFileURL = URL(fileURLWithPath: audioFilePath)
                audioFile = try AVAudioFile(forWriting: audioFileURL, settings: saveFormat.settings)
            } catch {
                print("Error setting up audio file: \(error.localizedDescription)")
            }
            
            // 文字识别
            speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
            if let speechRecognizer {
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                if let recognitionRequest = recognitionRequest {
                    recognitionRequest.shouldReportPartialResults = true

                    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [unowned self] result, error in
                        if let result = result {
                            if let block = self.speechBlock {
                                block(result.bestTranscription.formattedString)
                            }
                        }
                    }
                }
            }
            
            self.totalFrameLength = 0
            self.duration = 0
            inputNode.installTap(onBus: bus, bufferSize: 1024, format: recordingFormat) { [unowned self] buffer, when in
                self.totalFrameLength += buffer.frameLength
                let duration = Double(self.totalFrameLength)/recordingFormat.sampleRate
                self.duration = duration
                
                if let block = self.progressBlock {
                    block(duration)
                }
                
                self.recognitionRequest?.append(buffer)
                
                let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                
                let convertedBuffer = AVAudioPCMBuffer(pcmFormat: saveFormat, frameCapacity: AVAudioFrameCount(saveFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!
                
                var error: NSError? = nil
                let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
                guard status != .error else {
                    print(status)
                    return
                }
                
                guard error == nil else {
                    print(error?.localizedDescription ?? "--")
                    return
                }
                
                do {
                    try self.audioFile.write(from: convertedBuffer)
                } catch {
                    print("Error writing buffer to file: \(error.localizedDescription)")
                }
            }
            
            do {
                try audioEngine.start()
                recording = true
                print("Recording started")
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func stopRecording() {
        if recording {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            
            
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            recognitionTask = nil
            
            recording = false
            print("Recording stopped")
        }
    }
}
