
import Foundation
import Varioqub

protocol AppMetricaReporterProtocol: AnyObject {
    func setExtras(data: Data?, for key: String)
    func reportEvent(name: String, attributes: [AnyHashable: Any])
}

protocol AppMetricaProtocol {
    func fetchIdentifiers(completionQueue: DispatchQueue, completion: @escaping VarioqubIdProvider.Completion)
}
