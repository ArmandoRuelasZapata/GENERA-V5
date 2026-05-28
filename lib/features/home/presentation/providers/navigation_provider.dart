import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el índice de navegación activo
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Provider para controlar el estado del drawer
final drawerProvider = StateProvider<bool>((ref) => false);

// Provider para navegacion dentro de StoreTap
final storeTabIndexProvider = StateProvider<int>((ref) => 0);
