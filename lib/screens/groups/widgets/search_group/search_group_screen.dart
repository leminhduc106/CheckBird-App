import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:check_bird/screens/groups/widgets/group_item.dart';
import 'package:flutter/material.dart';

class SearchGroupScreen extends StatefulWidget {
  const SearchGroupScreen({super.key});

  @override
  State<SearchGroupScreen> createState() => _SearchGroupScreenState();
}

class _SearchGroupScreenState extends State<SearchGroupScreen> {
  final _textFieldFocus = FocusNode();
  final _textFieldController = TextEditingController();
  String _searchQuery = "";
  final _groupController = GroupsController();
  bool _isSearching = false;
  final List<Group> _searchResults = [];

  void _search() async {
    if (_searchQuery.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
    });
    _searchResults.clear();
    _searchQuery = _searchQuery.toLowerCase();
    final results = await _groupController.searchGroups(query: _searchQuery);
    _searchResults.addAll(results);
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Groups"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              autofocus: true,
              focusNode: _textFieldFocus,
              controller: _textFieldController,
              decoration: InputDecoration(
                hintText: 'Search by group name...',
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.primary),
                suffixIcon: _textFieldController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textFieldController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                _search();
              },
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Searching..."),
                      ],
                    ),
                  )
                : _textFieldController.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 80,
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Search for groups',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Enter a group name to find groups you\'re interested in',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 80,
                                  color:
                                      theme.colorScheme.error.withOpacity(0.5),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No groups found',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Text(
                                    'Try a different search term or browse all groups',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _searchResults.length,
                            itemBuilder: (BuildContext context, int index) {
                              return GroupItem(
                                groupId: _searchResults[index].groupId,
                                size: size,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
