// Gera texturas simples em tempo de execução para não depender de arquivos de imagem.
// Quando tiver sprites reais, carregue-os aqui com this.load.image / this.load.spritesheet
// (coloque os arquivos na pasta assets/).
export default class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  create() {
    const g = this.make.graphics({ x: 0, y: 0, add: false });

    g.fillStyle(0xffcc00).fillRect(0, 0, 32, 32);
    g.generateTexture('player', 32, 32);
    g.clear();

    g.fillStyle(0x29adff).fillRect(0, 0, 64, 16);
    g.generateTexture('ground', 64, 16);
    g.clear();

    g.fillStyle(0xff004d).fillCircle(8, 8, 8);
    g.generateTexture('coin', 16, 16);
    g.destroy();

    this.scene.start('Game');
  }
}
