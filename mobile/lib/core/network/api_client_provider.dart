import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return ApiClient(authRepo);
});
