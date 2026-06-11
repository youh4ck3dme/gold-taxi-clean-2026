import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/models/faq_model.dart';
import '../bloc/faq_bloc.dart';
import '../bloc/faq_event.dart';
import '../bloc/faq_state.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  Map<String, List<FaqModel>> _groupFaqsByCategory(List<FaqModel> faqs) {
    final groups = <String, List<FaqModel>>{};
    for (final faq in faqs) {
      groups.putIfAbsent(faq.category, () => []).add(faq);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FaqBloc>()..add(const FetchFaqs()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Často kladené otázky')),
        body: BlocBuilder<FaqBloc, FaqState>(
          builder: (context, state) {
            if (state is FaqLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FaqError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chyba: ${state.message}', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FaqBloc>().add(const FetchFaqs(isRefresh: true));
                      },
                      child: const Text('Skúsiť znova'),
                    )
                  ],
                ),
              );
            } else if (state is FaqLoaded) {
              final faqs = state.faqs;
              if (faqs.isEmpty) {
                return const Center(child: Text('Nenašli sa žiadne FAQ.'));
              }

              final groupedFaqs = _groupFaqsByCategory(faqs);

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FaqBloc>().add(const FetchFaqs(isRefresh: true));
                },
                child: ListView.builder(
                  itemCount: groupedFaqs.keys.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final category = groupedFaqs.keys.elementAt(index);
                    final categoryFaqs = groupedFaqs[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        ...categoryFaqs.map((faq) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              title: Text(
                                faq.question,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    faq.answer.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                                    style: const TextStyle(fontSize: 15, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
