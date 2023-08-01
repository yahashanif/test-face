import 'package:flutter_bloc/flutter_bloc.dart';

class SaveCubit extends Cubit<List<dynamic>> {
  SaveCubit() : super([]);

  void setNewValue(List<dynamic> faces) async {
    print("Wahahaha");
    print(faces);
    emit(faces);
  }
}
