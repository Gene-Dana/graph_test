part of 'heart_rate_bloc.dart';

abstract class HeartRateEvent extends Equatable {
  const HeartRateEvent();

  @override
  List<Object> get props => [];
}
class StartSubscribe extends HeartRateEvent {}

class StartPublish extends HeartRateEvent {}

class StartHeartRate extends HeartRateEvent {}





class StartSTPSD extends HeartRateEvent {}

class HeartRatePoint extends HeartRateEvent {
  final List<int> point;

  const HeartRatePoint(this.point);

  @override
  List<Object> get props => [point];
}
