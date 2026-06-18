import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/features/search/presentation/bloc/places_search_cubit.dart';
import 'package:gold_taxi/features/search/data/models/place_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchBottomSheet extends StatefulWidget {
  final LatLng? currentLocation;

  const SearchBottomSheet({super.key, this.currentLocation});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();

  static Future<PlaceModel?> show(
    BuildContext context, {
    LatLng? currentLocation,
  }) {
    return showModalBottomSheet<PlaceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PlacesSearchCubit>(),
        child: SearchBottomSheet(currentLocation: currentLocation),
      ),
    );
  }
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      context.read<PlacesSearchCubit>().setCurrentLocation(
        widget.currentLocation!,
      );
    }
    context.read<PlacesSearchCubit>().loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onPlaceSelected(PlaceModel place) async {
    final fullPlace = await context.read<PlacesSearchCubit>().selectPlace(
      place,
    );
    if (mounted && fullPlace != null) {
      Navigator.of(context).pop(fullPlace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Kam to bude?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PlacesSearchCubit>().onQueryChanged('');
                  },
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<PlacesSearchCubit>().onQueryChanged(value);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Results / Content
          Expanded(
            child: BlocBuilder<PlacesSearchCubit, PlacesSearchState>(
              builder: (context, state) {
                if (state is PlacesSearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PlacesSearchError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is PlacesSearchLoaded) {
                  return _buildContent(state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PlacesSearchLoaded state) {
    if (state.isSearching) {
      if (state.results.isEmpty) {
        return const Center(child: Text('Nenašli sa žiadne výsledky'));
      }
      return ListView.builder(
        itemCount: state.results.length,
        itemBuilder: (context, index) =>
            _buildResultTile(state.results[index], true),
      );
    } else {
      // Show Pinned & Recent
      return ListView(
        children: [
          // Pinned Spots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickChip(
                    'home',
                    state.homePlace,
                    Icons.home,
                    'Domov',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickChip(
                    'work',
                    state.workPlace,
                    Icons.work,
                    'Práca',
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (state.results.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Nedávne miesta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ...state.results.map((place) => _buildResultTile(place, false)),
        ],
      );
    }
  }

  Widget _buildResultTile(PlaceModel place, bool highlight) {
    return ListTile(
      leading: const Icon(Icons.location_on, color: Colors.grey),
      title: highlight
          ? _highlightText(place.primaryText, _searchController.text)
          : Text(place.primaryText),
      subtitle: Text(place.secondaryText),
      trailing: place.distanceInMeters != null
          ? Text(
              '${(place.distanceInMeters! / 1000).toStringAsFixed(1)} km',
              style: const TextStyle(color: Colors.grey),
            )
          : null,
      onTap: () => _onPlaceSelected(place),
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) return Text(text);

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  Widget _buildQuickChip(
    String type,
    PlaceModel? place,
    IconData icon,
    String label,
  ) {
    return InkWell(
      onTap: () {
        if (place != null) {
          _onPlaceSelected(place);
        } else {
          // Trigger search and save
          _searchController.text = label;
          // Context: we could ask user to search and save this
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vyhľadaj a podrž pre uloženie ako $label')),
          );
        }
      },
      onLongPress: () {
        // Edit mode (normally would show a dialog or special save state)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editácia $label (Zatiaľ len demo)')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    place?.primaryText ?? 'Pridať',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
