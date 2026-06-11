import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(BuildContext context, String query) {
    context.read<SearchBloc>().add(SearchQueryChanged(query));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>()..add(LoadSearchHistory()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vyhľadávanie')),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppTextField(
                    controller: _searchController,
                    labelText: 'Hľadať...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onQueryChanged(context, '');
                      },
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => _onQueryChanged(context, value),
                    validator: null,
                    hintText: 'Zadajte hľadaný výraz',
                    keyboardType: TextInputType.text,
                  ),
                ),
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is SearchError) {
                        return Center(
                          child: Text(
                            'Chyba: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (state is SearchInitial) {
                        final history = state.history;
                        if (history.isEmpty) {
                          return const Center(
                            child: Text(
                              'Zadajte výraz pre vyhľadávanie',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'História vyhľadávania',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<SearchBloc>().add(ClearHistory());
                                  },
                                  child: const Text('Vymazať', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: history.map((term) {
                                return ActionChip(
                                  label: Text(term),
                                  onPressed: () {
                                    _searchController.text = term;
                                    _onQueryChanged(context, term);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      } else if (state is SearchSuccess) {
                        final results = state.result;
                        if (results.isEmpty) {
                          return const Center(
                            child: Text('Nenašli sa žiadne výsledky.'),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (results.products.isNotEmpty) ...[
                              _buildSectionHeader('Produkty'),
                              ...results.products.map(
                                (p) => _buildResultTile(
                                  title: p.name,
                                  subtitle: '${p.price.toStringAsFixed(2)} €',
                                  icon: Icons.shopping_bag_outlined,
                                  onTap: () => context.push('/products/detail', extra: p),
                                ),
                              ),
                            ],
                            if (results.services.isNotEmpty) ...[
                              _buildSectionHeader('Služby'),
                              ...results.services.map(
                                (s) => _buildResultTile(
                                  title: s.name,
                                  subtitle: s.category,
                                  icon: Icons.drive_eta_outlined,
                                  onTap: () => context.push('/services/detail', extra: s),
                                ),
                              ),
                            ],
                            if (results.events.isNotEmpty) ...[
                              _buildSectionHeader('Udalosti'),
                              ...results.events.map(
                                (e) => _buildResultTile(
                                  title: e.title,
                                  subtitle: e.category,
                                  icon: Icons.event_outlined,
                                  onTap: () => context.push('/events/detail', extra: e),
                                ),
                              ),
                            ],
                            if (results.posts.isNotEmpty) ...[
                              _buildSectionHeader('Články'),
                              ...results.posts.map(
                                (p) => _buildResultTile(
                                  title: p.title,
                                  subtitle: p.excerpt.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                                  icon: Icons.article_outlined,
                                  onTap: () => context.push('/blog/detail', extra: p),
                                ),
                              ),
                            ],
                          ],
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildResultTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
