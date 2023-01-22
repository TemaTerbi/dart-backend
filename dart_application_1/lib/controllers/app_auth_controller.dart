import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:dart_application_1/model/user.dart';
import 'package:dart_application_1/model/model_response.dart';
import 'package:dart_application_1/utils/app_utils.dart';

class AppAuthController extends ResourceController {
  AppAuthController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.username == null) {
      return Response.badRequest(
          body:
              ModelResponse(message: 'Поля username, password - обязательны!'));
    }

    try {
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.username).equalTo(user.username)
        ..returningProperties(
          (element) => [element.id, element.salt, element.hashPassword],
        );

      final findUser = await qFindUser.fetchOne();

      if (findUser == null) {
        throw QueryException.input("Пользователь не найден", []);
      }

      final requestHashPassword =
          generatePasswordHash(user.password ?? '', user.salt ?? '');

      if (requestHashPassword == findUser.hashPassword) {
        _updateTokens(findUser.id ?? -1, managedContext);

        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);

        return Response.ok(
          ModelResponse(
              data: newUser!.backing.contents, message: "Успешная авторизация"),
        );
      } else {
        throw QueryException.input("Не верный пароль", []);
      }
    } on QueryException catch (e) {
      return Response.serverError(
        body: ModelResponse(message: e.message),
      );
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.username == null || user.email == null) {
      return Response.badRequest(
        body: ModelResponse(
            message: 'Поля username, password, email - обязательны!'),
      );
    }

    final salt = generateRandomSalt();

    final hashPassword = generatePasswordHash(user.password!, salt);

    try {
      late final int id;

      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();

        id = createdUser.id!;

        _updateTokens(id, transaction);
      });

      final userData = await managedContext.fetchObjectWithID<User>(id);

      return Response.ok(
        ModelResponse(
            data: userData!.backing.contents,
            message: "Пользователь успешно зарегистрировался"),
      );
    } on QueryException catch (e) {
      return Response.serverError(
        body: ModelResponse(message: e.message),
      );
    }
  }

  @Operation.post("refresh")
  Future<Response> refreshToken(
      @Bind.path("refresh") String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);

      final user = await managedContext.fetchObjectWithID<User>(id);

      if (user!.refreshToken != refreshToken) {
        return Response.unauthorized(body: "Токен не валиден");
      }

      _updateTokens(id, managedContext);

      return Response.ok(
        ModelResponse(
            data: user.backing.contents, message: "Токен успешно обновлен"),
      );
    } on QueryException catch (e) {
      return Response.serverError(
        body: ModelResponse(message: e.message),
      );
    }
  }

  void _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, String> tokens = _getTokens(id);

    final qUpdateTokens = Query<User>(transaction)
      ..where((element) => element.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTokens.updateOne();
  }

  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    print(key);
    final accessClaimSet = JwtClaim(
      maxAge: const Duration(hours: 1),
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(accessClaimSet, key);

    return tokens;
  }
}
