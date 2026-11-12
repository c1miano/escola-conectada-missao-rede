# Escola Conectada: Missão Rede

Aventura 2D em **pixel art top-down (16x16)** com minijogos educativos sobre redes de computadores,
feita em **Godot 4.7.2 (GDScript)** para estudantes do Curso Técnico em Informática,
incluindo estudantes com deficiência intelectual.

- **Jogar no navegador (testes):** https://c1miano.github.io/escola-conectada-missao-rede/
- **Baixar para Windows (offline):** https://c1miano.github.io/escola-conectada-missao-rede/EscolaConectada-Windows.zip

O jogo funciona **inteiramente offline**, sem cadastro e sem internet (a versão Windows é um único `.exe`).

## História

A Escola Conectada vai fazer a Feira de Tecnologia, mas os equipamentos não se comunicam.
O jogador é um jovem técnico de informática. Ele anda pela escola e pelas salas até os equipamentos,
com a ajuda do robô **Bit**, e resolve cinco missões:

| Missão | Local | Conteúdos |
|---|---|---|
| 1. A escola desconectada | Laboratório | Topologia em estrela, switch, cabo de par trançado |
| 2. Cada computador tem seu endereço | Secretaria | IPv4, máscara, endereços duplicados, DHCP |
| 3. O mistério da mensagem perdida | Biblioteca | Ping (ICMP), DNS, HTTP, camadas TCP/IP e OSI |
| 4. O detetive das redes | Sala de Servidores | Cabo solto, IP de outra rede, serviço Web desligado |
| 5. A escola inteligente | Sala de Aula Inteligente | Wi-Fi, ponto de acesso, IoT, painel de monitoramento |

No fim, a escola fica iluminada e Bit entrega o certificado **"Técnico de Redes"**.

## Como se joga

- **Clicar** é a forma principal: clique em um equipamento e o técnico anda até ele e usa.
- **Teclado (opcional):** setas ou WASD para andar; **E**, Espaço ou Enter para **Usar** o equipamento perto;
  **Tab** troca o botão selecionado.
- Arrastar nunca é obrigatório.

## Acessibilidade pedagógica

- **Modo Guiado:** Bit dá a instrução de cada passo, a primeira ação é demonstrada, o objeto certo é destacado
  depois de um erro e há poucas escolhas por tela.
- **Modo Explorador:** menos orientações, mais opções (mais portas, cartões de IP, redes Wi-Fi, senha)
  e desafios extras no fim de cada missão. Os dois modos dão as mesmas conquistas.
- Botão permanente **"Preciso de ajuda"** com 3 níveis: reforça o objetivo → destaca o objeto → demonstra a ação.
- **Ouvir de novo:** narração das instruções com a voz do sistema (pode ser desligada).
- Sem limite de tempo, sem pontos negativos, tentativas ilimitadas.
- Acerto/erro sempre com **ícone + texto + som**, nunca só com cor.
- Opções de **texto grande** e **pular animações repetidas** (o personagem também se move na hora).

## Relatório do professor

Em *Configurações → Relatório do professor*: missões feitas, tentativas, dicas usadas (por nível)
e habilidades demonstradas. O botão *Salvar relatório* grava um `.txt` (no Windows abre a pasta; no navegador baixa o arquivo).
O relatório **não contém diagnóstico** nem classificação do estudante. Tudo fica salvo só no computador.

## Para desenvolver

1. Instale o [Godot 4.7.2](https://godotengine.org/download) e abra a pasta do projeto.
2. Aperte F5 para jogar.

### Pixel art

Os sprites ficam em `assets/sprites/` e são gerados por um script (paleta única, contorno colorido,
luz de cima/esquerda, sem antialiasing — técnicas do guia *pixel-art-professional*):

```bash
python3 tools/pixelart/gerar_sprites.py
```

Os PNGs podem ser retocados no Aseprite. `tools/pixelart/previa.png` mostra todos os sprites.

### Teste automático

Joga todas as missões sozinho e confere se foram concluídas:

```bash
godot -- --autoteste=1,2,3,4,5:guiado
```

Use `:explorador` para o outro modo. Para salvar capturas: `--autoteste=1:guiado:/pasta/capturas`.

### Publicação

A cada push na branch `main`, o GitHub Actions (`.github/workflows/deploy.yml`) exporta as versões
Web e Windows e publica no GitHub Pages. Na primeira vez, confira em
**Settings → Pages → Source: GitHub Actions**.

## Estrutura

```
project.godot
scenes/Main.tscn            cena inicial (troca de telas)
scripts/core/               estado do jogo, salvamento, relatório, sons e narração
scripts/screens/            telas: início, modos, mapa, configurações, relatório, certificado
scripts/missions/           base das missões + missões 1 a 5
scripts/ui/                 equipamentos, cabos, personagem, Bit, ícones, tema
assets/sprites/             pixel art (16x16)
tools/pixelart/             gerador de sprites
tests/autotest.gd           teste automático
```
