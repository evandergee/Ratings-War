import SpriteKit

final class GameScene: SKScene {
    private enum State {
        case title, playing, roomCleared, gameOver
    }

    private enum PickupKind {
        case cash, spread, rapid, heart
    }

    private final class Enemy {
        let node: SKSpriteNode
        var hp: Int
        let speed: CGFloat
        let radius: CGFloat
        let points: Int
        let wobble = CGFloat.random(in: 0...(2 * .pi))

        init(node: SKSpriteNode, hp: Int, speed: CGFloat, radius: CGFloat, points: Int) {
            self.node = node
            self.hp = hp
            self.speed = speed
            self.radius = radius
            self.points = points
        }
    }

    private struct Bullet {
        let node: SKSpriteNode
        let velocity: CGVector
    }

    private final class Pickup {
        let node: SKSpriteNode
        let kind: PickupKind
        var life: TimeInterval = 8

        init(node: SKSpriteNode, kind: PickupKind) {
            self.node = node
            self.kind = kind
        }
    }

    // MARK: Layout constants (world points; the world node is scaled to fit the view)

    private let arena = CGSize(width: 720, height: 480)
    private let wall: CGFloat = 16
    private let doorWidth: CGFloat = 96
    private let playerRadius: CGFloat = 12
    private let characterScale: CGFloat = 2.5
    private let bulletRadius: CGFloat = 3

    // MARK: Nodes

    private let world = SKNode()
    private let player = SKNode()
    private let barrel = SKSpriteNode(color: .white, size: CGSize(width: 16, height: 4))
    private let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let roomLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let healthLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let xpBar = SKSpriteNode(color: .yellow, size: CGSize(width: 0, height: 4))
    private let bannerTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let bannerSubtitle = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    private let playerTexture = PixelArt.texture(PixelArt.player)
    private let gruntTexture = PixelArt.texture(PixelArt.grunt)
    private let bruiserTexture = PixelArt.texture(PixelArt.bruiser)
    private let bulletTexture = PixelArt.texture(PixelArt.bullet)
    private let cashTexture = PixelArt.texture(PixelArt.cash)
    private let spreadTexture = PixelArt.texture(PixelArt.spread)
    private let rapidTexture = PixelArt.texture(PixelArt.rapid)
    private let heartTexture = PixelArt.texture(PixelArt.heart)

    // MARK: Game state

    private let input = InputController()
    private var state = State.title
    private var stateTime: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    private var isBuilt = false

    private var enemies: [Enemy] = []
    private var bullets: [Bullet] = []
    private var pickups: [Pickup] = []

    private var score = 0
    private var health = 3
    private var maxHealth = 3
    private var level = 1
    private var xp = 0
    private let xpBarWidth: CGFloat = 90
    private let maxHealthCap = 10
    private var room = 1
    private var enemiesToSpawn = 0
    private var spawnTimer: TimeInterval = 0
    private var fireCooldown: TimeInterval = 0
    private var invulnerable: TimeInterval = 0
    private var spreadTime: TimeInterval = 0
    private var rapidTime: TimeInterval = 0

    #if os(macOS)
    private var keyMonitor: Any?
    #else
    private struct Stick {
        let origin: CGPoint
        let isMove: Bool
        let base: SKShapeNode
        let knob: SKShapeNode
    }

    private var sticks: [UITouch: Stick] = [:]
    private let stickRadius: CGFloat = 48
    #endif

    // MARK: Setup

    override func didMove(to view: SKView) {
        guard !isBuilt else { return }
        isBuilt = true
        backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)

        addChild(world)
        buildArena()
        buildPlayer()
        buildHUD()
        layoutWorld()
        showBanner("RATINGS WAR", startPrompt)

