class ModelResponse {
  ModelResponse({this.error, this.data, this.message});

  final dynamic error;
  final dynamic data;
  final dynamic message;

  Map<String, dynamic> toJson() =>
      {'error': error ?? '', 'data': data ?? '', 'message': message ?? ''};
}

class CodeResponse {
  CodeResponse({this.validate});

  final dynamic validate;

  Map<String, dynamic> toJson() => {'validate': validate ?? ''};
}
