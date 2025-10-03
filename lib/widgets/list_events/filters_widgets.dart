import 'package:app_flutter/pages/events/viewmodel/event_list_view_model.dart';
import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final EventsViewModel viewModel;

  const SearchBar({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // color y opacidad de la sombra
            blurRadius: 8, // difuminado
            offset: const Offset(0, 4), // posición de la sombra
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE3944F)),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.viewModel.updateSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none, // quitamos el borde para usar solo el del Container
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_controller.text == value) {
              widget.viewModel.updateSearchQuery(value);
            }
          });
        },
      ),
    );
  }
}

class ActiveFiltersChips extends StatelessWidget {
  final EventsViewModel viewModel;

  const ActiveFiltersChips({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (viewModel.filters.eventTypes?.isNotEmpty ?? false)
              ...viewModel.filters.eventTypes!.map((type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(type),
                      onDeleted: () {
                        final types = List<String>.from(viewModel.filters.eventTypes!);
                        types.remove(type);
                        viewModel.updateEventTypes(types);
                      },
                      backgroundColor: const Color(0xFF6389E2).withValues(alpha: 0.1),
                    ),
                  )),
            if (viewModel.filters.category != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(viewModel.filters.category!),
                  onDeleted: () => viewModel.updateCategory(null),
                  backgroundColor: const Color(0xFFED6275).withValues(alpha: 0.1),
                ),
              ),
            if (viewModel.filters.city != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(viewModel.filters.city!),
                  onDeleted: () => viewModel.updateCity(null),
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                ),
              ),
            if (viewModel.filters.minRating != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Rating ≥ ${viewModel.filters.minRating}'),
                  onDeleted: () => viewModel.updateMinRating(null),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                ),
              ),
            TextButton.icon(
              onPressed: viewModel.clearFilters,
              icon: const Icon(Icons.clear_all, color: Colors.black,),
              label: const Text('Clear all', style: TextStyle(color: Color.fromARGB(255, 49, 49, 49)),),
            ),
          ],
        ),
      ),
    );
  }
}

class FiltersBottomSheet extends StatefulWidget {
  final EventsViewModel viewModel;

  const FiltersBottomSheet({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  late List<String> _selectedTypes;
  String? _selectedCategory;
  String? _selectedCity;
  double? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedTypes = widget.viewModel.filters.eventTypes ?? [];
    _selectedCategory = widget.viewModel.filters.category;
    _selectedCity = widget.viewModel.filters.city;
    _selectedRating = widget.viewModel.filters.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTypes = [];
                        _selectedCategory = null;
                        _selectedCity = null;
                        _selectedRating = null;
                      });
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Event Types
                    const Text(
                      'Event Types',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: ['Conference', 'Seminar', 'Workshop'].map((type) {
                        return FilterChip(
                          label: Text(type),
                          selected: _selectedTypes.contains(type),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select category',
                      ),
                      items: widget.viewModel.availableCategories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 20),
                    
                    // City
                    const Text(
                      'City',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select city',
                      ),
                      items: widget.viewModel.availableCities
                          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCity = value),
                    ),
                    const SizedBox(height: 20),
                    
                    // Minimum Rating
                    const Text(
                      'Minimum Rating',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: _selectedRating ?? 0,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _selectedRating?.toStringAsFixed(1) ?? '0.0',
                      onChanged: (value) => setState(() => _selectedRating = value > 0 ? value : null),
                    ),
                    if (_selectedRating != null)
                      Text(
                        'Rating ≥ ${_selectedRating!.toStringAsFixed(1)}',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.viewModel.updateEventTypes(_selectedTypes);
                    widget.viewModel.updateCategory(_selectedCategory);
                    widget.viewModel.updateCity(_selectedCity);
                    widget.viewModel.updateMinRating(_selectedRating);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6389E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}