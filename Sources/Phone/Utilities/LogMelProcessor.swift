import Foundation
import Accelerate
import CoreML

/// Converts a 0.6s audio window to a log-mel spectrogram matching torchaudio.MelSpectrogram exactly.
///
/// Spec: n_fft=1024, hop=256, Hann window, center=True (reflect pad n_fft/2),
/// 64 mel bands, f_min=0, f_max=11025, HTK mel scale, norm=None,
/// 10*log10(clamp(x, 1e-10)).  No mean/std normalisation (baked into model).
final class LogMelProcessor {

    static let sampleRate: Int  = 22050
    static let windowSamples: Int = 13230   // 0.6s @ 22050 Hz
    static let nFFT: Int        = 1024
    static let hopLength: Int   = 256
    static let nMels: Int       = 64
    static let nFrames: Int     = 52        // = 1 + windowSamples / hopLength

    private static let halfN: Int   = nFFT / 2 + 1   // 513 frequency bins
    private static let fMin: Double = 0.0
    private static let fMax: Double = 11025.0

    // Periodic Hann window: w[n] = 0.5 - 0.5*cos(2π*n/N)
    // Matches torchaudio default (periodic=True).
    private static let hannWindow: [Float] = {
        (0..<nFFT).map { n in
            0.5 - 0.5 * cos(2.0 * Float.pi * Float(n) / Float(nFFT))
        }
    }()

    // Mel filterbank [nMels][halfN] (triangular, HTK, norm=None)
    private static let melFB: [[Float]] = buildMelFilterbank()

    // Complex DFT setup (vDSP_DFT_zop, N=1024, FORWARD)
    private static let dftSetup: OpaquePointer = {
        guard let s = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(nFFT), .FORWARD) else {
            fatalError("LogMelProcessor: failed to create vDSP DFT setup")
        }
        return s
    }()

    // MARK: - Public API

    /// Process 13230 samples → MLMultiArray [1,1,64,52] Float16 ready for CoughCNN.
    static func process(samples: [Float]) -> MLMultiArray? {
        guard samples.count == windowSamples else {
            print("LogMelProcessor: expected \(windowSamples) samples, got \(samples.count)")
            return nil
        }

        // --- 1. Reflective padding: n_fft/2 = 512 each side → 14254 total ---
        let padSize = nFFT / 2
        var padded = [Float](repeating: 0, count: windowSamples + 2 * padSize)

        // Center
        for i in 0..<windowSamples { padded[padSize + i] = samples[i] }
        // Left reflect: padded[padSize-k] = samples[k]  (k=1..512)
        for k in 1...padSize { padded[padSize - k] = samples[k] }
        // Right reflect: padded[padSize+windowSamples+k-1] = samples[windowSamples-k-1] (k=1..512)
        for k in 1...padSize { padded[padSize + windowSamples + k - 1] = samples[windowSamples - k - 1] }

        // --- 2. STFT → power spectrogram [nFrames, halfN] ---
        var powerSpec = [Float](repeating: 0, count: nFrames * halfN)
        var realIn  = [Float](repeating: 0, count: nFFT)
        let imagIn  = [Float](repeating: 0, count: nFFT)   // always zero for real input
        var realOut = [Float](repeating: 0, count: nFFT)
        var imagOut = [Float](repeating: 0, count: nFFT)

        padded.withUnsafeBufferPointer { paddedPtr in
            hannWindow.withUnsafeBufferPointer { hannPtr in
                for frame in 0..<nFrames {
                    let offset = frame * hopLength
                    // Windowed frame → realIn
                    vDSP_vmul(paddedPtr.baseAddress! + offset, 1,
                               hannPtr.baseAddress!, 1,
                               &realIn, 1, vDSP_Length(nFFT))
                    // DFT (complex input, real imaginary part is zero)
                    realIn.withUnsafeBufferPointer { rIn in
                        imagIn.withUnsafeBufferPointer { iIn in
                            vDSP_DFT_Execute(dftSetup,
                                             rIn.baseAddress!, iIn.baseAddress!,
                                             &realOut, &imagOut)
                        }
                    }
                    // Power = re² + im² for each of the halfN unique bins
                    let base = frame * halfN
                    for k in 0..<halfN {
                        let re = realOut[k]; let im = imagOut[k]
                        powerSpec[base + k] = re * re + im * im
                    }
                }
            }
        }

        // --- 3. Mel filterbank dot-products → log-mel [nMels × nFrames] ---
        var logMel = [Float](repeating: 0, count: nMels * nFrames)

        powerSpec.withUnsafeBufferPointer { psPtr in
            for m in 0..<nMels {
                melFB[m].withUnsafeBufferPointer { fbPtr in
                    for f in 0..<nFrames {
                        var energy: Float = 0
                        vDSP_dotpr(fbPtr.baseAddress!, 1,
                                   psPtr.baseAddress! + f * halfN, 1,
                                   &energy, vDSP_Length(halfN))
                        // 10 * log10(max(energy, 1e-10))
                        logMel[m * nFrames + f] = 10.0 * log10(max(energy, 1e-10))
                    }
                }
            }
        }

        // --- 4. Pack into MLMultiArray [1,1,64,52] Float16 ---
        guard let array = try? MLMultiArray(shape: [1, 1, 64, 52], dataType: .float16) else {
            return nil
        }
        array.dataPointer.withMemoryRebound(to: Float16.self, capacity: nMels * nFrames) { ptr in
            for i in 0..<(nMels * nFrames) { ptr[i] = Float16(logMel[i]) }
        }
        return array
    }

    // MARK: - Mel Filterbank

    private static func buildMelFilterbank() -> [[Float]] {
        func hzToMel(_ hz: Double) -> Double { 2595.0 * log10(1.0 + hz / 700.0) }
        func melToHz(_ mel: Double) -> Double { 700.0 * (pow(10.0, mel / 2595.0) - 1.0) }

        let melMin = hzToMel(fMin)
        let melMax = hzToMel(fMax)

        // nMels+2 = 66 equally-spaced mel points (matches torch.linspace)
        let step = (melMax - melMin) / Double(nMels + 1)
        let fPts = (0..<(nMels + 2)).map { melToHz(melMin + Double($0) * step) }

        // FFT bin center frequencies: k * sr / n_fft
        let fftFreqs = (0..<halfN).map { Double($0) * Double(sampleRate) / Double(nFFT) }

        var fb = [[Float]](repeating: [Float](repeating: 0, count: halfN), count: nMels)

        for m in 0..<nMels {
            let fLow    = fPts[m]
            let fCenter = fPts[m + 1]
            let fHigh   = fPts[m + 2]
            let dLow    = fCenter - fLow
            let dHigh   = fHigh - fCenter
            guard dLow > 0, dHigh > 0 else { continue }

            for k in 0..<halfN {
                let f = fftFreqs[k]
                let v = max(0.0, min((f - fLow) / dLow, (fHigh - f) / dHigh))
                fb[m][k] = Float(v)
            }
        }
        return fb
    }
}
