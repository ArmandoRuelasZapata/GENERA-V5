import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:theoriginallab_v2/core/network/network_client.dart';
import 'package:theoriginallab_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:theoriginallab_v2/features/tickets/data/repositories/api_tickets_repository.dart';

void main() {
  test('Fetch Tickets Script', () async {
    // 1. Initial manual auth client
    final client = AppNetworkClient(readToken: () async => null);
    final authDio = client.createClient(
      baseUrl:
          'https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host',
      enableAuth: false,
      usePinning: false,
    );
    final exchangeDio = client.createClient(
      baseUrl: 'https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host',
      enableAuth: true,
      usePinning: false, // Turn off pinning for local test
    );

    final authDS = AuthRemoteDataSourceImpl(authDio, exchangeDio: exchangeDio);

    // Attempt Login
    final user =
        await authDS.login(email: 'test@example.com', password: 'test1234');
    final String? token = user.token;

    debugPrint('LOGIN SUCCESS');

    // 2. Tickets Client
    final ticketsClient = AppNetworkClient(readToken: () async => token);
    final ticketsDio = ticketsClient.createClient(
      baseUrl: 'https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host',
      enableAuth: true,
      useEncryption: true,
      usePinning: false, // Turn off pinning
    );

    final repo = ApiTicketsRepository(dio: ticketsDio);
    final res = await repo.getActiveTickets(userId: user.id);

    res.fold(
      (l) => debugPrint('ERROR FETCHING TICKETS: ${l.message}'),
      (tickets) {
        debugPrint('SUCCESS FETCHING TICKETS: ${tickets.length}');
        if (tickets.isNotEmpty) {
          debugPrint('FIRST TICKET: ${tickets.first.title}');
        }
      },
    );
  });
}
