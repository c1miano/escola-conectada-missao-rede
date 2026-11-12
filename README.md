# Escola Conectada: Missão Rede

Jogo 2D em HTML5 feito com [Phaser 3](https://phaser.io/). Não precisa de build: o código roda direto no navegador.

## Jogar online

A cada push na branch `main`, o GitHub Actions publica o jogo no GitHub Pages:

`https://<seu-usuario>.github.io/escola-conectada-missao-rede/`

## Rodar localmente

Módulos ES precisam de um servidor HTTP (abrir o `index.html` direto do disco não funciona):

```bash
python3 -m http.server 8000
```

Depois acesse http://localhost:8000.

## Controles

- **Setas / WASD**: mover
- **Espaço / ↑ / W**: pular
- **R**: reiniciar
- **Toque (celular)**: terço esquerdo/direito da tela move, meio pula

## Estrutura

```
index.html              página que carrega o Phaser e o jogo
src/main.js             configuração do jogo
src/scenes/BootScene.js gera/carrega texturas
src/scenes/GameScene.js lógica da fase
assets/                 imagens, sons, mapas
.github/workflows/      deploy automático no GitHub Pages
```
