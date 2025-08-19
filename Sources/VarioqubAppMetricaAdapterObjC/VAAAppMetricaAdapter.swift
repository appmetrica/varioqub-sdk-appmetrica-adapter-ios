
import Foundation

#if VQ_MODULES
import Varioqub
import VarioqubObjC
import VarioqubAppMetricaAdapter
#else
import Varioqub
#endif

import AppMetricaCore
import AppMetricaCoreExtension

@objc
public final class VAAAppMetricaAdapter: NSObject {

    let adapter: AppMetricaAdapter

    public override init() {
        adapter = .init()
        super.init()
    }
    
    public init(adapter: AppMetricaAdapter) {
        self.adapter = adapter
        super.init()
    }
    
    @objc
    public convenience init(handleQueue: DispatchQueue) {
        self.init(adapter: .init(handleQueue: handleQueue))
    }
    
    @objc
    public convenience init(reporter: AppMetricaExtendedReporting, handleQueue: DispatchQueue) {
        self.init(adapter: .init(reporter: reporter, handleQueue: handleQueue))
    }
    
    @objc
    public convenience init?(apiKey: String, handleQueue: DispatchQueue) {
        guard let adapter = AppMetricaAdapter(apiKey: apiKey, handleQueue: handleQueue) else { return nil }
        self.init(adapter: adapter)
    }
    
}

extension VAAAppMetricaAdapter: VQReporter, VQIdProvider {
    
    public var varioqubName: String {
        return adapter.varioqubName
    }
    

    public func fetchIdentifiers(completion: @escaping VQIdCompletion) {
        adapter.fetchIdentifiers { result in
            switch result {
            case .success(let id):
                completion(id.userId, id.deviceId, nil)
            case .failure(let e):
                let nsError = NSError(domain: e._domain, code: e._code, userInfo: e._userInfo as? [String: Any])
                completion(nil, nil, nsError)
            }
        }
    }

    public func setExperiments(_ experiments: String) {
        adapter.setExperiments(experiments)
    }

    public func setTriggeredTestIds(_ testIds: VQTestIDSet) {
        let oriSet = testIds.testIDSet
        adapter.setTriggeredTestIds(oriSet)
    }
    
    public func sendActivateEvent(_ eventData: VQActivateEventData) {
        let ed = VarioqubEventData(
            fetchDate: eventData.fetchDate,
            oldVersion: eventData.oldVersion,
            newVersion: eventData.newVersion
        )
        adapter.sendActivateEvent(ed)
    }
    
    
}
