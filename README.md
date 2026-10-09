# START — Your Board Game Companion

App nativo para iOS, feito em SwiftUI e utilizável offline. A linguagem visual parte da referência de mesa de jogos: madeira escura, painéis verdes/carvão e detalhes dourados.

## Ferramentas

- **Dados 3D:** D4, D6, D8, D10, D12 e D20 em resina polida, modelados no Blender e empacotados como USDZ para SceneKit. O acabamento usa microtextura sutil, chanfros proporcionais e marcações de baixo relevo visual; os pips do D6 ficam rebaixados com insertos escuros. O D4 marca os vértices; os demais exibem valores nas faces e respeitam pares opostos. O resultado é sorteado uniformemente pelo gerador do sistema; a animação termina na face/vértice correspondente.
- **Carta mais alta:** usa um baralho padrão de 52 cartas sem repetição dentro da rodada, com desempate.
- **Dedos na tela:** sorteia entre toques simultâneos mantidos por 2 segundos.
- **Cartas de situação:** sorteia critérios offline e deixa o grupo selecionar quem começa.
- **Roletas locais:** roleta para escolher um jogo, roletas personalizadas com edição e histórico de giros, além de templates editáveis.
- **Partidas e rankings:** grupos de jogadores, partidas retomáveis, placar com desfazer/correção, cronômetro total, timer de turno, resultados e rankings por jogo/grupo.
- **Dados locais:** grupos, roletas, giros e partidas são guardados no armazenamento local do app; não há conta nem sincronização nesta versão.

## Revisão visual pelo GitHub Actions

O workflow **iOS build + visual review** roda no simulador de iPhone e publica dois artefatos separados para facilitar a revisão:

- `START-prints`: PNG das telas do app e dos seis dados, montagens geral e de dados, e `START-dice-blender-preview.png` renderizado no Blender;
- `START-all-dice-reel`: `START-all-dice.mp4` com os seis dados rolando em sequência.

## Roadmap

O plano do produto, arquitetura de dados e fases de evolução estão em [`ROADMAP.md`](ROADMAP.md).

O modo de screenshot usa um resultado controlado para facilitar a revisão; o app normal continua sorteando aleatoriamente.

## Assets dos dados

- USDZ do app: `START/Art.scnassets/Dice/`
- Cena editável e render de referência do Blender: `Blender/START-dice-studio.blend` e `Blender/START-dice-studio.png`
- Regenerar os assets com Blender 5.2+: `blender -b --python Scripts/generate_dice_assets.py -- START/Art.scnassets/Dice`
