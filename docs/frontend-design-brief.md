# GowienHelper — Briefing de Design do Frontend

Documento para gerar os mockups da UI (Flutter, Material 3, tema escuro).
Use a seção **"Prompt pronto"** no final para colar no Claude/ferramenta de design.

---

## 1. Conceito visual

App de estudos com IA. Sensação: **moderno, minimalista, escuro, focado e calmo**.
Cards arredondados, bastante respiro, hierarquia clara, animações suaves
(fade + slide curtos, 150–250 ms). Nada poluído. Mobile-first.

## 2. Design System (tokens)

### Cores (tema escuro)
| Token | Hex | Uso |
|-------|-----|-----|
| `background` | `#0F1115` | Fundo geral |
| `surface` | `#16181D` | Containers, app bar |
| `surfaceVariant` | `#1E2128` | Cards |
| `surfaceHover` | `#23262E` | Estados hover/selected |
| `outline` | `#2A2E37` | Bordas sutis (1px) |
| `primary` | `#8B7CF6` | Ação principal (violeta) |
| `primaryContainer` | `#2A2350` | Fundo de destaque |
| `secondary` | `#34D399` | Sucesso / acertos (verde) |
| `tertiary` | `#22D3EE` | Acentos / gráficos (ciano) |
| `warning` | `#FBBF24` | Streak / atenção (âmbar) |
| `error` | `#F87171` | Erros / erradas |
| `textHigh` | `#ECEDEE` | Títulos |
| `textMedium` | `#9BA1A6` | Texto secundário |
| `textDisabled` | `#5B616B` | Placeholder |

> Cada **disciplina** tem sua própria cor (campo `color`), usada como acento do card,
> da app bar do detalhe e dos gráficos daquela matéria.

### Tipografia (Inter ou similar)
- Display/H1: 28–32, bold
- H2 (títulos de seção): 20–22, semibold
- Título de card: 16, semibold
- Corpo: 14–15, regular
- Caption/label: 12–13, medium

### Forma e espaçamento
- Raio: cards **20–24px**, botões **16px**, chips/avatars **full**.
- Espaçamento base 4 → escala 4/8/12/16/24/32.
- Elevação: sombra suave + borda 1px `outline` (não usar sombras pesadas).
- Botões: primário preenchido (violeta), secundário "tonal", terciário texto.

### Componentes reutilizáveis (catálogo)
- `AppScaffold` (fundo + safe area)
- `PrimaryButton` / `TonalButton` / `IconButton`
- `AppCard` (card arredondado com borda sutil)
- `SubjectCard` (card de disciplina com cor, ícone, progresso)
- `StatTile` (número grande + label + ícone)
- `ProgressRing` / `ProgressBar`
- `Chip` (tópicos, tipos de questão, favoritos)
- `EmptyState` (ilustração + texto + CTA)
- `LoadingShimmer` (skeleton enquanto a IA processa)
- `AppTextField` (input com label flutuante)
- `BottomNavBar` (3 itens)
- `XpBadge`, `StreakFlame`, `LevelBadge`
- `FlashcardView` (com animação de flip)
- `QuizOption` (estado: normal / selecionado / correto / errado)
- `ChatBubble` (usuário x assistente)
- `Timer` (cronômetro do simulado)

## 3. Navegação (Go Router)

- **Auth stack:** Splash → Login → Cadastro
- **App shell** (bottom nav, 3 abas):
  1. **Início** (Dashboard)
  2. **Estatísticas**
  3. **Perfil**
- **Push** a partir do Dashboard: Detalhe da Disciplina (com abas internas) →
  Upload, Resumo, Mapa mental, Flashcards, Quiz, Simulado, Chat.

## 4. Telas (lista completa + layout)

### 4.1 Splash
Logo centralizada, fundo `background`, fade-in. Decide rota (logado ou não).

### 4.2 Login
- Logo + nome do app no topo.
- Campos: e-mail, senha (com olho de mostrar/ocultar).
- `PrimaryButton` "Entrar".
- Botão "Continuar com Google" (placeholder, futuro).
- Link "Criar conta".

### 4.3 Cadastro
- Campos: nome, e-mail, senha, confirmar senha.
- `PrimaryButton` "Criar conta". Link "Já tenho conta".

### 4.4 Dashboard (Início)
- Header: saudação ("Olá, Pedro 👋"), `StreakFlame` com nº de dias, `XpBadge`.
- Linha de `StatTile`: **Tempo estudado**, **Sequência**, **Nível/XP**.
- Barra de progresso de XP até o próximo nível.
- Seção "Minhas disciplinas": grid/lista de `SubjectCard`
  (cor, ícone, nome, professor, mini barra de progresso, data da prova com contagem
  regressiva tipo "prova em 5 dias").
- FAB "+" → Criar disciplina.
- `EmptyState` quando não há disciplinas.

### 4.5 Criar/Editar Disciplina
- Form: Nome; **seletor de cor** (paleta de bolinhas); **seletor de ícone**
  (grid de ícones); Professor; Descrição (multiline); **Data da prova** (date picker).
- Preview do `SubjectCard` em tempo real no topo.
- `PrimaryButton` "Salvar".

