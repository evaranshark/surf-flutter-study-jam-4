import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class MagicBallBlocState {}

final class MagicBallHasDataState extends MagicBallBlocState {
  final String data;

  MagicBallHasDataState(this.data);
}

final class MagicBallLoadingState extends MagicBallBlocState {}

final class MagicBallHasErrorState extends MagicBallBlocState {
  final String error;

  MagicBallHasErrorState(this.error);
}

final class MagicBallEmptyState extends MagicBallBlocState {}

sealed class MagicBallEvent {}

final class Load extends MagicBallEvent {}

final class Clear extends MagicBallEvent {}

class MagicBallBloc extends Bloc<MagicBallEvent, MagicBallBlocState> {
  static final dio = Dio();
  MagicBallBloc() : super(MagicBallEmptyState()) {
    on<Clear>(
      (event, emit) {
        emit(MagicBallEmptyState());
      },
    );
    on<Load>(
      (event, emit) async {
        emit(MagicBallLoadingState());
        try {
          var response = await dio.get("https://eightballapi.com/api/",
              options: Options(
                responseType: ResponseType.json,
              ));
          String value = response.data['reading'];
          emit(MagicBallHasDataState(value));
        } catch (e) {
          emit(MagicBallHasErrorState("There is no answer from spirits."));
        }
      },
    );
  }
}
