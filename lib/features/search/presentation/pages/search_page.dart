import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mock_geocoding_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _destinationController = TextEditingController();
  List<LocationModel> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  Future<void> _loadInitialSuggestions() async {
    setState(() => _isLoading = true);
    final results = await MockGeocodingService.search('');
    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  Future<void> _onQueryChanged(String query) async {
    setState(() => _isLoading = true);
    final results = await MockGeocodingService.search(query);
    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  void _selectLocation(LocationModel location) {
    // In a real app, we'd also have a pickup location.
    // Here we assume "Current Position" as pickup for now.
    context.push('/ride-request', extra: location);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Kam to bude?'), elevation: 0),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _destinationController,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Zadajte cieľovú adresu (Košice)',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                ),
                filled: true,
                fillColor: isDarkMode ? AppColors.grey900 : AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Suggestions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final loc = _suggestions[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.grey200.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history,
                            color: AppColors.grey600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          loc.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          loc.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectLocation(loc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
