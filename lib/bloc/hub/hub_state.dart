import '../../models/hub_model.dart';

abstract class HubState {}

class HubInitial extends HubState {}

class HubLoading extends HubState {}

class HubsLoaded extends HubState {
  final List<Hub> hubs;
  HubsLoaded({
    required this.hubs,
  });
}

class HubError extends HubState {
  final String message;
  HubError(this.message);
}