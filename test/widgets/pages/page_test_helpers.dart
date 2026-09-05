// Shared helpers for test/widgets/pages/*_test.dart.
//
// Pages read their blocs from ambient BlocProviders (context.read<XBloc>()).
// AppBloc.providers (lib/bloc/bloc.dart) wires all of them with real,
// un-injected services — fine for the real app, but in a widget test that
// means every BlocBuilder waiting on a fetch hangs forever, because a real
// http.Client()'s request never resolves within flutter_test's fake-async
// pump() cycles (see the root_scaffold_test.dart comment for why). So page
// tests build their own provider list here, with every bloc's service
// backed by an injected MockClient instead.

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
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:cocoa_supply/services/farm_service.dart';
import 'package:cocoa_supply/services/hub_service.dart';
import 'package:cocoa_supply/services/plot_service.dart';
import 'package:cocoa_supply/services/processing_station_service.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:cocoa_supply/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../services/test_helpers.dart';

/// A MockClient that answers every request with an empty JSON array/object,
/// good enough for pages that only need their blocs to settle out of the
/// loading state without asserting on the fetched data itself.
http.Client emptyMockClient() => MockClient((request) async => jsonResponse([], 200));

/// The full bloc provider list a page might read from, all backed by
/// [client] (or a default empty-response MockClient).
List<BlocProvider> testBlocProviders({http.Client? client}) {
  final c = client ?? emptyMockClient();
  final taskBloc = TaskBloc(taskService: TaskService(client: c));
  return [
    BlocProvider<FarmBloc>(create: (_) => FarmBloc(farmService: FarmService(client: c))),
    BlocProvider<PlotBloc>(create: (_) => PlotBloc(plotService: PlotService(client: c))),
    BlocProvider<ProcessingStationBloc>(
      create: (_) => ProcessingStationBloc(stationService: ProcessingStationService(client: c)),
    ),
    BlocProvider<HubBloc>(create: (_) => HubBloc(hubService: HubService(client: c))),
    BlocProvider<BatchBloc>(create: (_) => BatchBloc()),
    BlocProvider<TransactionBloc>(create: (_) => TransactionBloc()),
    BlocProvider<LoginBloc>(create: (_) => LoginBloc(client: c)),
    BlocProvider<TaskBloc>.value(value: taskBloc),
    BlocProvider<DynamicBloc>(
      create: (ctx) => DynamicBloc(taskBloc: ctx.read<TaskBloc>(), apiOverride: DynamicApiService(client: c)),
    ),
    BlocProvider<HomeBloc>(create: (ctx) => HomeBloc(taskBloc: ctx.read<TaskBloc>())),
  ];
}

/// Wraps [page] in a MaterialApp + all blocs a page might read from. The
/// providers sit *above* MaterialApp so pages reached via
/// Navigator.pushNamed (using the real AppRoute.onGenerateRoute, wired in
/// by default) can still `context.read<XBloc>()` — a route pushed from
/// inside `home` is a sibling in the widget tree, not a descendant of a
/// provider placed inside `home`.
Widget wrapPage(Widget page, {http.Client? client}) {
  return MultiBlocProvider(
    providers: testBlocProviders(client: client),
    child: MaterialApp(home: page, onGenerateRoute: AppRoute.onGenerateRoute),
  );
}
