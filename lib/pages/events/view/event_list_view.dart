import 'package:app_flutter/pages/events/viewmodel/event_list_view_model.dart';
import 'package:app_flutter/widgets/list_events/event_list.dart';
import 'package:app_flutter/widgets/list_events/event_map.dart';
import 'package:app_flutter/widgets/list_events/filters_widgets.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';

class EventsMapListView extends StatelessWidget {
  const EventsMapListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventsViewModel(),
      child: const EventsMapListContent(),
    );
  }
}

class EventsMapListContent extends StatelessWidget {
  const EventsMapListContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EventsViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Switch para alternar entre mapa y lista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: viewModel.isMapView ? Colors.grey : Colors.black,
                ),
                Switch(
                  value: viewModel.isMapView,
                  onChanged: (_) => viewModel.toggleView(),
                  activeColor: const Color(0xFF6389E2),
                ),
                Icon(
                  Icons.map,
                  color: viewModel.isMapView ? Colors.black : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          SearchBar(viewModel: viewModel),
          
          // Chips de filtros activos
          if (viewModel.filters.hasActiveFilters)
            ActiveFiltersChips(viewModel: viewModel),
          
          // Contenido: Mapa o Lista
          Expanded(
            child: viewModel.isMapView
                ? EventsMapView(events: viewModel.events)
                : EventsListView(events: viewModel.events, viewModel: viewModel),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFiltersBottomSheet(context, viewModel),
        backgroundColor: const Color(0xFF6389E2),
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context, EventsViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FiltersBottomSheet(viewModel: viewModel),
    );
  }
}