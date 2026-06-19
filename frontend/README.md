# GoWise Helper — Frontend (Flutter)

App de estudos gamificado (Material 3, **dark only**, Android/portrait).
Implementa as 7 telas do `design_handoff_gowise/` com os tokens do handoff.

## Stack
- Flutter + Material 3
- `go_router` (navegação) · `flutter_riverpod` (estado) · `google_fonts` (Inter)

## Telas
1. **Dashboard** (Opção A — bento gamificado): hero nível+ofensiva, revisão de hoje, bento 2×2, missões, disciplinas.
2. **Flashcard** (Opção B): pilha + flip 3D (toque vira) + swipe ←/→ + dica mnemônica.
3. **Detalhe da disciplina**: hero + abas Resumo/Flashcards/Quiz/Mapa.
4. **Quiz**: feedback imediato (verde/vermelho) + explicação + cronômetro.
5. **Simulado**: grid 10/20/50/100, cronômetro, chips de disciplinas, histórico.
6. **Estatísticas**: KPIs, gráfico semanal (sábado em destaque), domínio por disciplina.
7. **Quiz por tema** ⭐: setup (disciplina/tema/dificuldade) → quiz com tema travado (cadeado).

## Estrutura
```
lib/
  main.dart, app.dart
  core/theme/      tokens.dart (cores/raios/sombras), app_theme.dart (M3 dark + Inter)
  core/router/     app_router.dart (GoRouter + transições)
  shared/widgets/  progress_ring, common (GlowButton/GwCard/GwChip/GwProgressBar), app_bottom_nav
  data/            mock_data.dart (dados de exemplo; trocar pela API depois)
  features/        dashboard, flashcards, subject_detail, quiz, simulado, stats, themed_quiz, home
```
Os dados são **mock** (espelham as props do protótipo). A integração com a API
(Dio) entra depois, substituindo `data/mock_data.dart`.

## Rodar
```bash
cd frontend
flutter create .        # gera as pastas de plataforma (android/, etc.) sem tocar em lib/
flutter pub get
flutter run             # device/emulador Android
# ou para validar sem device:
flutter analyze
```
