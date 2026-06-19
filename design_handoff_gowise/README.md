# Handoff: GoWise Helper — App de estudos gamificado

## Overview
GoWise Helper é um app mobile (Android, portrait, **dark only**) que transforma estudo em progressão gamificada: disciplinas, flashcards com repetição espaçada, quizzes com feedback, simulados cronometrados, estatísticas e um gerador de **quiz por tema** (o usuário digita o assunto e recebe um quiz focado só nele). Este pacote documenta 7 telas de alta fidelidade.

## About the Design Files
Os arquivos deste bundle são **referências de design feitas em HTML** — protótipos que mostram aparência e comportamento pretendidos, **não** código de produção para copiar direto. A tarefa é **recriar estes designs no ambiente do app alvo** (o doc original menciona **Flutter + Material 3 + Riverpod + Go Router + Dio**), usando os padrões e bibliotecas já estabelecidos. Se ainda não houver ambiente, inicialize o projeto Flutter e implemente lá.

> `GoWise Helper.dc.html` é um "Design Component" — abre no navegador via `support.js` (runtime do protótipo). `support.js` é só para visualizar o protótipo; **não** faz parte do app de produção.

## Fidelity
**Alta fidelidade (hifi).** Cores, tipografia, espaçamento e interações são finais. Recriar pixel-perfect com a biblioteca de UI do codebase. As 4 primeiras telas existem em 2 direções (A/B) — a direção escolhida pelo cliente foi: **Dashboard = Opção A (bento gamificado)** e **Flashcard = Opção B (pilha + swipe + mnemônico)**. As demais telas têm direção única.

---

## Design Tokens

### Cores (tema escuro)
| Token | Hex | Uso |
|---|---|---|
| `bg` | `#0F1115` | Fundo da tela |
| `bgElevated` (status/nav) | `#13151A` | Barra de navegação inferior, rodapés |
| `card` | `#1E2128` | Cards, campos, tiles |
| `cardAlt` | `#15171C` / `#181B21` | Superfícies internas (miolo de anéis, cards empilhados) |
| `border` | `#2A2E37` | Bordas 1px de cards |
| `borderSubtle` | `#1F232B` / `#23262E` | Divisores, bordas de cards de fundo |
| `textHi` | `#ECEDEE` | Texto principal |
| `textMid` | `#C8CDD3` | Corpo de texto secundário (parágrafos) |
| `textLo` | `#9BA1A6` | Texto auxiliar/labels |
| `textDim` | `#6B7280` | Texto desativado, dicas, ícones inativos |
| **`primary` (violeta)** | `#8B7CF6` | CTA principal, nav ativo, nível, foco |
| `primaryLight` | `#A78BFA` | Gradientes/realces do violeta |
| `success` (verde) | `#34D399` | Acertos, "Lembrei", concluído |
| `accent` (ciano) | `#22D3EE` | Informacional, secundário, XP |
| `streak` (âmbar) | `#FBBF24` | Ofensiva / chama / streak |
| `error` (vermelho) | `#F87171` | Erros, "Errei", "Revisar" |

### Acentos pastel por disciplina (cor própria de cada matéria)
Aparecem **só** dentro dos elementos da própria disciplina (ícone, anel, barra, chip):
| Disciplina | Hex |
|---|---|
| Cálculo I | `#B6A8F2` (lavanda) |
| Anatomia | `#F2A6BE` (rosa) |
| Algoritmos | `#8FE3C4` (menta) |
| Microeconomia / Psicologia | `#97C6F2` (azul-céu) |
| Bioquímica | `#F2DD97` (manteiga) |

### Tipografia
- Família: **Inter** (400/500/600/700/800/900). Em Flutter, usar `google_fonts` → Inter.
- Escala observada: display 40/900; títulos de tela 20–22/800 (`letter-spacing:-.4px`); número de destaque 24–34/800 (`letter-spacing:-.5 a -1px`); corpo 14–16/500–600; labels/overline 11/700 `letter-spacing:1.5–2px` (UPPERCASE); micro 10–12/500.

