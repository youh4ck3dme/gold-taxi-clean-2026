import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../location/map_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthBloc, String>((bloc) {
      final state = bloc.state;
      return state is Authenticated ? state.userProfile.fullName : 'Vodič';
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Konzola vodiča: $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásiť sa',
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
      body: const MapScreen(),
    );
  }
}
