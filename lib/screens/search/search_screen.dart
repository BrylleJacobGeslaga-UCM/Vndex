import 'package:flutter/material.dart';

/// VNDB search. Placeholder until Step 4 wires up the API.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a VN')),
      body: const Center(child: Text('Search coming in Step 4')),
    );
  }
}
