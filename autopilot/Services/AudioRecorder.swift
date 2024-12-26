import Foundation
import AVFoundation
import Speech

class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var audioTranscription = ""
    private var audioBuffer = Data()
    private let audioEngine = AVAudioEngine()
    private let wisprAPIKey = Bundle.main.infoDictionary?["WISPR_API_KEY"] as? String ?? "NO_API_KEY"
    
    func startRecording() {
        print("Starting recording process...")
        audioBuffer.removeAll()
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("Microphone access already authorized")
            setupRecording()
        case .notDetermined:
            print("Requesting microphone access")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupRecording()
                    }
                }
            }
        default:
            print("Microphone access not available")
        }
    }
    
    private func setupRecording() {
        do {
            let inputNode = audioEngine.inputNode
            
            let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                              sampleRate: 16000,
                                              channels: 1,
                                              interleaved: true)!
            
            print("Recording format: \(recordingFormat)")
            
            let converter = AVAudioConverter(from: inputNode.inputFormat(forBus: 0),
                                          to: recordingFormat)!
            
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.inputFormat(forBus: 0)) { buffer, time in
                let frameCount = UInt32(buffer.frameLength)
                let outputBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat,
                                                  frameCapacity: frameCount)!
                
                var error: NSError?
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                converter.convert(to: outputBuffer,
                                error: &error,
                                withInputFrom: inputBlock)
                
                if let error = error {
                    print("Conversion error: \(error)")
                    return
                }
                
                let channels = UnsafeBufferPointer(start: outputBuffer.int16ChannelData?[0],
                                                 count: Int(outputBuffer.frameLength))
                self.audioBuffer.append(Data(bytes: channels.baseAddress!,
                                          count: Int(outputBuffer.frameLength) * 2))
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            print("Audio engine started successfully")
            
        } catch {
            print("Error in setupRecording: \(error)")
        }
    }
    
    func stopRecording() {
        print("Stopping recording...")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        
        let wavData = createWavFile(from: audioBuffer)
        sendToFlowVoice(audioData: wavData)
    }
    
    private func createWavFile(from buffer: Data) -> Data {
        var wavHeader = Data()
        
        wavHeader.append("RIFF".data(using: .utf8)!)
        let fileSize = UInt32(buffer.count + 36).littleEndian
        wavHeader.append(withUnsafeBytes(of: fileSize) { Data($0) })
        wavHeader.append("WAVE".data(using: .utf8)!)
        
        wavHeader.append("fmt ".data(using: .utf8)!)
        let subchunk1Size = UInt32(16).littleEndian
        wavHeader.append(withUnsafeBytes(of: subchunk1Size) { Data($0) })
        let audioFormat = UInt16(1).littleEndian
        wavHeader.append(withUnsafeBytes(of: audioFormat) { Data($0) })
        let numChannels = UInt16(1).littleEndian
        wavHeader.append(withUnsafeBytes(of: numChannels) { Data($0) })
        let sampleRate = UInt32(16000).littleEndian
        wavHeader.append(withUnsafeBytes(of: sampleRate) { Data($0) })
        let byteRate = UInt32(16000 * 2).littleEndian
        wavHeader.append(withUnsafeBytes(of: byteRate) { Data($0) })
        let blockAlign = UInt16(2).littleEndian
        wavHeader.append(withUnsafeBytes(of: blockAlign) { Data($0) })
        let bitsPerSample = UInt16(16).littleEndian
        wavHeader.append(withUnsafeBytes(of: bitsPerSample) { Data($0) })
        
        wavHeader.append("data".data(using: .utf8)!)
        let subchunk2Size = UInt32(buffer.count).littleEndian
        wavHeader.append(withUnsafeBytes(of: subchunk2Size) { Data($0) })
        
        var wavData = Data()
        wavData.append(wavHeader)
        wavData.append(buffer)
        
        return wavData
    }
    
    private func sendToFlowVoice(audioData: Data) {
        let base64Audio = audioData.base64EncodedString()
        
        print("Sending audio to FlowVoice...")
        
        let url = URL(string: "https://cloud.flowvoice.ai/api/v1/dash/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(wisprAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "audio": base64Audio,
            "properties": [
                "language_text": "en"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let transcribedText = json["text"] as? String {
                
                print("json: \(json)")
                
                DispatchQueue.main.async {
                    self?.audioTranscription = transcribedText
                }
            }
        }.resume()
    }
} 