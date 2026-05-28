// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$servicesHash() => r'846f9ef25fdd50b2f80be95e27186d055a1a95fa';

/// See also [services].
@ProviderFor(services)
final servicesProvider =
    AutoDisposeFutureProvider<List<ServiceEntity>>.internal(
  services,
  name: r'servicesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$servicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ServicesRef = AutoDisposeFutureProviderRef<List<ServiceEntity>>;
String _$bookingNotifierHash() => r'2d124de50c8a128116752fb2333ee4d52f7c7f05';

/// See also [BookingNotifier].
@ProviderFor(BookingNotifier)
final bookingNotifierProvider =
    NotifierProvider<BookingNotifier, BookingState>.internal(
  BookingNotifier.new,
  name: r'bookingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BookingNotifier = Notifier<BookingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
