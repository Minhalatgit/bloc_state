import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    ),
  );
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction implements LoadAction {
  final PersonUrl url;

  const LoadPersonAction({required this.url}) : super();
}

class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        age = json['age'];

  @override
  String toString() {
    return "Name: $name Age: $age";
  }
}

enum PersonUrl {
  persons1,
  persons2,
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.persons1:
        return "http://127.0.0.1:5500/api/persons1.json";
      case PersonUrl.persons2:
        return "http://127.0.0.1:5500/api/persons2.json";
    }
  }
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetreivedFromCache;

  const FetchResult({
    required this.persons,
    required this.isRetreivedFromCache,
  });

  @override
  String toString() =>
      "Fetch result (isRetreivedFromCache: $isRetreivedFromCache, persons: $persons)";
}

class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonBloc() : super(null) {
    on<LoadPersonAction>(
      (event, emit) async {
        final url = event.url;

        if (_cache.containsKey(url)) {
          final cachedPerson = _cache[url]!;

          final result = FetchResult(
            persons: cachedPerson,
            isRetreivedFromCache: true,
          );

          emit(result);
        } else {
          final persons = await getPersons(url.urlString);

          _cache[url] = persons;

          final result = FetchResult(
            persons: persons,
            isRetreivedFromCache: false,
          );

          emit(result);
        }
      },
    );
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  context.read<PersonBloc>().add(
                        const LoadPersonAction(
                          url: PersonUrl.persons1,
                        ),
                      );
                },
                child: Text("Load json #1"),
              ),
              TextButton(
                onPressed: () {
                  context.read<PersonBloc>().add(
                        const LoadPersonAction(
                          url: PersonUrl.persons2,
                        ),
                      );
                },
                child: Text("Load json #2"),
              ),
            ],
          ),
          BlocBuilder<PersonBloc, FetchResult?>(
            buildWhen: (previous, current) {
              return previous?.persons != current?.persons;
            },
            builder: (context, fetchResult) {
              fetchResult?.log();
              final persons = fetchResult?.persons;
              if (persons == null) {
                return const SizedBox();
              }

              return Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    final person = persons[index];

                    return ListTile(
                      title: Text(person?.name ?? ""),
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
