// lib/bloc/app_bloc.dart
import 'package:cocoa_supply/bloc/batch/batch.dart';
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/bloc/farm/farm_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/hub/hub_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_bloc.dart';
import 'package:cocoa_supply/bloc/plot/plot_bloc.dart';
import 'package:cocoa_supply/bloc/processing_station/processing_station.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/transaction/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
/// Collection of all Bloc Providers used throughout the application.
class AppBloc {
  static List<BlocProvider> get providers => [
    BlocProvider<LoginBloc>(create: (BuildContext context) => LoginBloc(),),
    BlocProvider<FarmBloc>(create: (BuildContext context) => FarmBloc(),),
    BlocProvider<PlotBloc>(create: (BuildContext context) => PlotBloc(),),
    BlocProvider<ProcessingStationBloc>(create: (BuildContext context) => ProcessingStationBloc(),),
    
    BlocProvider<HubBloc>(create: (BuildContext context) => HubBloc(),),
    BlocProvider<BatchBloc>(create: (BuildContext context) => BatchBloc(),),
    BlocProvider<TransactionBloc>(create: (BuildContext context) => TransactionBloc(),),
    BlocProvider<TaskBloc>(create: (BuildContext context) => TaskBloc(),),
    BlocProvider<DynamicBloc>(
      create: (context) => DynamicBloc(
        taskBloc: context.read<TaskBloc>(),
      ),
    ),
    BlocProvider<HomeBloc>(
      create: (BuildContext context) => HomeBloc(
        taskBloc: context.read<TaskBloc>(),
      ),
    ),
  ];
}
