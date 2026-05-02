# skills/flutter/riverpod_provider.md
# Skill: Tạo Riverpod provider chuẩn cho AquaTrack

## Dùng khi
Cần tạo provider mới cho một feature.

## Template — AsyncNotifier (fetch data)
```dart
// features/<feature>/providers/<name>_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part '<name>_provider.g.dart';

@riverpod
class <Name>Notifier extends _$<Name>Notifier {
  @override
  AsyncValue<<Model>> build() => const AsyncValue.loading();

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).<method>(),
    );
  }

  Future<void> refresh() => fetch();
}
```

## Template — StateNotifier (local state)
```dart
@riverpod
class <Name>Notifier extends _$<Name>Notifier {
  @override
  <State> build() => <initialState>;

  void update(<params>) {
    state = state.copyWith(<changes>);
  }
}
```

## Dùng trong widget
```dart
final state = ref.watch(<name>NotifierProvider);
return state.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Lỗi: $e'),
  data: (data) => <Widget>,
);
```
