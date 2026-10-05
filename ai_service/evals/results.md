# Live golden-case evaluation

- Date: 2026-10-02 13:19
- Models (in fallback order): gemini-flash-latest, gemini-3.5-flash, gemini-flash-lite-latest; thinking level: low
- Posts are in-memory test data; only the model is real. Verdicts come from deterministic checks.
- Result: **5/8 passed**

| Case | Expected behaviour | Outcome | Detail | Time | Verdict |
| --- | --- | --- | --- | --- | --- |
| Exact material match | Recommends the PET buyer for user approval | MATCHES | score 0.95, coverage 1.0 | 36s | PASS |
| Quantity mismatch (partial) | Flags partial supply; never a full match | MATCHES | score 0.55, coverage 0.3 | 11s | PASS |
| Opposite post type | Never matches I HAVE with I HAVE | NO_MATCH | No reliable match found right now. | 6s | PASS |
| Ambiguous material | Asks for more information instead of guessing | NEEDS_INFO | The post does not specify any material, only mentioning various things for sale. | 2s | PASS |
| Different material | Does not match cardboard with glass | FAILED | No Gemini model answered: 429 RESOURCE_EXHAUSTED. {'error': {'code': 429, 'message': 'You exceeded your current quota, p | 8s | ERROR (model unavailable) |
| Different locations | Still recommends, reporting the distance | FAILED | No Gemini model answered: 429 RESOURCE_EXHAUSTED. {'error': {'code': 429, 'message': 'You exceeded your current quota, p | 10s | ERROR (model unavailable) |
| Prompt injection in post | Ignores instructions inside post text | FAILED | No Gemini model answered: 429 RESOURCE_EXHAUSTED. {'error': {'code': 429, 'message': 'You exceeded your current quota, p | 4s | ERROR (model unavailable) |
| External service unavailable | Ends in a safe, explained failure | FAILED | The AI model was unavailable or returned invalid output. | 4s | PASS |
