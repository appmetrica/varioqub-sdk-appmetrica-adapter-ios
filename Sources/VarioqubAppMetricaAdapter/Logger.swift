
#if VQ_LOGGER

#if VQ_MODULES
import VarioqubLogger
#else
import Varioqub
#endif

public let loggerModuleString = LoggerModule(rawValue: "com.varioqub.appmetricaadapter")
let log = Logger(moduleName: loggerModuleString)

#else
import Logging
public let loggerModuleString = "com.varioqub.appmetricaadapter"
let log = Logger(label: loggerModuleString)
#endif
