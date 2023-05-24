import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:acoustics_repository/acoustics_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fftea/fftea.dart';
import 'package:time_series_generator_api/generated/time_series_generator.dart';

part 'heart_rate_event.dart';
part 'heart_rate_state.dart';

class HeartRateBloc extends Bloc<HeartRateEvent, HeartRateState> {
  HeartRateBloc({
    required AcousticsRepository acousticsRepository,
  })  : _acousticsRepository = acousticsRepository,
        super(const HeartRateState()) {
    on<StartHeartRate>(_onStartHeartRate);
    on<StartSubscribe>(_onStartSubscribe);

    on<StartPublish>(_onStartPublish);
    on<StartSTPSD>(_onStartSTPSD);
  }
  final windowSize = 256;
  // final overlap = 128;
  final samplingRate = 4410.0;
  final buffer = Queue<Point>();

  final AcousticsRepository _acousticsRepository;

  Future<void> _onStartPublish(
      StartPublish event, Emitter<HeartRateState> emit) async {
    final publishRequest = TimeSeriesConfig()
      ..sampleRate = 4410
      ..tones.addAll([
        ToneConfig(initialPhase: 0, amplitude: 10, frequency: 1000),
        ToneConfig(initialPhase: 0, amplitude: 5, frequency: 80),
        ToneConfig(initialPhase: 0, amplitude: 1, frequency: 10),
      ]);

    await _acousticsRepository.setTones(publishRequest);

    await emit.forEach<BatchedData>(_acousticsRepository.getCombinedTone(),
        onData: (batch) {
      for (int i = 0; i < batch.yValues.length;) {
        final updatedList = state.chartData.map((e) => e).toList();
        if (updatedList.length > 100) {
          updatedList.removeAt(0);
        }

        final point = Point(batch.xValues[i], batch.yValues[i]);

        final newData = FlSpot(point.x, point.y);

        buffer.add(point);

        if (buffer.length >= windowSize) {
          final stpsdData = <FlSpot>[];

          // Perform FFT on the buffer
          final spectrum = performFFT(buffer);

          // Compute power spectrum
          final powerSpectrum = computePowerSpectrum(spectrum);

          // Convert power spectrum to dB scale
          final powerSpectrumdB = convertToDecibel(powerSpectrum);

          // Generate frequency axis
          final frequencyAxis = generateFrequencyAxis(windowSize, samplingRate);

          // Create FlSpot objects for plotting
          for (int i = 0; i < frequencyAxis.length; i++) {
            stpsdData.add(FlSpot(frequencyAxis[i], powerSpectrumdB[i]));
          }

          buffer.clear(); // Clear the buffer after computing the FFT

          // Update the state or perform any further processing
          return state.copyWith(stpsdData: stpsdData);
        }

        return state.copyWith(chartData: updatedList..add(newData));
      }

      return state;
    });
  }

  Future<void> _onStartSubscribe(
      StartSubscribe event, Emitter<HeartRateState> emit) async {
    await emit.forEach<BatchedData>(_acousticsRepository.getCombinedTone(),
        onData: (batch) {
      print(batch.xValues.first);
      // final newData = FlSpot(point.x.toDouble(), point.y.toDouble());
      // final updatedList = state.chartData.map((e) => e).toList();

      // if (updatedList.length > 50) {
      //   updatedList.removeAt(0);
      // }

      return state;
    });
  }

  Future<void> _onStartHeartRate(
      StartHeartRate event, Emitter<HeartRateState> emit) async {
    await emit.forEach<Point>(_acousticsRepository.getHeartRateStream(),
        onData: (point) {
      final newData = FlSpot(point.x.toDouble(), point.y.toDouble());
      final updatedList = state.chartData.map((e) => e).toList();

      if (updatedList.length > 50) {
        updatedList.removeAt(0);
      }

      return state.copyWith(chartData: updatedList..add(newData));
    }).whenComplete(() => add(StartHeartRate()));
  }