### 4.6 Detalhe da Disciplina
- App bar com a **cor da disciplina**, nome, ícone, "prova em X dias".
- **Abas** (TabBar) ou grid de atalhos:
  `Materiais` · `Resumo` · `Mapa mental` · `Flashcards` · `Quiz` · `Simulado` · `Chat` · `Glossário/Fórmulas`.

### 4.7 Materiais / Upload
- Lista de materiais enviados (nome, tipo, status: processando/pronto, data).
- Botão "Enviar material" → bottom sheet: escolher arquivo
  (PDF, DOCX, TXT, Markdown, Imagem) ou tirar foto.
- Card de status de processamento da IA (extraindo texto → gerando conteúdo) com `LoadingShimmer`.

### 4.8 Resumo
- Toggle "Curto / Completo".
- Texto formatado (markdown). Chips de **tópicos principais**.
- Botão "Gerar de novo".

### 4.9 Mapa mental
- Render do Markdown como árvore/lista aninhada estilizada (nós com a cor da disciplina).
- Opção exportar/expandir.

### 4.10 Flashcards
- **Modo estudo:** card central grande com **flip** (frente → verso ao tocar),
  botões "Errei / Difícil / Bom / Fácil" (repetição espaçada), progresso "3/20".
- **Lista:** todos os cards, ações: favoritar (estrela), editar, excluir.
- Botão "Criar manualmente" (form frente/verso).
- Filtro "Só favoritos" / "Para revisar hoje".

### 4.11 Quiz
- Uma questão por vez. Tipos: múltipla escolha, V/F, completar, relacionar, aberta.
- `QuizOption` com feedback de cor (verde correto / vermelho errado) após responder.
- **Explicação** aparece abaixo após responder.
- Barra de progresso da quantidade de questões. Tela final com pontuação.

### 4.12 Simulado
- Tela de configuração: escolher **quantidade (10/20/50/100)**, misturar disciplinas (toggle).
- Execução com **cronômetro** no topo.
- Tela de resultado: **nota final**, acertos/erros, tempo, botão "Revisar questões".

### 4.13 Chat (RAG, por disciplina)
- Lista de `ChatBubble`. Campo de input fixo embaixo + botão enviar.
- Indicador "digitando…" enquanto a IA responde.
- Mensagem de sistema quando fora do material:
  *"Essa informação não está presente no material enviado."* (estilo discreto/itálico).

### 4.14 Estatísticas
- Cards de topo: tempo total, questões respondidas, **taxa de acertos** (ProgressRing).
- Gráfico de **evolução** (linha) por semana.
- Gráfico de barras "**disciplinas mais difíceis**" (menor taxa de acerto).
- Lista de conquistas recentes.

### 4.15 Perfil / Gamificação
- Avatar, nome, **nível** e barra de XP.
- `StreakFlame` com calendário de sequência.
- Grid de **conquistas** (desbloqueadas coloridas, bloqueadas em cinza).
- Configurações: tema, provedor de IA (futuro), sair.

## 5. Estados a desenhar (não esquecer)
- Vazio (sem disciplinas, sem flashcards, chat sem mensagens).
- Carregando (skeleton/shimmer durante IA).
- Erro (falha ao processar material) com botão "tentar de novo".
- Sucesso (toast/snackbar).

---

## 6. Prompt pronto (colar no Claude/ferramenta de design)

> Crie os mockups de um app mobile de estudos com IA chamado **GowienHelper**, em
> **Flutter Material 3, tema 100% escuro, estilo moderno e minimalista**, cards bem
> arredondados (raio 20–24), bastante respiro e animações suaves.
>
> **Paleta:** fundo `#0F1115`, cards `#1E2128`, bordas sutis `#2A2E37`, primária
> violeta `#8B7CF6`, sucesso verde `#34D399`, acento ciano `#22D3EE`, streak âmbar
> `#FBBF24`, erro `#F87171`, texto principal `#ECEDEE`, secundário `#9BA1A6`.
> Tipografia Inter. Cada disciplina tem uma cor de acento própria.
>
> Gere estas telas (mobile, 1 por frame): Login, Cadastro, **Dashboard** (saudação +
> streak + XP + tempo estudado + grid de disciplinas com progresso e contagem
> regressiva da prova), Criar Disciplina (cor + ícone + campos), Detalhe da Disciplina
> com abas (Materiais, Resumo, Mapa mental, Flashcards, Quiz, Simulado, Chat),
> **Upload de material** com status de processamento da IA, **Resumo** (curto/completo +
> chips de tópicos), **Mapa mental** (árvore em markdown), **Flashcards** (card com flip
> + botões de repetição espaçada), **Quiz** (opções com feedback verde/vermelho +
> explicação), **Simulado** (config de quantidade 10/20/50/100 + cronômetro + resultado
> com nota), **Chat** estilo bolhas, **Estatísticas** (taxa de acerto em anel, gráfico de
> evolução, disciplinas mais difíceis), **Perfil** (nível, XP, streak, grid de conquistas).
> Inclua estados vazio, carregando (shimmer) e erro. Use bottom navigation de 3 itens:
> Início, Estatísticas, Perfil.
