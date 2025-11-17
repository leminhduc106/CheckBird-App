import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

class QuotesAPI extends StatefulWidget {
  static const routeName = '/home-screen';

  const QuotesAPI({super.key});

  @override
  State<QuotesAPI> createState() => _QuotesAPISate();
}

class _QuotesAPISate extends State<QuotesAPI> {
  final String _url = "https://api.quotable.io/random";
  late StreamController _streamController;
  late Stream _stream;
  late Response response;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController();
    _stream = _streamController.stream;
    getQuotes();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  getQuotes() async {
    response = await get(Uri.parse(_url));
    Map<String, dynamic> quotes = json.decode(response.body);

    while (int.parse(quotes['length'].toString()) > 80) {
      response = await get(Uri.parse(_url));
      quotes = json.decode(response.body);
    }
    _streamController.add(quotes);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.primary,
              ],
            ),
          ),
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: size.height * 0.15,
            maxHeight: size.height * 0.22,
          ),
          child: StreamBuilder(
            stream: _stream,
            builder: (BuildContext ctx, AsyncSnapshot snapshot) {
              String quote = snapshot.data != null 
                  ? snapshot.data['content'].toString() 
                  : "Waiting for inspiration...";
              
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 28,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      quote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        color: Theme.of(context).colorScheme.onPrimary,
                        height: 1.4,
                      ),
                    ),
                    if (snapshot.data != null && snapshot.data['author'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        "— ${snapshot.data['author']}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
