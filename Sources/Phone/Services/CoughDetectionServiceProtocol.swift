import Foundation

protocol CoughDetectionServiceProtocol: AnyObject {
    var delegate: CoughDetectionServiceDelegate? { get set }
    func start() throws
    func stop()
}

protocol CoughDetectionServiceDelegate: AnyObject {
    func coughDetectionService(_ service: CoughDetectionServiceProtocol, didDetect event: CoughEvent)
}
