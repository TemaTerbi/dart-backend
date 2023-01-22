import 'dart:io';
import 'dart:math';

import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:dart_application_1/model/user.dart';
import 'package:dart_application_1/model/model_response.dart';
import 'package:dart_application_1/utils/app_utils.dart';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AppCodeController extends ResourceController {
  AppCodeController(this.managedContext, this.code);

  final ManagedContext managedContext;
  int code;

  @Operation.get("email")
  Future<Response> codeSent() async {
    code = 0;
    final email = request!.path.variables['email'];

    String mailUserName = "isip_a.v.soloviev@mpt.ru";
    String mailPassword = "KvazI132410";

    final smtpServer = SmtpServer('smtp.gmail.com',
        username: mailUserName, password: mailPassword, port: 587);
    final min = 1000;
    final max = 9000;
    Random random = new Random();
    code = random.nextInt(max - min);

    final qFindCode = Query<Code>(managedContext)
      ..where((element) => element.email).equalTo(email)
      ..returningProperties(
        (element) => [element.email],
      );

    final findCode = await qFindCode.fetchOne();

    if (findCode != null) {
      throw QueryException.input("На данную почту уже был отправлен код", []);
    } else {
      try {
        final message = Message()
          ..from = Address(mailUserName, 'HYPE MAP')
          ..recipients.add(Address(email!))
          ..subject = 'Твой код подтверждения $code 📬'
          ..html =
              "<h1>$code</h1>\n<p>Спасибо за регистрацию в нашем приложении!</p>";

        try {
          final sendReport = await send(message, smtpServer);
          print(
            'Сообщение отправлено: ' + sendReport.toString(),
          );
        } on MailerException catch (e) {
          print('Сообщение не было отправлено');
          print(e.message);
          return Response.serverError(
            body: ModelResponse(message: e.message),
          );
        }

        late final int id;

        await managedContext.transaction((transaction) async {
          final qCreateCode = Query<Code>(transaction)
            ..values.code = code
            ..values.email = email;

          final createCode = await qCreateCode.insert();

          id = createCode.id!;
        });

        final codeData = await managedContext.fetchObjectWithID<Code>(id);

        return Response.ok(
          ModelResponse(
              data: codeData!.backing.contents,
              message: "Код был успешно отправлен!"),
        );
      } on QueryException catch (e) {
        return Response.serverError(
          body: ModelResponse(message: e.message),
        );
      }
    }
  }

  @Operation.post("code")
  Future<Response> codeCheck() async {
    final userCode = request!.path.variables['code'];
    if (userCode == null) {
      return Response.badRequest(
        body: ModelResponse(message: 'Code не был введен'),
      );
    }

    int userCodeInt = int.parse(userCode);

    final qFindCode = Query<Code>(managedContext)
      ..where((element) => element.code).equalTo(userCodeInt)
      ..returningProperties(
        (element) => [element.code],
      );

    final findCode = await qFindCode.fetchOne();

    if (findCode == null) {
      return Response.ok(
        CodeResponse(validate: false),
      );
    }

    int findedCode = findCode.code!;
    qFindCode.delete();

    try {
      return findedCode == userCodeInt
          ? Response.ok(
              CodeResponse(validate: true),
            )
          : Response.ok(
              CodeResponse(validate: false),
            );
    } on QueryException catch (e) {
      return Response.serverError(
        body: ModelResponse(message: e.message),
      );
    }
  }
}
