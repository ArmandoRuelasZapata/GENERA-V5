import 'package:freezed_annotation/freezed_annotation.dart';
part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.unauthorized(String message) = UnauthorizedFailure;

  const Failure._();

  @override
  String get message => when(
        server: (msg) => msg,
        network: (msg) => msg,
        cache: (msg) => msg,
        validation: (msg) => msg,
        unauthorized: (msg) => msg,
      );
}
