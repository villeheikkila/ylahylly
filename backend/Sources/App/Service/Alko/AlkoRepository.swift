import Foundation
import PostgresNIO

struct AlkoRepository: Sendable {
    let logger: Logger

    func upsertAlkoProducts(
        _ connection: PostgresConnection,
        products: [AlkoSearchProductResponse]
    ) async throws -> [(id: UUID, isNewRecord: Bool)] {
        let columns = [
            "alko_id",
            "taste",
            "additional_info",
            "abv",
            "beer_style_id",
            "beer_style_name",
            "beer_substyle_id",
            "country_name",
            "food_symbol_id",
            "main_group_id",
            "name",
            "price",
            "product_group_id",
            "product_group_name",
            "volume",
            "online_availability_datetime_ts",
            "description",
            "certificate_id",
        ]
        var bindings: PostgresBindings = .init()
        var placeholders: [String] = []
        for (index, product) in products.enumerated() {
            bindings.append(product.id)
            bindings.append(product.taste)
            bindings.append(product.additionalInfo)
            bindings.append(product.abv)
            bindings.append(product.beerStyleId)
            bindings.append(product.beerStyleName)
            bindings.append(product.beerSubstyleId ?? [])
            bindings.append(product.countryName)
            bindings.append(product.foodSymbolId ?? [])
            bindings.append(product.mainGroupId)
            bindings.append(product.name)
            bindings.append(product.price)
            bindings.append(product.productGroupId)
            bindings.append(product.productGroupName)
            bindings.append(product.volume)
            bindings.append(product.onlineAvailabilityDatetimeTs)
            bindings.append(product.description)
            bindings.append(product.certificateId ?? [])
            let base = index * columns.count
            let paramIndices = (1 ... columns.count).map { "$\(base + $0)" }
            let placeholder = "(\(paramIndices.joined(separator: ", ")))"
            placeholders.append(placeholder)
        }
        let query = """
            INSERT INTO alko_product (\(columns.joined(separator: ", ")))
            VALUES \(placeholders.joined(separator: ", "))
            ON CONFLICT (alko_id) DO UPDATE SET
                taste = EXCLUDED.taste,
                additional_info = EXCLUDED.additional_info,
                abv = EXCLUDED.abv,
                beer_style_id = EXCLUDED.beer_style_id,
                beer_style_name = EXCLUDED.beer_style_name,
                beer_substyle_id = EXCLUDED.beer_substyle_id,
                country_name = EXCLUDED.country_name,
                food_symbol_id = EXCLUDED.food_symbol_id,
                main_group_id = EXCLUDED.main_group_id,
                name = EXCLUDED.name,
                price = EXCLUDED.price,
                product_group_id = EXCLUDED.product_group_id,
                product_group_name = EXCLUDED.product_group_name,
                volume = EXCLUDED.volume,
                online_availability_datetime_ts = EXCLUDED.online_availability_datetime_ts,
                description = EXCLUDED.description,
                certificate_id = EXCLUDED.certificate_id,
                updated_at = NOW()
            RETURNING id, (xmax = 0) AS is_new_record;
        """
        let result = try await connection.query(.init(unsafeSQL: query, binds: bindings), logger: logger)
        var productResults: [(id: UUID, isNewRecord: Bool)] = []
        for try await (id, isNewRecord) in result.decode((UUID, Bool).self) {
            productResults.append((id: id, isNewRecord: isNewRecord))
        }
        return productResults
    }

    func upsertStores(_ connection: PostgresConnection, stores: [AlkoStoreResponse]) async throws -> [(id: String, isNewRecord: Bool)] {
        let columns = [
            "id",
            "name",
            "address",
            "city",
            "postal_code",
            "latitude",
            "longitude",
            "outlet_type",
        ]
        var bindings: PostgresBindings = .init()
        var placeholders: [String] = []
        for (index, store) in stores.enumerated() {
            bindings.append(store.id)
            bindings.append(store.name)
            bindings.append(store.address)
            bindings.append(store.city)
            bindings.append(store.postalCode)
            bindings.append(store.latitude)
            bindings.append(store.longitude)
            bindings.append(store.outletType)
            let base = index * columns.count
            let paramIndices = (1 ... columns.count).map { "$\(base + $0)" }
            let placeholder = "(\(paramIndices.joined(separator: ", ")))"
            placeholders.append(placeholder)
        }
        let query = """
            INSERT INTO alko_store (\(columns.joined(separator: ", ")))
            VALUES \(placeholders.joined(separator: ", "))
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                address = EXCLUDED.address,
                city = EXCLUDED.city,
                postal_code = EXCLUDED.postal_code,
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                outlet_type = EXCLUDED.outlet_type
            RETURNING id, (xmax = 0) AS is_new_record;
        """
        let result = try await connection.query(.init(unsafeSQL: query, binds: bindings), logger: logger)
        var storeResults: [(id: String, isNewRecord: Bool)] = []
        for try await (id, isNewRecord) in result.decode((String, Bool).self) {
            storeResults.append((id: id, isNewRecord: isNewRecord))
        }
        return storeResults
    }
}
