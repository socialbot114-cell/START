# START — Your Board Game Companion

MVP nativo para iOS, feito em SwiftUI e utilizável offline. A linguagem visual parte da referência de mesa de jogos: madeira escura, painéis verdes/carvão e detalhes dourados.

## Ferramentas

- **Dados 3D:** D4, D6, D8, D10, D12 e D20 em resina clássica, modelados no Blender e empacotados como USDZ para SceneKit. O D6 usa pips; o D4 marca os vértices. Os demais imprimem valores nas faces e respeitam pares opostos. O resultado é sorteado uniformemente pelo gerador do sistema; a animação termina na face/vertex correspondente.
- **Carta mais alta:** usa um baralho padrão de 52 cartas sem repetição dentro da rodada, com desempate.
- **Dedos na tela:** sorteia entre toques simultâneos mantidos por 2 segundos.
- **Cartas de situação:** sorteia critérios offline e deixa o grupo selecionar quem começa.

## Revisão visual pelo GitHub Actions

O workflow **iOS build + visual review** roda no simulador de iPhone e publica dois artefatos separados para facilitar a revisão:

- `START-prints`: PNG de cada tela, montagem geral e `START-dice-blender-preview.png` renderizado no Blender;
- `START-dice-preview`: vídeo `START-session.mp4` com a navegação e a rolagem 3D do dado.

O modo de screenshot usa um resultado controlado para facilitar a revisão; o app normal continua sorteando aleatoriamente.

## Assets dos dados

- USDZ do app: `START/Art.scnassets/Dice/`
- Cena editável e render de referência do Blender: `Blender/START-dice-studio.blend` e `Blender/START-dice-studio.png`
- Regenerar os assets com Blender 5.2+: `blender -b --python Scripts/generate_dice_assets.py -- START/Art.scnassets/Dice`
