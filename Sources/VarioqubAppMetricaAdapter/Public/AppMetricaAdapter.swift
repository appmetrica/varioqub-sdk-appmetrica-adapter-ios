import Foundation

import Varioqub
#if VQ_MODULES
import VarioqubUtils
#endif
import AppMetricaCore
import AppMetricaCoreExtension

let varioqubEventName = "com.yandex.varioqub.activate_config"

/// AppMetricaAdapter rely on AppMetrica library.
///
/// See details: https://appmetrica.io
public class AppMetricaAdapter: VarioqubReporter, VarioqubIdProvider {
    
    private let dataLock = UnfairLock()

    private var identifiers: VarioqubIdentifiers?
    private var extra = VarioqubMessage()
    private let appMetricaImpl: AppMetricaProtocol
    private let reporterImpl: AppMetricaReporterProtocol

    public let varioqubKey: String = "varioqub"
    public let handleQueue: DispatchQueue
    

    public init(handleQueue: DispatchQueue = .main) {
        let impl = AppMetricaImpl()
        
        self.appMetricaImpl = impl
        self.reporterImpl = impl
        self.handleQueue = handleQueue
    }
    
    public init?(apiKey: String, handleQueue: DispatchQueue = .main) {
        guard let reporter = AppMetrica.extendedReporter(for: apiKey) else { return nil }
        let impl = AppMetricaImpl()
        let reporterImpl = AppMetricaReporterImpl(reporter: reporter)
        
        self.appMetricaImpl = impl
        self.reporterImpl = reporterImpl
        self.handleQueue = handleQueue
    }
    
    public init(reporter: AppMetricaExtendedReporting, handleQueue: DispatchQueue = .main) {
        let impl = AppMetricaImpl()
        let reporterImpl = AppMetricaReporterImpl(reporter: reporter)
        
        self.appMetricaImpl = impl
        self.reporterImpl = reporterImpl
        self.handleQueue = handleQueue
    }

    /// Varioqub adapter name.
    ///
    /// Used for analytics purposes.
    public var varioqubName: String {
        return "AppMetricaAdapter"
    }

    
    /// Sets an experiment.
    ///
    /// - parameter experiments: The experiment identifier.
    open func setExperiments(_ experiments: String) {
        log.trace("setExperiment: \(experiments)")

        let (new, impl) = dataLock.lock {
            extra.encryptedExperiments = experiments
            return (extra, reporterImpl)
        }

        setExtras(new, for: impl)
    }

    /// Sets triggered IDs.
    ///
    /// - parameter triggeredTestIds: The set of the triggered test IDs.
    open func setTriggeredTestIds(_ triggeredTestIds: VarioqubTestIDSet) {
        log.trace("reportTriggeredTestId: \(triggeredTestIds)")

        let (new, impl) = dataLock.lock {
            extra.triggeredTestIds = triggeredTestIds.set.map { $0.rawValue }
            return (extra, reporterImpl)
        }

        setExtras(new, for: impl)
    }

    /// Sends an activation event.
    ///
    /// - parameter eventData: The struct that represents the information about activation.
    open func sendActivateEvent(_ eventData: VarioqubEventData) {
        log.trace("sendEvent: \(eventData)")

        let parameters = eventData.attributesMap

        let impl = dataLock.lock { return reporterImpl }

        impl.reportEvent(name: varioqubEventName, attributes: parameters)
    }

    /// Obtains identifiers(deviceId and userId).
    ///
    /// - parameter completion: Notifies when the operation ends.
    open func fetchIdentifiers(completion: @escaping VarioqubIdProvider.Completion) {
        log.trace("fetchIdentifiers started")

        let (idf, impl) = dataLock.lock {
            return (identifiers, appMetricaImpl)
        }

        if let idf = idf {
            completion(.success(idf))
            return
        }

        impl.fetchIdentifiers(completionQueue: handleQueue) { result in
            log.trace("identifiers was obtained: \(result)")

            switch result {
            case .success(let ans):
                self.dataLock.lock { self.identifiers = ans }
                completion(.success(ans))
            case .failure(let e):
                self.dataLock.lock { self.identifiers = nil }
                completion(.failure(e))
            }
        }
    }

}

private extension AppMetricaAdapter {
    
    func setExtras(_ extra: VarioqubMessage, `for` reporterImpl: AppMetricaReporterProtocol) {
        do {
            let data = try extra.serializedData()
            log.trace("session extra data: \(data.base64EncodedString())")
            reporterImpl.setExtras(data: data, for: varioqubKey)
        } catch let e {
            log.error("parsing serialized data error: \(e)")
            reporterImpl.setExtras(data: nil, for: varioqubKey)
        }
    }
    
}
