import 'dart:async';
import 'dart:developer';

import 'package:acoustics_repository/acoustics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graph_test/bootstrap.dart';
// import 'package:grpc/grpc.dart';
import 'package:time_series_generator_api/generated/time_series_generator.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:time_series_generator_api/time_series_generator_api.dart';

import 'app/app.dart';

void main() {
  grpc.ClientChannel? channel;
  TimeSeriesGeneratorClient? client;
  TimeSeriesGeneratorApi? generatorApi;
  AcousticsRepository? acousticsRepository;

  channel = grpc.ClientChannel('192.168.0.100',
      port: 8080,
      options: const grpc.ChannelOptions(
          credentials: grpc.ChannelCredentials.insecure()));

  client = TimeSeriesGeneratorClient(channel);
  generatorApi = TimeSeriesGeneratorApi(client: client);
  acousticsRepository = AcousticsRepository(generatorApi: generatorApi);

  Bloc.observer = const AppBlocObserver();

  runApp(
    App(
      acousticsRepository: acousticsRepository,
    ),
  );
}


//here is my second change