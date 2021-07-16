import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    let databaseName: String
    let databasePort: Int
    
    
    if (app.environment == .testing) {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = "vapor_database"
        databasePort = 5432
    }

    if var config = Environment.get("DATABASE_URL")
        .flatMap(URL.init)
        .flatMap(PostgresConfiguration.init) {
        config.tlsConfiguration = .forClient(
            certificateVerification: .none)
        app.databases.use(.postgres(
            configuration: config
        ), as: .psql)
    } else {
        app.databases.use(
            .postgres(
                hostname: Environment.get("DATABASE_HOST") ??
                    "localhost",
                port: databasePort,
                username: Environment.get("DATABASE_USERNAME") ??
                    "vapor_username",
                password: Environment.get("DATABASE_PASSWORD") ??
                    "vapor_password",
                database: Environment.get("DATABASE_NAME") ??
                    databaseName),
            as: .psql)
    }

    
//    Increase payload
    app.routes.defaultMaxBodySize = "10mb"
    app.migrations.add(CreateUser())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateRecipe())
    app.migrations.add(CreateRecipeCategoryPivot())
    app.migrations.add(CreateUserConnectionPivot())
    app.migrations.add(CreateUserLikesRecipePivot())
    app.migrations.add(CreateUserWorkingOnRecipePivot())
    app.migrations.add(CreateUserUsedRecipePivot())
    app.migrations.add(CreateUserRatesRecipePivot())
    app.migrations.add(CreateTokenMigration())
//    app.migrations.add(CreateAdminUser())

    app.logger.logLevel = .debug
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
