import Foundation

import Varioqub
import AppMetricaCore
import AppMetricaCoreExtension

typealias IdentifiersFetchBlock = ([StartupKey: Any]?, Error?) -> ()

final class AppMetricaImpl: AppMetricaReporterProtocol, AppMetricaProtocol {
    
    func fetchIdentifiers(completionQueue: DispatchQueue, completion: @escaping VarioqubIdProvider.Completion) {
        let block: IdentifiersFetchBlock =  { identifiers, error in
            log.trace("identifiers was obtained: \(identifiers.debugDescription) error: \(error.debugDescription)")
            let result: Result<VarioqubIdentifiers, VarioqubProviderError>
            defer { completion(result) }

            if let identifiers = identifiers,
               let userId = identifiers[StartupKey.uuidKey] as? String,
               let deviceId = identifiers[StartupKey.deviceIDKey] as? String {
                let ids = VarioqubIdentifiers(deviceId: deviceId, userId: userId)
                result = .success(ids)
            } else if let error = error {
                result = .failure(.underlying(error: error))
            } else {
                result = .failure(.general)
            }
        }

        AppMetrica.requestStartupIdentifiers(for: [StartupKey.deviceIDKey, StartupKey.uuidKey],
                on: completionQueue, completion: block)
    }

    func setExtras(data: Data?, for key: String) {
        AppMetrica.setSessionExtra(value: data, for: key)
    }
    
    func reportEvent(name: String, attributes: [AnyHashable: Any]) {
        AppMetrica.reportEvent(name: name, parameters: attributes)
    }

}

final class AppMetricaReporterImpl: AppMetricaReporterProtocol {
    
    let reporter: AppMetricaExtendedReporting
    init(reporter: AppMetricaExtendedReporting) {
        self.reporter = reporter
    }
    
    func setExtras(data: Data?, for key: String) {
        reporter.setSessionExtra(value: data, for: key)
    }
    
    func reportEvent(name: String, attributes: [AnyHashable: Any]) {
        reporter.reportEvent(name: name, parameters: attributes)
    }
}
