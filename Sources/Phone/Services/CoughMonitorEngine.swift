import Foundation
import AVFoundation
import SoundAnalysis
import CoreML
import Accelerate

// MARK: - Engine

final class CoughMonitorEngine: CoughDetectionServiceProtocol {

    // -------------------------------------------------------------------------
    // MARK: Thresholds (tune here)
    // -------------------------------------------------------------------------
    private let energyThreshold: Float   = 0.02
    private let coughThreshold: Double   = 0.3
    private let speechThreshold: Double  = 0.5
    private let groupingGap: TimeInterval = 1.0
    private let noiseFloorAlpha: Float   = 0.05
    private let noiseFloorMargin: Float  = 2.0
    private let warmupWindows: Int       = 120
    private let snSilenceGate: Float     = 0.005

    // -------------------------------------------------------------------------
    // MARK: CoughDetectionServiceProtocol
    // -------------------------------------------------------------------------
    weak var delegate: CoughDetectionServiceDelegate?

    // -------------------------------------------------------------------------
    // MARK: Private — infrastructure
    // -------------------------------------------------------------------------
    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var monoFormat: AVAudioFormat?
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private let gateObserver = SNGateObserver()
    private var mlModel: MLModel?

    private let queue = DispatchQueue(label: "com.coughy.analysis", qos: .userInitiated)

    // -------------------------------------------------------------------------
    // MARK: Private — audio state (touched only on `queue`)
    // -------------------------------------------------------------------------
    private var sampleBuffer: [Float] = []
    private var framePosition: AVAudioFramePosition = 0

    private var windowsProcessed = 0
    private var bgRMSHistory = [Float]()
    private var noiseFloor: Float = 0.02
    private var gate: Float = 0.02

    private typealias PendingWindow = (timestamp: Date, rms: Float, dry: Double, wet: Double, samples: [Float])
    private var pendingWindows = [PendingWindow]()
    private var lastWindowTimestamp: Date?

