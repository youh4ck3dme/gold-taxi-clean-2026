import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/services_repository.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServicesRepository _servicesRepository;

  ServicesBloc(this._servicesRepository) : super(ServicesInitial()) {
    on<FetchServices>(_onFetchServices);
  }

  Future<void> _onFetchServices(FetchServices event, Emitter<ServicesState> emit) async {
    if (state is! ServicesLoaded || event.isRefresh || event.search != null) {
      emit(ServicesLoading());
    }

    try {
      final services = await _servicesRepository.getServices(
        page: 1,
        search: event.search,
      );
      emit(ServicesLoaded(services: services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }
}
