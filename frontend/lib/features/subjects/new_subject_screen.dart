import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../shared/widgets/common.dart';

const _palette = <Color>[
  Gw.calculo,
  Gw.anatomia,
  Gw.algoritmos,
  Gw.psicologia,
  Gw.bioquimica,
  Gw.primary,
  Gw.accent,
  Gw.streak,
];

final _icons = kSubjectIconByName.values.toList();

/// Cadastro de uma nova disciplina (POST /subjects).
class NewSubjectScreen extends ConsumerStatefulWidget {
  const NewSubjectScreen({super.key});

  @override
  ConsumerState<NewSubjectScreen> createState() => _NewSubjectScreenState();
}

class _NewSubjectScreenState extends ConsumerState<NewSubjectScreen> {
  final _name = TextEditingController();
  final _professor = TextEditingController();
  Color _color = _palette.first;
  IconData _icon = _icons.first;
  DateTime? _examDate;
  bool _saving = false;
  String? _error;

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _professor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(subjectsRepositoryProvider).create(
            name: _name.text.trim(),
            colorHex: hexFromColor(_color),
            iconName: nameFromIcon(_icon),
            professor: _professor.text.trim(),
            examDate: _examDate,
          );
      ref.invalidate(subjectsListProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Gw.primary,
            surface: Gw.bgElevated,
            onSurface: Gw.textHi,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
                children: [
                  _preview(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Nome da disciplina'),
                  const SizedBox(height: Gw.s12),
                  _nameField(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Cor'),
                  const SizedBox(height: Gw.s12),
                  _colorPicker(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Ícone'),
                  const SizedBox(height: Gw.s12),
                  _iconPicker(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Professor (opcional)'),
                  const SizedBox(height: Gw.s12),
                  _professorField(),
                  const SizedBox(height: Gw.s24),
                  const Overline('Data da prova (opcional)'),
                  const SizedBox(height: Gw.s12),
                  _dateField(),
                  if (_error != null) ...[
                    const SizedBox(height: Gw.s16),
                    Text(_error!,
                        style: const TextStyle(color: Gw.error, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gw.s18, Gw.s8, Gw.s18, Gw.s16),
              child: GlowButton(
                label: _saving ? 'Criando...' : 'Criar disciplina',
                icon: Icons.check_rounded,
                onTap: (_valid && !_saving) ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gw.s8, Gw.s8, Gw.s18, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Gw.textHi),
          ),
          const Expanded(
            child: Text('Nova disciplina',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Gw.textHi)),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _preview() {
    final name = _name.text.trim();
    return GwCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_color.withValues(alpha: 0.22), _color.withValues(alpha: 0.05)],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _color.withValues(alpha: 0.5)),
            ),
            child: Icon(_icon, color: _color, size: 26),
          ),
          const SizedBox(width: Gw.s16),
          Expanded(
            child: Text(
              name.isEmpty ? 'Sua disciplina' : name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: name.isEmpty ? Gw.textDim : Gw.textHi,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField() => TextField(
        controller: _name,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Gw.textHi, fontSize: 15),
        cursorColor: _color,
        textCapitalization: TextCapitalization.words,
        decoration: _dec('Ex.: Cálculo I', Icons.menu_book_rounded),
      );

  Widget _professorField() => TextField(
        controller: _professor,
        style: const TextStyle(color: Gw.textHi, fontSize: 15),
        cursorColor: _color,
        textCapitalization: TextCapitalization.words,
        decoration: _dec('Ex.: Dra. Ana Souza', Icons.person_rounded),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Gw.textDim),
        prefixIcon: Icon(icon, color: _color, size: 20),
        filled: true,
        fillColor: Gw.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gw.rCard),
          borderSide: const BorderSide(color: Gw.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gw.rCard),
          borderSide: BorderSide(color: _color, width: 1.5),
        ),
      );

  Widget _colorPicker() => Wrap(
        spacing: Gw.s12,
        runSpacing: Gw.s12,
        children: _palette.map((c) {
          final sel = c == _color;
          return GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? Gw.textHi : Colors.transparent, width: 2.5),
                boxShadow: sel ? Gw.softGlow(c, blur: 12, alpha: 0.6) : null,
              ),
              child: sel
                  ? const Icon(Icons.check_rounded, color: Gw.bg, size: 20)
                  : null,
            ),
          );
        }).toList(),
      );

  Widget _iconPicker() => Wrap(
        spacing: Gw.s12,
        runSpacing: Gw.s12,
        children: _icons.map((ic) {
          final sel = ic == _icon;
          return GestureDetector(
            onTap: () => setState(() => _icon = ic),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sel ? _color.withValues(alpha: 0.18) : Gw.card,
                borderRadius: BorderRadius.circular(Gw.rChip),
                border: Border.all(
                    color: sel ? _color : Gw.border, width: sel ? 1.5 : 1),
              ),
              child: Icon(ic, color: sel ? _color : Gw.textLo, size: 22),
            ),
          );
        }).toList(),
      );

  Widget _dateField() {
    final label = _examDate == null
        ? 'Sem data definida'
        : '${_examDate!.day.toString().padLeft(2, '0')}/'
            '${_examDate!.month.toString().padLeft(2, '0')}/${_examDate!.year}';
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gw.s16, vertical: 16),
        decoration: BoxDecoration(
          color: Gw.card,
          borderRadius: BorderRadius.circular(Gw.rCard),
          border: Border.all(color: Gw.border),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, color: _color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      color: _examDate == null ? Gw.textDim : Gw.textHi)),
            ),
            if (_examDate != null)
              GestureDetector(
                onTap: () => setState(() => _examDate = null),
                child:
                    const Icon(Icons.close_rounded, color: Gw.textLo, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