### Raio, espaçamento, sombra
- **Raios:** chips/tags `999px (pill)` ou `9–12px`; cards `16–24px`; molduras hero `24–28px`; botões `15–18px`.
- **Espaçamento:** escala 4pt (4/8/12/16/24). Padding lateral de tela = `18px`. Seções separadas por `~18–24px`.
- **Sombra/glow:** cards `0 4 12 rgba(0,0,0,.4)`. **Glow neon é a assinatura**: preenchimentos emitem brilho da mesma cor — ex. barras de progresso e CTAs usam `box-shadow:0 8px 24px rgba(139,124,246,.4)` e a parte preenchida da barra carrega `0 0 10–12px` da própria cor a 50–60% alpha.
- **Botões:** sempre CAPS no rótulo (`labelLarge`), altura 48–52px.

---

## Screens / Views

### 1. Dashboard (Opção A — escolhida)
- **Purpose:** hub diário; revisar, ver progresso e missões.
- **Layout:** coluna rolável (padding 18px) + barra de navegação fixa inferior (5 abas) + pílula de gesto.
- **Componentes (de cima p/ baixo):**
  1. **Header** — avatar 46px (gradiente lavanda→violeta, inicial), saudação ("Olá, {nome}" / "Bora revisar?"), botão de sino com badge de notificação vermelho.
  2. **Hero Nível+Ofensiva** — card gradiente `135deg rgba(139,124,246,.22)→rgba(34,211,238,.10)`. Anel de nível 84px via `conic-gradient` (preenchido até `248deg` = ~69%), miolo `#13151A` com "NÍVEL / 7". À direita: chama âmbar + "{streak} dias de ofensiva", barra de XP 69% (glow violeta), "1.240 XP / faltam 560 p/ Nv 8".
  3. **CTA Revisão de hoje** — card `#1E2128`, anel 50px "0/24", botão violeta full-width "REVISAR AGORA" com ícone `repeat` (símbolo de repetição espaçada).
  4. **Bento 2×2** — tiles `#1E2128` r18: Ofensiva (12, chama âmbar), XP hoje (240, raio ciano), Precisão (87%, alvo verde), Tempo hoje (42min, relógio lavanda).
  5. **Missões diárias** (2/3) — linhas com ícone, título, mini-barra de progresso e recompensa "+50/+30 XP".
  6. **Disciplinas** — linhas com anel de % (cor pastel da disciplina), nome, "N cartões para revisar", chevron.
  7. **Bottom nav** — Início (ativo, violeta), Disciplinas, **Revisar (FAB central elevado**, 50px, gradiente violeta→ciano, ícone repeat), Stats, Perfil. Ícones inativos `#6B7280`.

> A **Opção B** (no arquivo) é uma alternativa "foco/feed": calendário semanal de ofensiva, card grande "continue de onde parou", meta de XP, scroll horizontal de decks. Mantida como referência, não a escolhida.

### 2. Flashcard (Opção B — escolhida)
- **Purpose:** revisar cartões com recall ativo + dica mnemônica.
- **Layout:** topbar (voltar / título-disciplina / chip de ofensiva) + barra de progresso "12/30 dominados" + área de cartão (pilha) + controles inferiores fixos.
- **Componentes:**
  - **Pilha de cartões:** 2 cartões de fundo levemente escalados/deslocados (`scale .9/.95`, `translateY`), criando profundidade.
  - **Cartão (flip 3D):** `perspective:1600px`, faces com `backface-visibility:hidden`, verso `rotateY(180deg)`, transição `.55s cubic-bezier(.4,0,.2,1)`. **Toque vira o cartão.**
    - Frente: overline "PERGUNTA" (rosa) + medidor de maestria (5 pontos, 3 preenchidos rosa) + pergunta 25/700 + chip de **Dica** mnemônica (fundo `rgba(242,166,190,.1)`).
    - Verso: "RESPOSTA" + resposta 30/800 + explicação mnemônica com borda-esquerda rosa 2px.
  - **Controles inferiores:** dois botões grandes — "Revisar" (vermelho, seta ←) e "Lembrei" (verde, gradiente, seta →). Texto-guia "Arraste ← revisar depois · → já lembro". Classificar avança o cartão e incrementa "dominados".

