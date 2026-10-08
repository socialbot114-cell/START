# START — Your Board Game Companion (MVP iOS)

Companion offline para decidir quem começa. SwiftUI nativo, iOS 17+.

## Modos do MVP
1. **Dados** — D4, D6, D8, D10, D12, D20
2. **Carta mais alta** — cada jogador tira uma carta, maior vence, empate gera desempate
3. **Dedos na tela** — multi-toque simultâneo, sorteio após segurar
4. **Situações** — baralho com critérios (óculos, vermelho, mais novo...)

## CI / Prints
Workflow `.github/workflows/ios-screenshots.yml` roda em `macos-15`:
- build no simulador iPhone 16
- `STARTScreenshotTests/testScreenshots` abre cada modo e anexa screenshots
- artefatos: `start-screenshots` + `start-test-logs`

Para rodar manualmente: Actions → iOS build + screenshots → Run workflow.
