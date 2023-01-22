import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_application_1/controllers/app_token_controller.dart';
import 'package:dart_application_1/controllers/app_user_controller.dart';
import 'model/user.dart';
import 'controllers/app_auth_controller.dart';
import 'controllers/app_code_controller.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;
  final int code = 0;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);
    return super.prepare();
  }

  @override
  // Controller get entryPoint => Router();
  Controller get entryPoint => Router()
    ..route("token/[:refresh]").link(
      () => AppAuthController(managedContext),
    )
    ..route("signUp").link(
      () => AppAuthController(managedContext),
    )
    ..route("sigIn").link(
      () => AppAuthController(managedContext),
    )
    ..route("code/[:email]").link(
      () => AppCodeController(managedContext, code),
    )
    ..route("codeCheck/[:code]").link(
      () => AppCodeController(managedContext, code),
    )
    ..route("user")
        .link(AppTokenController.new)!
        .link(() => AppUserController(managedContext));

  PersistentStore _initDatabase() {
    final username = Platform.environment["DB_USERNAME"] ?? "postgres";
    final password = Platform.environment["DB_PASSWORD"] ?? "1324";
    final host = Platform.environment["DB_HOST"] ?? "localhost";
    final port = int.parse(Platform.environment["DB_PORT"] ?? "5432");
    final databaseName = Platform.environment["DB_NAME"] ?? "postgres";
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
