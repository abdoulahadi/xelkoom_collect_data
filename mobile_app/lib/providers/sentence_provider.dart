import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sentence.dart';
import 'auth_provider.dart';

// Provider pour la sentence actuelle
final currentSentenceProvider = StateProvider<Sentence?>((ref) => null);

// Provider pour charger la prochaine sentence
final nextSentenceProvider = FutureProvider<Sentence>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getNextSentence();
});

// Provider pour recharger une nouvelle sentence
final reloadSentenceProvider = StateProvider<int>((ref) => 0);

// Provider qui se recharge quand reloadSentenceProvider change
final refreshableSentenceProvider = FutureProvider<Sentence>((ref) {
  // Écouter les changements de reloadSentenceProvider
  ref.watch(reloadSentenceProvider);

  final apiService = ref.read(apiServiceProvider);
  return apiService.getNextSentence();
});
