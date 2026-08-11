import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query = '';

  static String _bare(String s) => s.replaceAll(RegExp(r'[ً-ٰٟـ]'), '');

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final tokens = context.tokens;
    final q = _bare(_query.trim().toLowerCase());
    final entries = data.glossary.where((g) {
      if (q.isEmpty) return true;
      return _bare(g.termAr.toLowerCase()).contains(q) ||
          g.term.toLowerCase().contains(q) ||
          g.transliteration.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.termAr.compareTo(b.termAr));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مُعْجَمُ الْمُصْطَلَحَاتِ',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 20),
            ),
            Text(
              'Glosari (${data.glossary.length} istilah)',
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Cari istilah...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Tiada istilah dijumpai',
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final g = entries[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.term,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  if (g.transliteration.isNotEmpty)
                                    Text(
                                      g.transliteration,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: tokens.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  Text(
                                    'Unit ${g.unitId}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              g.termAr,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