    // -------------------------------------------------------------------------
    // MARK: Start / Stop
    // -------------------------------------------------------------------------

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default, options: [])
        try session.setActive(true)

        mlModel = try Self.loadMLModel()
        try buildEngineGraph()
        try engine.start()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption(_:)),
                       name: AVAudioSession.interruptionNotification, object: session)
        nc.addObserver(self, selector: #selector(handleConfigChange(_:)),
                       name: .AVAudioEngineConfigurationChange, object: engine)
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        queue.sync { self.flushGroup() }
    }

    // -------------------------------------------------------------------------
    // MARK: Engine Graph
    // -------------------------------------------------------------------------

    private func buildEngineGraph() throws {
        let inputNode = engine.inputNode
        let hwFormat  = inputNode.outputFormat(forBus: 0)
        let targetSR: Double = Double(LogMelProcessor.sampleRate)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: targetSR, channels: 1)!
        monoFormat = fmt

        print("CoughMonitorEngine: hw format = \(hwFormat)")
        print("CoughMonitorEngine: target format = \(fmt)")

        converter = AVAudioConverter(from: hwFormat, to: fmt)

        let analyzer = SNAudioStreamAnalyzer(format: fmt)
        let req = try SNClassifySoundRequest(classifierIdentifier: .version1)
        try analyzer.add(req, withObserver: gateObserver)
        streamAnalyzer = analyzer

        print("CoughMonitorEngine: SN known classifications: \(req.knownClassifications)")

        inputNode.installTap(onBus: 0, bufferSize: 8192, format: hwFormat) { [weak self] buf, _ in
            self?.queue.async { self?.ingest(hwBuf: buf) }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Audio Ingestion & Window Processing
    // -------------------------------------------------------------------------

    private func ingest(hwBuf: AVAudioPCMBuffer) {
        guard let cvt = converter, let monoFmt = monoFormat else { return }

        let hwEnergy = rawRMS(hwBuf)

        let outFrames = AVAudioFrameCount(
            ceil(Double(hwBuf.frameLength) * monoFmt.sampleRate / cvt.inputFormat.sampleRate) + 1
        )
        guard let monoBuf = AVAudioPCMBuffer(pcmFormat: monoFmt, frameCapacity: outFrames) else { return }

        var inputUsed = false
        var convErr: NSError?
        let status = cvt.convert(to: monoBuf, error: &convErr) { _, outStatus in
            if inputUsed { outStatus.pointee = .noDataNow; return nil }
            outStatus.pointee = .haveData
            inputUsed = true
            return hwBuf
        }
        guard status != .error, let ch0 = monoBuf.floatChannelData?[0] else { return }

        let count = Int(monoBuf.frameLength)

        if hwEnergy > snSilenceGate {
            streamAnalyzer?.analyze(monoBuf, atAudioFramePosition: framePosition)
        }

        sampleBuffer.append(contentsOf: UnsafeBufferPointer(start: ch0, count: count))
        framePosition += AVAudioFramePosition(count)

        let winSize = LogMelProcessor.windowSamples
        while sampleBuffer.count >= winSize {
            let window = Array(sampleBuffer.prefix(winSize))
            sampleBuffer.removeFirst(winSize)
            processWindow(window)
        }
    }

    private func processWindow(_ samples: [Float]) {
        windowsProcessed += 1
        let rms = vRMS(samples)

        guard rms >= gate else {
            addToBackground(rms: rms)
            return
        }

        let coughScore  = gateObserver.latestCough
        let speechScore = gateObserver.latestSpeech

        print("▶ rms=\(pf(rms)) gate=\(pf(gate)) cough=\(pd(coughScore)) speech=\(pd(speechScore)) snReady=\(gateObserver.hasResult)")

        if gateObserver.hasResult {
            guard coughScore >= coughThreshold, speechScore < speechThreshold else {
                addToBackground(rms: rms)
                return
            }
        }

        guard let model  = mlModel,
              let marray = LogMelProcessor.process(samples: samples),
              let input  = try? MLDictionaryFeatureProvider(dictionary: ["logmel_input": marray]),
              let output = try? model.prediction(from: input),
              let rawDict = output.featureValue(for: "classLabel_probs")?.dictionaryValue else {
            addToBackground(rms: rms)
            return
        }
        let dry = (rawDict["dry"] as? NSNumber)?.doubleValue ?? 0
        let wet = (rawDict["wet"] as? NSNumber)?.doubleValue ?? 0
        print("▶ dry=\(pd(dry)) wet=\(pd(wet))")

        let now = Date()
        if let last = lastWindowTimestamp, now.timeIntervalSince(last) > groupingGap {
            flushGroup()
        }
        pendingWindows.append((now, rms, dry, wet, samples))
        lastWindowTimestamp = now
    }

    private func flushGroup() {
        guard !pendingWindows.isEmpty else { return }
        let peak = pendingWindows.max(by: { $0.rms < $1.rms })!
        let type: CoughEvent.CoughType = peak.dry >= peak.wet ? .dry : .wet
        let id = UUID()

        // Gabungkan sampel seluruh burst (urut sesuai perekaman) → tulis 1 klip.
        let clipSamples = pendingWindows.flatMap { $0.samples }
        let filename = writeClip(samples: clipSamples, id: id)

        let event = CoughEvent(
            id: id,
            timestamp: peak.timestamp,
            type: type,
            dryScore: peak.dry,
            wetScore: peak.wet,
            confidence: max(peak.dry, peak.wet),
            peakRMS: peak.rms,
            windowCount: pendingWindows.count,
            audioClipFilename: filename
        )
        pendingWindows.removeAll()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.coughDetectionService(self, didDetect: event)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Adaptive Threshold
    // -------------------------------------------------------------------------

    private func addToBackground(rms: Float) {
        bgRMSHistory.append(rms)
        if bgRMSHistory.count > 300 { bgRMSHistory.removeFirst() }

        guard windowsProcessed >= warmupWindows, bgRMSHistory.count >= 10 else {
            gate = energyThreshold
            return
        }
        let sorted = bgRMSHistory.sorted()
        let p10idx = max(0, Int(Float(sorted.count) * 0.1) - 1)
        let p10 = sorted[p10idx]
        noiseFloor = noiseFloorAlpha * p10 + (1 - noiseFloorAlpha) * noiseFloor
        gate = min(max(noiseFloor * noiseFloorMargin, 0.005), 0.15)
    }

    // -------------------------------------------------------------------------
    // MARK: Interruption Handling
    // -------------------------------------------------------------------------

    @objc private func handleInterruption(_ note: Notification) {
        guard let typeVal = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }

        switch type {
        case .began:
            queue.async { self.flushGroup() }
            engine.pause()
        case .ended:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.restartAfterInterruption()
            }
        @unknown default: break
        }
    }

    @objc private func handleConfigChange(_ note: Notification) {
        restartAfterInterruption()
    }

    private func restartAfterInterruption() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        queue.async { self.sampleBuffer.removeAll() }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try buildEngineGraph()
            try engine.start()
            print("CoughMonitorEngine: restarted after interruption")
        } catch {
            print("CoughMonitorEngine: restart failed (\(error)), retrying in 2 s")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.restartAfterInterruption()
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------------------

    private func vRMS(_ s: [Float]) -> Float {
        var sumSq: Float = 0
        vDSP_svesq(s, 1, &sumSq, vDSP_Length(s.count))
        return sqrt(sumSq / Float(s.count))
    }

    private func rawRMS(_ buf: AVAudioPCMBuffer) -> Float {
        guard buf.frameLength > 0,
              let ch0 = buf.floatChannelData?[0] else { return 0 }
        var ms: Float = 0
        vDSP_measqv(ch0, 1, &ms, vDSP_Length(buf.frameLength))
        return sqrt(ms)
    }

    private static func loadMLModel() throws -> MLModel {
        let cfg = MLModelConfiguration()
        if let url = Bundle.main.url(forResource: "CoughCNN", withExtension: "mlmodelc") {
            return try MLModel(contentsOf: url, configuration: cfg)
        }
        if let pkgURL = Bundle.main.url(forResource: "CoughCNN", withExtension: "mlpackage") {
            let compiled = try MLModel.compileModel(at: pkgURL)
            return try MLModel(contentsOf: compiled, configuration: cfg)
        }
        throw NSError(
            domain: "CoughMonitorEngine", code: 1,
            userInfo: [NSLocalizedDescriptionKey:
                "CoughCNN model not found in bundle (expected CoughCNN.mlmodelc or CoughCNN.mlpackage)"])
    }
    
    static var clipsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("CoughClips", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func writeClip(samples: [Float], id: UUID) -> String? {
        guard !samples.isEmpty, let fmt = monoFormat else { return nil }
        let filename = id.uuidString + ".caf"
        let url = Self.clipsDirectory.appendingPathComponent(filename)
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt,
                                         frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
        buf.frameLength = AVAudioFrameCount(samples.count)
        if let ch = buf.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { ch.update(from: $0.baseAddress!, count: samples.count) }
        }
        do {
            let file = try AVAudioFile(forWriting: url, settings: fmt.settings)
            try file.write(from: buf)
            return filename
        } catch {
            print("writeClip failed: \(error)")
            return nil
        }
    }

    private func pf(_ v: Float) -> String { String(format: "%.4f", v) }
    private func pd(_ v: Double) -> String { String(format: "%.3f", v) }
}

// MARK: - SN Gate Observer

private final class SNGateObserver: NSObject, SNResultsObserving {
    var latestCough: Double  = 0
    var latestSpeech: Double = 0
    private(set) var hasResult: Bool = false

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let r = result as? SNClassificationResult else { return }

        let top = r.classifications.prefix(5).map { "\($0.identifier)=\(String(format:"%.2f",$0.confidence))" }
        print("[SN] \(top.joined(separator: "  "))")

        latestCough  = r.classification(forIdentifier: "cough")?.confidence  ?? 0
        latestSpeech = r.classification(forIdentifier: "speech")?.confidence ?? 0
        hasResult = true
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("SNGateObserver error: \(error)")
    }

    func requestDidComplete(_ request: SNRequest) {}
}
