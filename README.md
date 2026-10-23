# Atividade Multiplayer

Jogo de plataforma multiplayer feito em Godot 4.7.1. Um jogador cria a partida como servidor (host) e outro entra como cliente. Cada participante controla seu próprio personagem; quando um deles alcança o portal, a partida exibe a tela de vitória correspondente para os dois.

## Requisitos

- Godot 4.7.x (projeto configurado para Godot 4.7).
- Para partidas em computadores diferentes, ambos precisam estar na mesma rede ou ter conectividade entre si. O host precisa permitir tráfego UDP na porta `7000` no firewall/roteador.

## Como executar

1. Abra o **Project Manager** do Godot e importe/abra a pasta deste projeto, selecionando `project.godot`.
2. Execute o projeto com **F5** para iniciar a cena principal configurada.
3. Na primeira instância, selecione **Servidor/Host** para criar a partida.
4. Na segunda instância, digite o endereço do host no campo de endereço e selecione **Entrar/Cliente**. Para testar na mesma máquina, use `127.0.0.1`.
5. Jogue até um dos personagens alcançar o portal; a tela de vitória aparece em ambas as instâncias.

## Controles

| Jogador | Esquerda | Direita | Pular |
| --- | --- | --- | --- |
| Player 1 (host) | `A` | `D` | `W` |
| Player 2 (cliente) | `←` | `→` | `↑` |

## Organização

- `cenas/`: cena principal, fase, portal e telas de vitória.
- `scripts/`: lógica principal, rede, portal e script da tela de vitória.
- `scripts/personagens/`: scripts auxiliares de animação.
- `personagem/`: cenas e scripts dos jogadores.
- `assets/`: sprites, efeitos e tilesets usados pelo jogo.
- `project.godot`: configuração do projeto e cena inicial.

A replicação de movimento e animação é configurada nos scripts/cenas dos jogadores. O `MultiplayerSpawner` cria os jogadores e sincroniza sua entrada/saída; o host decide o vencedor e replica o resultado para o cliente.