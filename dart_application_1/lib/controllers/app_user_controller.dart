import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:conduit/conduit.dart';
import 'package:dart_application_1/utils/app_response.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:dart_application_1/model/user.dart';
import 'package:dart_application_1/model/model_response.dart';
import 'package:dart_application_1/utils/app_utils.dart';

class AppUserController extends ResourceController {
  AppUserController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getProfile(
      @Bind.header(HttpHeaders.acceptCharsetHeader) String header) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(id);
      user!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);
      return AppResponse.ok(
          body: user.backing.contents, message: "Профиль успешно получен");
    } catch (e) {
      return AppResponse.severError(e, message: "Ошибка получения профиля");
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
      @Bind.header(HttpHeaders.acceptCharsetHeader) String header,
      @Bind.body() User user) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final fUser = await managedContext.fetchObjectWithID<User>(id);

      final qUpdateUser = Query<User>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..values.username = user.username ?? fUser!.username
        ..values.email = user.email ?? fUser!.email;

      await qUpdateUser.updateOne();
      final findUser = await managedContext.fetchObjectWithID<User>(id);
      findUser!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);
      return AppResponse.ok(
          body: findUser.backing.contents,
          message: "Данные были успешно обновлены!");
    } catch (e) {
      return AppResponse.severError(e, message: "Данные не были обновлены");
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
      @Bind.header(HttpHeaders.acceptCharsetHeader) String header,
      @Bind.query('newPassword') String newPassword,
      @Bind.query('oldPassword') String oldPassword) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..returningProperties(
          (element) => [element.salt, element.hashPassword],
        );

      final fUser = await qFindUser.fetchOne();
      final oldHashPassword =
          generatePasswordHash(oldPassword, fUser!.salt ?? "");

      if (oldHashPassword != fUser.hashPassword) {
        return AppResponse.severError("error",
            message: "Неверный старый пароль");
      }

      final newHashPassword =
          generatePasswordHash(newPassword, fUser.salt ?? "");

      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.hashPassword = newHashPassword;

      await qUpdateUser.fetchOne();

      return AppResponse.ok(body: "Пароль успешно обновлен");
    } catch (e) {
      return AppResponse.severError(e, message: "Ошибка обновления пароля");
    }
  }
}
