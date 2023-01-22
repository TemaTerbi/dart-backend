import 'dart:async';
import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_application_1/utils/app_response.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:dart_application_1/utils/app_utils.dart';

class AppTokenController extends Controller {
  @override
  FutureOr<RequestOrResponse?> handle(Request request) {
    try {
      final header = request.raw.headers.value(HttpHeaders.authorizationHeader);
      final token = const AuthorizationBearerParser().parse(header);
      final key = AppUtils.test();
      final jwtClaim = verifyJwtHS256Signature(token ?? "", key);
      jwtClaim.validate();
      return request;
    } on JwtException catch (e) {
      return AppResponse.severError(e.message);
    }
  }
}
