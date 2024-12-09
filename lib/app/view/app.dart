import 'package:acoustics_repository/acoustics_repository.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graph_test/heart_rate/heart_rate.dart';
import 'package:graph_test/tone_overview/view/tone_overview.dart';

class App extends StatelessWidget {
  const App({
    Key? key,
    required AcousticsRepository acousticsRepository,
  })  : _acousticsRepository = acousticsRepository,
        super(key: key);

  final AcousticsRepository _acousticsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _acousticsRepository),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        home: Scaffold(
      body: HeartRate(),
    ));
  }
}
//step one of step two