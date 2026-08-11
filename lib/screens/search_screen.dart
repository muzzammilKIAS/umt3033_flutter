import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'unit_screen.dart';

class SearchScreen extends StatefulWidget {
  final void Function(int unitId) onOpenUnit;
  const SearchScreen({super.key, required this.onOpenUnit});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  static const _typeLabels = {
    'unit': ('وَحْدَة', 'Unit'),
    'vocab': ('مُفْرَدَة', 'Kosa kata'),
    'dialog': ('حِوَار', 'Dialog'),
    'reading': ('نَصّ', 'Bacaan'),
    'glossary': ('مُصْطَلَح', 'Glosari'),
  };

  static const _typeIcons = {
    'unit': Icons.menu_book_outlined,
    'vocab': Icons.style_outlined,
    'dialog': Icons.forum_outlined,
    'reading': Icons.article_outlined,
    'glossary': Icons.bookmark_border,
  };

  void _search(String q) {
    final data = context.read<DataService>();
    setState(() => _results = data.search(q));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Carian')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: false,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari unit, kosa kata, dialog, glosari...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _results = []);
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _controller.text.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Taip untuk mencari kandungan merentasi semua 14 unit, glosari dan teks bacaan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Text(
                      'Tiada hasil dijumpai',
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      final type = r['type'] as String;
                      final labels = _typeLabels[type] ?? ('', type);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tokens.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: Icon(
                              _typeIcons[type] ?? Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              r['titleAr'] as String,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 20,
                              ),
                            ),
                            subtitle: Text(
                              '${labels.$2} • ${r['subtitle']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              'U${r['unitId']}',
                              style: TextStyle(
                                color: tokens.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UnitScreen(unitId: r['unitId'] as int),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
