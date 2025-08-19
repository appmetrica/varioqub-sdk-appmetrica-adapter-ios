
import Foundation
import Varioqub

extension VarioqubEventData {
    
    var attributesMap: [AnyHashable: Any] {
        var result: [AnyHashable: Any] = [:]
        
        result["new_config"] = newVersion
        if let oldVersion = oldVersion {
            result["old_config"] = oldVersion
        }
        if let fetchDate = fetchDate {
            result["timestamp"] = Int64(fetchDate.timeIntervalSince1970) * 1000
        }
        
        return result
    }
    
}
