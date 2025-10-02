import 'package:app_flutter/pages/events/viewmodel/event_list_view_model.dart';
import 'package:app_flutter/pages/notification.dart';
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
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Events",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
              color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6389E2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
          
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                FloatingActionButton(
                  onPressed: () => _showFiltersBottomSheet(context, viewModel),
                  child: Row(
                    children: const [
                      Icon(Icons.filter_alt_outlined),
                      Text("Filtros"),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // opcional, espacio entre botón y el resto
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.list,
                        color: viewModel.isMapView ? Colors.grey : Colors.black,
                      ),
                      Switch(
                        value: viewModel.isMapView,
                        onChanged: (_) => viewModel.toggleView(),
                        activeThumbColor: const Color(0xFF6389E2),
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
          ),
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