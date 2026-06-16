"""Templates de prompt usados pelos providers de IA."""

SUMMARY_PROMPT = """Você é um assistente de estudos. Analise o CONTEÚDO e responda \
APENAS com um JSON válido (sem texto extra, sem markdown) no formato:
{{
  "short": "resumo em no máximo 3 frases",
  "full": "resumo completo e didático",
  "topics": ["tópico 1", "tópico 2"],
  "glossary": {{"termo": "definição"}},
  "formulas": ["fórmula 1 (quando existir, senão lista vazia)"]
}}

CONTEÚDO:
{content}
"""

FLASHCARDS_PROMPT = """Crie {count} flashcards de estudo a partir do CONTEÚDO.
Responda APENAS com um JSON válido (array), sem texto extra:
[{{"front": "pergunta/conceito", "back": "resposta/explicação"}}]

CONTEÚDO:
{content}
"""

QUIZ_PROMPT = """Crie {count} questões de prova a partir do CONTEÚDO.
Tipos permitidos: {types}.
Cada questão DEVE ter uma explicação da resposta correta.
Responda APENAS com um JSON válido (array), sem texto extra:
[{{
  "type": "multiple_choice|true_false|fill_blank|matching|open",
  "prompt": "enunciado",
  "options": ["a", "b", "c", "d"],
  "correct_answer": "resposta correta",
  "explanation": "por que está correta"
}}]
Para questões abertas, deixe "options" como lista vazia.

CONTEÚDO:
{content}
"""

DIFFICULTY_GUIDE = {
    "easy": "fácil — definições e conceitos básicos, perguntas diretas",
    "medium": "médio — exige compreensão e aplicação dos conceitos",
    "hard": "difícil — exige análise, comparação e raciocínio aprofundado",
}

# Quiz por tema — a trava de escopo é o ponto central: a IA não pode "se perder".
THEMED_QUIZ_PROMPT = """Você é um gerador de quiz de estudos para um aluno.

DISCIPLINA: {subject}
TEMA OBRIGATÓRIO: {theme}
NÍVEL: {difficulty}

REGRAS ABSOLUTAS (não viole nenhuma):
1. TODAS as {count} questões devem ser EXCLUSIVAMENTE sobre o TEMA "{theme}" \
dentro de {subject}.
2. NÃO gere questões de outros temas e NÃO fuja do assunto, mesmo que pareça relacionado.
3. Respeite o NÍVEL de dificuldade indicado.
4. Cada questão DEVE ter uma explicação da resposta correta.
5. {source_rule}

Tipos permitidos: {types}.

Responda APENAS com um JSON válido (array), sem texto extra:
[{{
  "type": "multiple_choice|true_false|fill_blank|matching|open",
  "prompt": "enunciado (sobre o tema)",
  "options": ["a", "b", "c", "d"],
  "correct_answer": "resposta correta",
  "explanation": "por que está correta"
}}]
Para questões abertas, deixe "options" como lista vazia.
{context_block}"""

THEMED_SOURCE_RULE_MATERIAL = (
    "Baseie-se SOMENTE no MATERIAL fornecido abaixo. Se algo não estiver nele, "
    "não invente."
)
THEMED_SOURCE_RULE_GENERAL = (
    "Use apenas conhecimento consolidado e correto sobre o tema; não invente fatos."
)

MINDMAP_PROMPT = """Crie um mapa mental em Markdown (usando listas aninhadas com \
'-') a partir do CONTEÚDO. Comece com um título '# '. Responda apenas o Markdown.

CONTEÚDO:
{content}
"""

# RAG — a regra de ouro: nunca inventar.
ANSWER_PROMPT = """Você responde dúvidas de um aluno usando SOMENTE o CONTEXTO abaixo.
Regras absolutas:
- Use apenas informações presentes no CONTEXTO.
- Nunca invente ou use conhecimento externo.
- Se a resposta não estiver no CONTEXTO, responda EXATAMENTE:
  "Essa informação não está presente no material enviado."

CONTEXTO:
{context}

PERGUNTA: {question}

RESPOSTA:"""

CORRECTION_PROMPT = """Avalie a resposta do aluno comparando com a esperada.
Responda APENAS com JSON válido:
{{"is_correct": true|false, "score": 0.0, "feedback": "explicação"}}

PERGUNTA: {question}
RESPOSTA ESPERADA: {expected}
RESPOSTA DO ALUNO: {user_answer}
"""

GROUNDING_REFUSAL = "Essa informação não está presente no material enviado."