  Future<void> _onStartSTPSD(
      StartSTPSD event, Emitter<HeartRateState> emit) async {
    print('starting');
    final buffer = Queue<Point>();

    await emit.forEach<Point>(_acousticsRepository.getHeartRateStream(),
        onData: (point) {
      final newData = FlSpot(point.x.toDouble(), point.y.toDouble());
      final updatedList = state.chartData.map((e) => e).toList();

      if (updatedList.length > 50) {
        updatedList.removeAt(0);
      }

      emit(state.copyWith(chartData: updatedList..add(newData)));
      buffer.add(point);

      if (buffer.length >= windowSize) {
        final stpsdData = <FlSpot>[];

        // Perform FFT on the buffer
        final spectrum = performFFT(buffer);

        // Compute power spectrum
        final powerSpectrum = computePowerSpectrum(spectrum);

        // Convert power spectrum to dB scale
        final powerSpectrumdB = convertToDecibel(powerSpectrum);

        // Generate frequency axis
        final frequencyAxis = generateFrequencyAxis(windowSize, samplingRate);

        // Create FlSpot objects for plotting
        for (int i = 0; i < frequencyAxis.length; i++) {
          stpsdData.add(FlSpot(frequencyAxis[i], powerSpectrumdB[i]));
        }

        buffer.clear(); // Clear the buffer after computing the FFT

        // Update the state or perform any further processing
        return state.copyWith(stpsdData: stpsdData);
      }

      return state;
    });
  }

  List<double> computePowerSpectrum(Float64x2List spectrum) {
    List<double> powerSpectrum = List<double>.filled(spectrum.length, 0.0);

    for (int i = 0; i < spectrum.length; i++) {
      final fftValue = spectrum[i];
      final real = fftValue.x;
      final imag = fftValue.y;
      final power = real * real + imag * imag;
      powerSpectrum[i] = power;
    }

    return powerSpectrum;
  }

  // Function to perform FFT on the heart rate signal
  Float64x2List performFFT(Queue<Point> buffer) {
    // Convert the buffer to a List<double> containing the real portions
    List<double> realParts = buffer.map((point) => point.y.toDouble()).toList();

    // Generate the Hamming window
    List<double> hammingWindow = generateHammingWindow(realParts.length);

    // Apply the Hamming window to the data
    applyWindow(realParts, hammingWindow);

    // Create a new FFT object
    final fft = FFT(realParts.length);

    // Perform the FFT on the padded signal
    final spectrum = fft.realFft(realParts);

    return spectrum;
  }

  List<double> generateHammingWindow(int windowSize) {
    final window = List<double>.filled(windowSize, 0.0);

    for (int i = 0; i < windowSize; i++) {
      window[i] = 0.54 - 0.46 * cos(2 * pi * i / (windowSize - 1));
    }

    return window;
  }

  void applyWindow(List<double> data, List<double> window) {
    // Apply a windowing function (e.g., Hamming window) to the data
    // You can use different windowing functions based on your requirements
    for (int i = 0; i < data.length; i++) {
      data[i] *= window[i];
    }
  }

  List<double> convertToDecibel(List<double> powerSpectrum) {
    List<double> powerSpectrumdB =
        List<double>.filled(powerSpectrum.length, 0.0);

    for (int i = 0; i < powerSpectrum.length; i++) {
      powerSpectrumdB[i] = 10 * log(powerSpectrum[i]) / log(10);
    }

    return powerSpectrumdB;
  }

  List<double> generateFrequencyAxis(int windowSize, double samplingRate) {
    final nyquistFrequency = samplingRate / 2;
    final deltaFrequency = nyquistFrequency / (windowSize / 2);

    List<double> frequencyAxis = List<double>.filled(windowSize ~/ 2, 0.0);

    for (int i = 0; i < frequencyAxis.length; i++) {
      frequencyAxis[i] = i * deltaFrequency;
    }

    return frequencyAxis;
  }
}
