// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:time_series_generator_api/time_series_generator_api.dart';
import 'package:acoustics_repository/acoustics_repository.dart';

import 'app/app.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  // @override
  // void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
  //   super.onChange(bloc, change);
  //   log('onChange: ${bloc.runtimeType},\nCurrent state: ${change.currentState}\nNext state: ${change.nextState}');
  // }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onCreate(BlocBase bloc) {
    log('onCreate(${bloc.state}, ${bloc.runtimeType})');
    super.onCreate(bloc);
  }

  @override
  void onClose(BlocBase bloc) {
    log('onClose(${bloc.state}, ${bloc.runtimeType})');
    super.onClose(bloc);
  }
}

void bootstrap({
  required TimeSeriesGeneratorApi generatorApi,
}) {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  // Bloc.observer = const AppBlocObserver();

  final acousticsRepository = AcousticsRepository(generatorApi: generatorApi);

  runZonedGuarded(
    () => runApp(
      App(
        acousticsRepository: acousticsRepository,
      ),
    ),
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
  );
}