> A **Opção A** (no arquivo): flip + **escala de confiança estilo SM-2** (Errei `<1min` / Difícil `6min` / Bom `1 dia` / Fácil `4 dias`) — útil se quiserem repetição espaçada explícita.

### 3. Detalhe da disciplina (Cálculo I)
- **Purpose:** central da matéria com abas.
- **Layout:** header (voltar / "Cálculo I" / menu ⋯) + hero lavanda + **tab bar (4)** + painel rolável.
- **Hero:** anel 78px (conic 68% lavanda) "68% dominado", "Nível 4 · Aprendiz", 3 stats (86 cartões / 87% precisão / 12 ofensiva âmbar).
- **Tabs (interativas, troca de conteúdo):** Resumo · Flashcards · Quiz · Mapa. Ativa = texto `#ECEDEE` + `border-bottom:2px #B6A8F2`; inativa = `#6B7280`.
  - **Resumo:** card com overline "RESUMO", parágrafo, 3 bullets com check verde, rodapé "Gerado de 3 PDFs · 24 páginas", CTA lavanda "Continuar estudando".
  - **Flashcards:** lista de decks (Derivadas 12 a revisar / Limites em dia / Integrais 8), barra colorida à esquerda, CTA "REVISAR 20 CARTÕES".
  - **Quiz:** card launcher com ícone, "Quiz rápido · Derivadas", melhor nota 87%, 3 tentativas, CTA ciano "INICIAR QUIZ".
  - **Mapa:** mapa mental — nó central "Derivadas" (gradiente lavanda) ligado por linhas finas a 3 nós-filho + chips de subtópicos.

### 4. Quiz (interativo)
- **Purpose:** responder com feedback imediato + explicação.
- **Layout:** topbar (fechar / "Quiz · Derivadas" / cronômetro) + barra de progresso "{n}/{total}" + pergunta + 4 alternativas + (explicação) + botão Próxima.
- **Comportamento:** tocar uma alternativa **trava** a resposta. Correta → fundo `rgba(52,211,153,.14)` + borda verde + ✓; selecionada errada → `rgba(248,113,113,.14)` + borda vermelha + ✗; demais → opacity .45. Aparece painel de explicação ("Correto! +10 XP" verde, ou "Resposta: B) …" vermelho) e botão **Próxima** (ciano) que avança e reseta a seleção. Antes de responder: "Escolha uma alternativa para continuar".

### 5. Simulado
- **Purpose:** configurar e iniciar simulado cronometrado.
- **Layout:** header + grid 2×2 de tamanhos + linha cronômetro + chips de disciplinas + histórico + CTA fixo.
- **Componentes:** grid **10 / 20 / 50 / 100** (toque seleciona; selecionado = `rgba(139,124,246,.16)` + borda violeta 1.5px; mostra "questões · ~tempo"). Linha "Cronômetro" com toggle verde + "{tempo} sugeridos". Chips de disciplinas incluídas (ponto pastel). "Últimos simulados" com nota em badge colorido (8.5 verde, 7.2 âmbar). CTA "INICIAR SIMULADO · {n}" (atualiza com a seleção).

### 6. Estatísticas
- **Purpose:** progresso semanal e domínio.
- **Componentes:** toggle Semana/Mês. **3 KPIs** (14h tempo / 84% precisão verde / 312 dominados). **Gráfico de barras "Atividade da semana"** — 7 barras (S–D), alturas fixas em px, sábado em destaque (gradiente violeta + glow), "+18%". **Domínio por disciplina** — 4 barras de progresso com a cor pastel de cada matéria (Cálculo 68% / Algoritmos 82% / Anatomia 45% / Psicologia 30%).