        #if os(macOS)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, !event.modifierFlags.contains(.command) else { return event }
            if event.type == .keyDown {
                self.input.pressedKeyCodes.insert(event.keyCode)
            } else {
                self.input.pressedKeyCodes.remove(event.keyCode)
            }
            return nil
        }
        #else
        view.isMultipleTouchEnabled = true
        #endif
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutWorld()
    }

    private func layoutWorld() {
        let fitWidth = arena.width + 2 * wall
        let fitHeight = arena.height + 2 * wall
        world.setScale(min(size.width / fitWidth, size.height / fitHeight))
        world.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private var startPrompt: String {
        #if os(macOS)
        "WASD to move  ·  arrow keys to fire  ·  press Space to start"
        #else
        "Left thumb moves  ·  right thumb fires  ·  tap to start"
        #endif
    }

    private func pixelSprite(_ texture: SKTexture, scale: CGFloat = PixelArt.pixelSize) -> SKSpriteNode {
        let pixels = texture.size()
        let size = CGSize(width: pixels.width * scale, height: pixels.height * scale)
        return SKSpriteNode(texture: texture, size: size)
    }

    private func buildArena() {
        let texture = PixelArt.arenaTexture(arena: arena, wall: wall, door: doorWidth)
        let backdrop = SKSpriteNode(
            texture: texture,
            size: CGSize(width: arena.width + 2 * wall, height: arena.height + 2 * wall)
        )
        backdrop.zPosition = -10
        world.addChild(backdrop)
    }

    private func buildPlayer() {
        let body = pixelSprite(playerTexture, scale: characterScale)
        barrel.anchorPoint = CGPoint(x: 0, y: 0.5)
        barrel.position = CGPoint(x: 0, y: -8)
        barrel.zPosition = 1
        player.addChild(body)
        player.addChild(barrel)
        player.zPosition = 10
        player.isHidden = true
        world.addChild(player)
    }

    private func buildHUD() {
        let y = arena.height / 2 - 24
        for label in [scoreLabel, roomLabel, healthLabel] {
            label.fontSize = 16
            label.zPosition = 40
            label.position.y = y
            world.addChild(label)
        }
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position.x = -arena.width / 2 + 14
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.position.x = arena.width / 2 - 14
        healthLabel.fontColor = SKColor(red: 1, green: 0.35, blue: 0.4, alpha: 1)

        let xpTrack = SKSpriteNode(color: SKColor(white: 0, alpha: 0.6), size: CGSize(width: xpBarWidth + 2, height: 6))
        xpTrack.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpTrack.position = CGPoint(x: -arena.width / 2 + 13, y: y - 10)
        xpTrack.zPosition = 40
        world.addChild(xpTrack)
        xpBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpBar.position = CGPoint(x: 1, y: 0)
        xpBar.zPosition = 1
        xpTrack.addChild(xpBar)

        bannerTitle.fontSize = 46
        bannerTitle.fontColor = .yellow
        bannerTitle.position = CGPoint(x: 0, y: 8)
        bannerTitle.zPosition = 50
        world.addChild(bannerTitle)

        bannerSubtitle.fontSize = 15
        bannerSubtitle.position = CGPoint(x: 0, y: -24)
        bannerSubtitle.zPosition = 50
        world.addChild(bannerSubtitle)

        for label in [scoreLabel, roomLabel, healthLabel, bannerTitle, bannerSubtitle] {
            addShadow(to: label)
        }
    }

    /// A hard black drop shadow, like 16-bit console text.
    private func addShadow(to label: SKLabelNode) {
        let shadow = SKLabelNode(fontNamed: label.fontName)
        shadow.name = "shadow"
        shadow.fontSize = label.fontSize
        shadow.fontColor = .black
        shadow.horizontalAlignmentMode = label.horizontalAlignmentMode
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        label.addChild(shadow)
    }

    private func setText(_ label: SKLabelNode, _ text: String) {
        label.text = text
        (label.childNode(withName: "shadow") as? SKLabelNode)?.text = text
    }

    // MARK: Flow

    private func setState(_ newState: State) {
        state = newState
        stateTime = 0
    }

    private func startGame() {
        enemies.forEach { $0.node.removeFromParent() }
        enemies.removeAll()
        pickups.forEach { $0.node.removeFromParent() }
        pickups.removeAll()
        score = 0
        health = 3
        maxHealth = 3
        level = 1
        xp = 0
        spreadTime = 0
        rapidTime = 0
        invulnerable = 2
        player.position = .zero
        player.isHidden = false
        startRoom(1)
    }

    private func startRoom(_ number: Int) {
        room = number
        bullets.forEach { $0.node.removeFromParent() }
        bullets.removeAll()
        enemiesToSpawn = 20 + 10 * number
        spawnTimer = 1
        setState(.playing)
        showBanner("ROOM \(number)", "Here they come!", hideAfter: 1.5)
        updateHUD()
    }

    private func roomCleared() {
        let bonus = 1000 * room
        score += bonus
        setState(.roomCleared)
        let lines = ["The crowd goes wild!", "Ratings are through the roof!", "What a show!", "The sponsors love you!"]
        showBanner("ROOM CLEARED", "\(lines.randomElement()!)  +\(bonus)")
        updateHUD()
    }

    private func gameOver() {
        player.isHidden = true
        setState(.gameOver)
        #if os(macOS)
        let prompt = "Press Space to play again"
        #else
        let prompt = "Tap to play again"
        #endif
        showBanner("CANCELLED", "Final score \(score)  ·  \(prompt)")
    }

    private func showBanner(_ title: String, _ subtitle: String, hideAfter delay: TimeInterval? = nil) {
        for (label, text) in [(bannerTitle, title), (bannerSubtitle, subtitle)] {
            label.removeAllActions()
            setText(label, text)
            label.alpha = 1
            if let delay {
                label.run(.sequence([.wait(forDuration: delay), .fadeOut(withDuration: 0.3)]))
            }
        }
    }

    private func updateHUD() {
        setText(scoreLabel, "$\(score)")
        setText(roomLabel, "ROOM \(room)  ·  LV \(level)")
        let filled = max(health, 0)
        setText(healthLabel, String(repeating: "♥", count: filled) + String(repeating: "♡", count: maxHealth - filled))
        xpBar.size.width = xpBarWidth * CGFloat(xp) / CGFloat(xpToNextLevel)
    }

    /// Each level takes 10 more kills' worth of XP than the last.
    private var xpToNextLevel: Int {
        5 + 10 * level
    }

    private func gainXP(_ amount: Int) {
        xp += amount
        while xp >= xpToNextLevel {
            xp -= xpToNextLevel
            level += 1
            maxHealth = min(maxHealth + 1, maxHealthCap)
            health = maxHealth
            floatText("LEVEL UP!", at: player.position)
            burst(at: player.position, color: .yellow, count: 14)
        }
    }

    private func floatText(_ text: String, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 14
        label.fontColor = .yellow
        label.position = CGPoint(x: position.x, y: position.y + 24)
        label.zPosition = 45
        world.addChild(label)
        addShadow(to: label)
        setText(label, text)
        let rise = SKAction.moveBy(x: 0, y: 30, duration: 0.9)
        label.run(.sequence([.group([rise, .sequence([.wait(forDuration: 0.6), .fadeOut(withDuration: 0.3)])]), .removeFromParent()]))
    }

    // MARK: Frame update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, 1.0 / 30)
        lastTime = currentTime
        stateTime += dt
        input.poll()
        let confirm = input.consumeConfirm()

        switch state {
        case .title:
            if confirm { startGame() }
        case .gameOver:
            // Short lockout so mashing fire doesn't skip the score.
            if confirm && stateTime > 1 { startGame() }
        case .playing:
            step(dt)
            if state == .playing && enemiesToSpawn == 0 && enemies.isEmpty {
                roomCleared()
            }
        case .roomCleared:
            step(dt)
            if state == .roomCleared && stateTime > 3 {
                startRoom(room + 1)
            }
        }
    }

    private func step(_ dt: TimeInterval) {
        updatePlayer(dt)
        updateBullets(dt)
        if state == .playing {
            updateSpawning(dt)
        }
        updateEnemies(dt)
        updatePickups(dt)
    }

    private func updatePlayer(_ dt: TimeInterval) {
        let halfWidth = arena.width / 2 - playerRadius
        let halfHeight = arena.height / 2 - playerRadius
        var position = player.position + input.move * (200 * dt)
        position.x = min(max(position.x, -halfWidth), halfWidth)
        position.y = min(max(position.y, -halfHeight), halfHeight)
        player.position = position

        invulnerable = max(0, invulnerable - dt)
        spreadTime = max(0, spreadTime - dt)
        rapidTime = max(0, rapidTime - dt)
        player.alpha = invulnerable > 0 && Int(invulnerable * 10) % 2 == 0 ? 0.35 : 1
        barrel.color = spreadTime > 0 ? .orange : (rapidTime > 0 ? .green : .white)

        fireCooldown -= dt
        let aim = input.fire
        guard aim != .zero else { return }
        barrel.zRotation = atan2(aim.dy, aim.dx)
        guard fireCooldown <= 0 else { return }
        fireCooldown = rapidTime > 0 ? 0.06 : 0.13

        let angles: [CGFloat] = spreadTime > 0 ? [-0.2, 0, 0.2] : [0]
        let base = atan2(aim.dy, aim.dx)
        for offset in angles {
            let direction = CGVector(dx: cos(base + offset), dy: sin(base + offset))
            let node = pixelSprite(bulletTexture)
            node.position = player.position + direction * (playerRadius + 6)
            node.zPosition = 5
            world.addChild(node)
            bullets.append(Bullet(node: node, velocity: direction * 540))
        }
    }

    private func updateBullets(_ dt: TimeInterval) {
        for bulletIndex in bullets.indices.reversed() {
            let bullet = bullets[bulletIndex]
            let position = bullet.node.position + bullet.velocity * dt
            bullet.node.position = position

            var spent = abs(position.x) > arena.width / 2 || abs(position.y) > arena.height / 2
            if !spent {
                for enemyIndex in enemies.indices.reversed() {
                    let enemy = enemies[enemyIndex]
                    guard (enemy.node.position - position).length < enemy.radius + bulletRadius else { continue }
                    spent = true
                    enemy.hp -= 1
                    if enemy.hp <= 0 {
                        enemies.remove(at: enemyIndex)
                        kill(enemy)
                    } else {
                        enemy.node.run(.sequence([.fadeAlpha(to: 0.4, duration: 0.03), .fadeAlpha(to: 1, duration: 0.06)]))
                    }
                    break
                }
            }
            if spent {
                bullet.node.removeFromParent()
                bullets.remove(at: bulletIndex)
            }
        }
    }

    private func kill(_ enemy: Enemy) {
        score += enemy.points
        gainXP(enemy.points / 100)
        burst(at: enemy.node.position, color: enemy.radius > 15 ? .purple : .red)
        enemy.node.removeFromParent()

        let roll = Int.random(in: 0..<100)
        if roll < 10 {
            dropPickup(.cash, at: enemy.node.position)
        } else if roll < 13 {
            dropPickup(.spread, at: enemy.node.position)
        } else if roll < 16 {
            dropPickup(.rapid, at: enemy.node.position)
        } else if roll < 19 {
            dropPickup(.heart, at: enemy.node.position)
        }
        updateHUD()
    }

    private func updateSpawning(_ dt: TimeInterval) {
        guard enemiesToSpawn > 0 else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0, enemies.count < 70 else { return }
        spawnTimer = max(0.5, 1.3 - Double(room) * 0.08)

        let door = Int.random(in: 0..<4)
        let count = min(enemiesToSpawn, min(8, 3 + room / 2))
        enemiesToSpawn -= count
        for _ in 0..<count {
            let along = CGFloat.random(in: -(doorWidth / 2 - 14)...(doorWidth / 2 - 14))
            let inset = CGFloat.random(in: 6...30)
            let position: CGPoint
            switch door {
            case 0: position = CGPoint(x: along, y: arena.height / 2 - inset)
            case 1: position = CGPoint(x: along, y: -arena.height / 2 + inset)
            case 2: position = CGPoint(x: -arena.width / 2 + inset, y: along)
            default: position = CGPoint(x: arena.width / 2 - inset, y: along)
            }

            let enemy: Enemy
            if room >= 2 && Int.random(in: 0..<100) < 15 {
                enemy = Enemy(node: pixelSprite(bruiserTexture, scale: characterScale), hp: 4, speed: 48, radius: 19, points: 300)
            } else {
                let speed = min(110, 60 + CGFloat(room) * 4) + CGFloat.random(in: -10...10)
                enemy = Enemy(node: pixelSprite(gruntTexture, scale: characterScale), hp: 1, speed: speed, radius: 12, points: 100)
            }
            enemy.node.position = position
            enemy.node.zPosition = 4
            world.addChild(enemy.node)
            enemies.append(enemy)
        }
    }

    private func updateEnemies(_ dt: TimeInterval) {
        var playerWasHit = false
        for enemy in enemies {
            let toPlayer = player.position - enemy.node.position
            let distance = toPlayer.length
            if distance > 1 {
                // Sway a little so a mob spreads out instead of stacking into one dot.
                let sway = sin(CGFloat(stateTime) * 3 + enemy.wobble) * 0.5
                let heading = atan2(toPlayer.dy, toPlayer.dx) + sway
                enemy.node.position = enemy.node.position + CGVector(dx: cos(heading), dy: sin(heading)) * (enemy.speed * dt)
                // Flip back and forth for a two-frame waddle.
                enemy.node.xScale = sin(CGFloat(stateTime) * 12 + enemy.wobble) > 0 ? 1 : -1
            }
            if !player.isHidden && invulnerable <= 0 && distance < enemy.radius + playerRadius - 2 {
                playerWasHit = true
            }
        }
        if playerWasHit {
            loseLife()
        }
    }

    private func loseLife() {
        health -= 1
        burst(at: player.position, color: .cyan, count: 16)
        // Clear the mob around the respawn point so the player gets a fair restart.
        enemies.removeAll { enemy in
            guard (enemy.node.position - player.position).length < 130 else { return false }
            burst(at: enemy.node.position, color: .red)
            enemy.node.removeFromParent()
            return true
        }
        spreadTime = 0
        rapidTime = 0
        invulnerable = 2.5
        updateHUD()
        if health <= 0 {
            gameOver()
        }
    }

    private func dropPickup(_ kind: PickupKind, at position: CGPoint) {
        let texture: SKTexture
        switch kind {
        case .cash: texture = cashTexture
        case .heart: texture = heartTexture
        case .spread: texture = spreadTexture
        case .rapid: texture = rapidTexture
        }
        let node = pixelSprite(texture)
        node.position = position
        node.zPosition = 3
        world.addChild(node)
        pickups.append(Pickup(node: node, kind: kind))
    }

    private func updatePickups(_ dt: TimeInterval) {
        for index in pickups.indices.reversed() {
            let pickup = pickups[index]
            pickup.life -= dt
            pickup.node.alpha = pickup.life < 2 && Int(pickup.life * 8) % 2 == 0 ? 0.3 : 1

            let collected = !player.isHidden && (pickup.node.position - player.position).length < playerRadius + 14
            if collected {
                switch pickup.kind {
                case .cash: score += 1000
                case .heart: health = min(health + 1, maxHealth)
                case .spread: spreadTime = 10
                case .rapid: rapidTime = 10
                }
                updateHUD()
            }
            if collected || pickup.life <= 0 {
                pickup.node.removeFromParent()
                pickups.remove(at: index)
            }
        }
    }

    private func burst(at position: CGPoint, color: SKColor, count: Int = 6) {
        for _ in 0..<count {
            let bit = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            bit.position = position
            bit.zPosition = 6
            world.addChild(bit)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 14...36)
            let fly = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.3)
            bit.run(.sequence([.group([fly, .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        }
    }

    // MARK: Platform input

    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        input.requestConfirm()
    }
    #else
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard state == .playing || state == .roomCleared else {
                input.requestConfirm()
                continue
            }
            let point = touch.location(in: self)
            let isMove = point.x < size.width / 2
            guard !sticks.values.contains(where: { $0.isMove == isMove }) else { continue }

            let base = SKShapeNode(circleOfRadius: stickRadius)
            base.strokeColor = SKColor(white: 1, alpha: 0.25)
            base.fillColor = SKColor(white: 1, alpha: 0.06)
            base.lineWidth = 2
            base.position = point
            base.zPosition = 100
            addChild(base)

            let knob = SKShapeNode(circleOfRadius: 20)
            knob.strokeColor = .clear
            knob.fillColor = (isMove ? SKColor.cyan : SKColor.yellow).withAlphaComponent(0.45)
            knob.position = point
            knob.zPosition = 101
            addChild(knob)

            sticks[touch] = Stick(origin: point, isMove: isMove, base: base, knob: knob)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let stick = sticks[touch] else { continue }
            var offset = touch.location(in: self) - stick.origin
            if offset.length > stickRadius {
                offset = offset * (stickRadius / offset.length)
            }
            stick.knob.position = stick.origin + offset
            if stick.isMove {
                input.touchMove = offset / stickRadius
            } else {
                input.touchFire = offset / stickRadius
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let stick = sticks.removeValue(forKey: touch) else { continue }
            stick.base.removeFromParent()
            stick.knob.removeFromParent()
            if stick.isMove {
                input.touchMove = .zero
            } else {
                input.touchFire = .zero
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    #endif
}
