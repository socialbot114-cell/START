# START — Roadmap do produto

## Visão

Transformar o START em um companheiro local e offline para noites de jogos: organizar pessoas e jogos, decidir o que jogar, sortear opções, acompanhar partidas e manter rankings e histórico no próprio aparelho.

## Princípios

- Uso rápido: dados, cartas e outros sorteios continuam disponíveis sem precisar iniciar uma partida.
- Offline e local nesta etapa; sem contas nem sincronização entre dispositivos.
- Resultados de partidas são a fonte dos rankings, que são calculados a partir do histórico.
- Modelos de jogos e roletas são editáveis; templates são copiados para a biblioteca pessoal.
- Uma partida interrompida pode ser retomada, com placar e relógios persistidos.

## Fluxo principal

`Jogadores e grupos → escolha do jogo → roleta de jogo ou roleta do template → partida ao vivo → resultado → ranking e histórico`

Os modos atuais de início rápido (dados, dedos, carta alta e situações) permanecem independentes desse fluxo.

## Fases

### 1. Fundação local

- [x] Persistência local versionada para grupos, jogadores, roletas e partidas.
- [x] Grupos/mesas criados pelos jogadores, com membros próprios.
- [x] Snapshot dos nomes dos participantes dentro de cada partida para preservar o histórico.
- [x] Retomada de partidas ativas após fechar e reabrir o app.

### 2. Roletas e escolha de jogos

- [x] Roleta “O que vamos jogar?” com títulos de jogos como opções.
- [x] Biblioteca “Minhas roletas” com criar, editar, duplicar e apagar.
- [x] Editor para adicionar, remover, renomear e reordenar opções.
- [x] Animação que termina no setor sorteado; resultado sorteado antes da animação.
- [x] Registro local de resultados e opção de remover uma opção após o sorteio.

### 3. Biblioteca de templates

- [x] Catálogo offline de jogos conhecidos e seus templates de roleta.
- [x] Templates podem conter roletas de personagem, facção, cenário, mapa ou outras opções do jogo.
- [x] Adicionar um template cria uma cópia pessoal, que pode ser alterada sem modificar o original.
- [x] Começar com um conjunto pequeno baseado nos jogos de referência enviados e ampliar depois.

### 4. Partidas ao vivo

- [x] Criar uma partida para um jogo e grupo, escolhendo os participantes.
- [x] Placar manual por jogador, com ajustes rápidos, histórico de alterações e desfazer.
- [x] Rodada atual e cronômetro total da partida.
- [x] Temporizador de turno com durações predefinidas e personalizadas, pausa e retomada.
- [x] Encerramento com seleção explícita de vencedor(es), suportando empate e regras variadas.

### 5. Rankings e histórico

- [x] Ranking local separado por grupo e jogo.
- [x] Estatísticas iniciais: partidas, vitórias, empates, derrotas, taxa de vitória e pontos.
- [x] Ordenação padrão por vitórias; demais números ficam visíveis para dar contexto.
- [x] Rankings oficiais consideram apenas partidas encerradas; partidas ao vivo aparecem separadamente.
- [x] Histórico com data, participantes, placar, resultado e duração.
- [x] Corrigir/remover um resultado recalcula o ranking a partir das partidas encerradas.

### 6. Qualidade e evolução

- [x] Executar no simulador iOS testes de persistência após relançamento, placar, ranking e retomada de uma partida com timer.
- [x] Executar testes dos fluxos principais de roletas, templates, criação local e conclusão de partida.
- [ ] Ampliar cobertura automatizada para empate, correção de resultados e isolamento entre grupos/jogos.
- [x] Configurar capturas das telas da biblioteca, templates, roleta, partida ao vivo, ranking e histórico.
- [x] Revisar e copiar os 14 prints, seis dados e reel aprovados para `prints-finais/START-visual-review/`.
- [ ] Avaliar sincronização/exportação e suporte a outras plataformas numa etapa futura.

## Modelo de domínio proposto

- **Grupo:** mesa local criada pelos jogadores e seus participantes.
- **Jogo:** título de template ou jogo personalizado.
- **Roleta:** título, vínculo opcional a um jogo, opções, configuração e histórico de giros.
- **Partida:** grupo, jogo, participantes em snapshot, placar, eventos, tempos, estado e resultado.
- **Ranking:** projeção calculada das partidas encerradas para um grupo e jogo; não mantém totais independentes que possam divergir do histórico.

## Estado atual

- App iOS existente: modos de dados, dedos, cartas e situações; rolagem 3D e capturas visuais.
- `PlayerStore` agora guarda grupos, jogadores, roletas, giros e partidas em um snapshot Codable versionado no Application Support; relógios usam datas persistidas para retomada correta.
- Roletas, templates, partidas, placares, resultados, rankings e histórico implementados na árvore de trabalho.
- GitHub Actions passou no build e nos 6 testes UI; os 14 prints foram revisados e o reel contém os seis modelos na sequência correta.
- A pasta `android/` contém trabalho local não rastreado; este ciclo preserva esses arquivos e foca na versão iOS.