### 7. Quiz por tema ⭐ (interativo, 2 estados)
- **Purpose:** o usuário escolhe a disciplina e digita o **tema**; o app gera um quiz **preso àquele tema** (sem fugir do assunto).
- **Estado SETUP:** título "Novo quiz por tema"; chips de **Disciplina** (Psicologia selecionada — `rgba(151,198,242,.16)` + borda azul); **campo de tema** (input controlado, prefixo com ícone, placeholder "Ex.: Teorias da personalidade"); aviso com ícone de cadeado verde "As perguntas ficam **presas a este tema** — sem fugir do assunto"; segmento **Nº de questões 5/10/20**; chips de **Dificuldade** (Médio selecionado); CTA "GERAR QUIZ" (gradiente azul→ciano).
- **Estado QUIZ (gerado):** topbar mostra a disciplina + **o tema com selo de cadeado verde** (reforço de que o escopo não muda) + barra de progresso. Mesma mecânica de feedback da tela Quiz, com perguntas de Psicologia (Freud / id / Big Five). Botão voltar retorna ao SETUP.

---

## Interactions & Behavior
- **Flip de flashcard:** toque alterna `rotateY(0↔180deg)`, transição `.55s cubic-bezier(.4,0,.2,1)`.
- **Quiz/Quiz por tema:** seleção é única e irreversível por questão (trava ao primeiro toque); revela cores de acerto/erro + explicação; "Próxima" avança e zera a seleção; índice circula pelas perguntas.
- **Quiz por tema:** "GERAR QUIZ" troca `themeScreen: 'setup' → 'quiz'`; voltar faz o inverso. O campo de tema é controlado (atualiza o cabeçalho do quiz gerado).
- **Simulado:** seleção de tamanho atualiza o rótulo do CTA e o tempo sugerido.
- **Detalhe:** troca de aba via estado `tab`.
- **Motion (do brief):** press = scale 96% 120ms ease-out; transição de página = slide + 8% overlay 220ms; ganho de XP = barra preenche com rastro + contador; loading = **shimmer com a forma do conteúdo final, nunca spinner genérico**; erro = shake inline 120ms ×3. Respeitar reduce-motion.

## State Management
Estado do protótipo (mapear para Riverpod/providers):
- Flashcard: `flip`, `idx`, `done` (cartões dominados).
- Detalhe: `tab` ∈ {resumo, flash, quiz, mapa}.
- Quiz: `qIdx`, `qSel` (null = não respondido).
- Simulado: `simLen` ∈ {10,20,50,100}.
- Quiz por tema: `themeDisc`, `theme` (string), `tqCount` ∈ {5,10,20}, `themeScreen` ∈ {setup,quiz}, `tqIdx`, `tqSel`.
- Props globais de exemplo: `studentName`, `streakDays`.
- **Data fetching:** conteúdo de resumo/flashcards/quiz vem da IA/RAG (ver doc original). Toda tela assíncrona deve ter 4 estados: loading (shimmer) · empty (ilustração+headline+CTA) · error (ícone+mensagem+retry) · success.

## Assets
- **Ícones:** stroke 1.5–1.8px, cantos arredondados (estilo **Lucide**: home, book-open, repeat, bar-chart, user, flame, zap, check, x, chevron, clock, target, lock, lightbulb, file-text). Variante preenchida para ativo. Recriar com a lib de ícones do app (ex. `lucide_icons` / `flutter_svg`). **Sem emoji.**
- **Sem fotografia.** Ilustrações (quando existirem) em estilo anime, fundo transparente. Identidade é data-driven (anéis/gráficos), não retrato.
- **Logo/wordmark:** "GoWise Helper" em Inter 800; marca em quadrado 12px com gradiente violeta→ciano e ícone de livro.

## Files
- `GoWise Helper.dc.html` — protótipo com as 7 telas (template + lógica de interação). Referência visual principal.
- `support.js` — runtime do protótipo (apenas para abrir o HTML; ignorar na implementação).
- Abrir o `.html` num navegador para interagir; cada moldura tem `data-screen-label` com o nome da tela.
