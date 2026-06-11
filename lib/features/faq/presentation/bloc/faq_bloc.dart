import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/faq_repository.dart';
import 'faq_event.dart';
import 'faq_state.dart';

class FaqBloc extends Bloc<FaqEvent, FaqState> {
  final FaqRepository _faqRepository;

  FaqBloc(this._faqRepository) : super(FaqInitial()) {
    on<FetchFaqs>(_onFetchFaqs);
  }

  Future<void> _onFetchFaqs(FetchFaqs event, Emitter<FaqState> emit) async {
    if (state is! FaqLoaded || event.isRefresh) {
      emit(FaqLoading());
    }

    try {
      final faqs = await _faqRepository.getFaqs();
      emit(FaqLoaded(faqs: faqs));
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }
}
