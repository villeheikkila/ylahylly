import Foundation
import Hummingbird
import HummingbirdRedis
import Logging
import OluttaShared
import PostgresNIO

struct AppController {
    let logger: Logger
    let pg: PostgresClient
    let persist: RedisPersistDriver
    let alkoRepository: AlkoRepository

    var endpoints: RouteCollection<AppRequestContext> {
        RouteCollection(context: AppRequestContext.self)
            .get("stores", use: stores)
    }
}

extension AppController {
    func stores(request _: Request, context _: some RequestContext) async throws -> [StoreEntity] {
        let key = "stores::v2"
        let cachedValue = try await persist.get(key: key, as: [StoreEntity].self)
        if let cachedValue {
            logger.info("returning cached stores")
            return cachedValue
        }
        let stores = try await pg.withTransaction { tx in
            try await alkoRepository.getStores(tx)
        }
        let res: [StoreEntity] = stores.map { store in
            StoreEntity(
                id: store.id,
                alkoStoreId: store.alkoStoreId,
                name: store.name,
                address: store.address,
                city: store.city,
                postalCode: store.postalCode,
                latitude: store.latitude,
                longitude: store.longitude,
            )
        }
        try await persist.set(key: key, value: res, expires: .seconds(60))
        return res
    }
}
