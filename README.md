# START — Your Board Game Companion

MVP nativo para iOS, feito em SwiftUI e utilizável offline. A linguagem visual parte da referência de mesa de jogos: madeira escura, painéis verdes/carvão e detalhes dourados.

## Ferramentas

- **Dados 3D:** D4, D6, D8, D10, D12 e D20 com modelos poligonais SceneKit. O resultado é sorteado uniformemente pelo gerador do sistema; a animação termina com a face sorteada voltada para o jogador.
- **Carta mais alta:** usa um baralho padrão de 52 cartas sem repetição dentro da rodada, com desempate.
- **Dedos na tela:** sorteia entre toques simultâneos mantidos por 2 segundos.
- **Cartas de situação:** sorteia critérios offline e deixa o grupo selecionar quem começa.

## Revisão visual pelo GitHub Actions

O workflow **iOS build + visual review** roda no simulador de iPhone e publica dois artefatos separados para facilitar a revisão:

- `START-prints`: PNG de cada tela em resolução do simulador e `START-contact-sheet.png` com a montagem geral;
- `START-dice-preview`: vídeo `START-session.mp4` com a navegação e a rolagem 3D do dado.

O modo de screenshot usa um resultado controlado para facilitar a revisão; o app normal continua sorteando aleatoriamente.
