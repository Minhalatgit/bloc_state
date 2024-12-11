import 'package:bloc_state/bloc/person.dart';
import 'package:flutter/foundation.dart' show immutable;

const personn1 = 'http://127.0.0.1:5500/api/persons1.json';
const personn2 = 'http://127.0.0.1:5500/api/persons2.json';

typedef PersonLoader = Future<Iterable<Person>> Function(String url);

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction implements LoadAction {
  final String url;
  final PersonLoader loader;

  const LoadPersonAction({required this.url, required this.loader}) : super();
}
