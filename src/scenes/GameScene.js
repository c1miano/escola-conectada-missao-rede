export default class GameScene extends Phaser.Scene {
  constructor() {
    super('Game');
  }

  create() {
    const { width, height } = this.scale;

    // Plataformas
    this.platforms = this.physics.add.staticGroup();
    for (let x = 32; x < width + 32; x += 64) {
      this.platforms.create(x, height - 8, 'ground');
    }
    this.platforms.create(200, 320, 'ground');
    this.platforms.create(264, 320, 'ground');
    this.platforms.create(520, 240, 'ground');
    this.platforms.create(584, 240, 'ground');

    // Jogador
    this.player = this.physics.add.sprite(100, height - 60, 'player');
    this.player.setCollideWorldBounds(true);
    this.physics.add.collider(this.player, this.platforms);

    // Moedas
    this.coins = this.physics.add.group({ allowGravity: false });
    [[232, 290], [552, 210], [700, 400], [400, 400]].forEach(([x, y]) => {
      this.coins.create(x, y, 'coin');
    });
    this.score = 0;
    this.add.text(this.scale.width - 16, 16, 'Escola Conectada: Missão Rede', { fontFamily: 'monospace', fontSize: '16px', color: '#fff' }).setOrigin(1, 0);
    this.scoreText = this.add.text(16, 16, 'Moedas: 0', { fontFamily: 'monospace', fontSize: '20px', color: '#fff' });
    this.physics.add.overlap(this.player, this.coins, (_p, coin) => {
      coin.destroy();
      this.score += 1;
      this.scoreText.setText(`Moedas: ${this.score}`);
      if (this.coins.countActive() === 0) {
        this.add.text(width / 2, height / 2, 'Você venceu!\nR para reiniciar', {
          fontFamily: 'monospace', fontSize: '28px', color: '#fff', align: 'center',
        }).setOrigin(0.5);
      }
    });

    // Controles: teclado (setas / WASD / espaço) e toque (esquerda / direita / meio = pular)
    this.cursors = this.input.keyboard.createCursorKeys();
    this.keys = this.input.keyboard.addKeys('W,A,D,R');
    this.touch = { left: false, right: false, jump: false };
    this.input.addPointer(2);
    this.input.on('pointerdown', () => this.updateTouch());
    this.input.on('pointermove', () => this.updateTouch());
    this.input.on('pointerup', () => this.updateTouch());
  }

  updateTouch() {
    const w = this.scale.width;
    const t = { left: false, right: false, jump: false };
    for (const p of this.input.manager.pointers) {
      if (!p.isDown) continue;
      if (p.x < w / 3) t.left = true;
      else if (p.x > (2 * w) / 3) t.right = true;
      else t.jump = true;
    }
    this.touch = t;
  }

  update() {
    const speed = 220;
    const left = this.cursors.left.isDown || this.keys.A.isDown || this.touch.left;
    const right = this.cursors.right.isDown || this.keys.D.isDown || this.touch.right;
    const jump = this.cursors.up.isDown || this.cursors.space.isDown || this.keys.W.isDown || this.touch.jump;

    if (left) this.player.setVelocityX(-speed);
    else if (right) this.player.setVelocityX(speed);
    else this.player.setVelocityX(0);

    if (jump && this.player.body.blocked.down) {
      this.player.setVelocityY(-480);
    }

    if (Phaser.Input.Keyboard.JustDown(this.keys.R)) {
      this.scene.restart();
    }
  }
}
