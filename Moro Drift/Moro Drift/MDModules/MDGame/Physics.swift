import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Injected HUD state
    private let state: GameState
    init(size: CGSize, state: GameState) {
        self.state = state
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Physics categories
    struct Cat {
        static let unit:   UInt32 = 1 << 0
        static let ground: UInt32 = 1 << 1
        static let player: UInt32 = 1 << 2
        static let bullet: UInt32 = 1 << 3
        static let hole:   UInt32 = 1 << 4
        static let bonus:  UInt32 = 1 << 5
    }

    // MARK: Config
    private let topHoleWidth: CGFloat = 100
    private let bottomHoleWidth: CGFloat = 120
    private let wallThickness: CGFloat = 24
    private let platformHeight: CGFloat = 12
    private let unitSize = CGSize(width: 18, height: 32)
    private let unitSpeedX: CGFloat = 160
    private let playerSize = CGSize(width: 24, height: 36)
    private let playerMoveSpeed: CGFloat = 220
    private let playerJumpImpulse: CGFloat = 360
    private let bulletSpeed: CGFloat = 520
    private let bulletSize = CGSize(width: 10, height: 4)

    // MARK: State
    private var player: PlayerNode!
    private var moveLeft = false
    private var moveRight = false
    private var spawnActionKey = "spawnLoop"
    private var lastShotTime: TimeInterval = 0
    private var sceneTime: TimeInterval = 0
    private var baseTime: TimeInterval? = nil
    
    private var fireCooldown: TimeInterval {
        if case .some(let ab) = state.activeBonus, ab.kind == .rapidFire { return 0.12 }
        return 0.35
    }
    private var shieldActive: Bool {
        if case .some(let ab) = state.activeBonus, ab.kind == .shield { return true }
        return false
    }

    private var bottomHoleCenterX: CGFloat { size.width * 0.5 }
    private var topHoleCenterX: CGFloat { size.width * 0.5 }

    // MARK: Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -980)
        physicsWorld.contactDelegate = self

        buildWorld()
        spawnPlayer()
        startSpawning()
    }

    // MARK: World
    private func buildWorld() {
        removeAllChildren()
        
        addStaticBox(rect: CGRect(x: 0, y: 0, width: wallThickness, height: size.height),
                     name: "leftWall", textureName: "wall_vert")
        addStaticBox(rect: CGRect(x: size.width - wallThickness, y: 0, width: wallThickness, height: size.height),
                     name: "rightWall", textureName: "wall_vert")
        
        // Верх: дыра 100
        let topY = size.height - wallThickness
        let tHoleLeftX = (size.width - topHoleWidth) / 2
        let tHoleRightX = tHoleLeftX + topHoleWidth
        addStaticBox(rect: CGRect(x: 0, y: topY, width: tHoleLeftX, height: wallThickness),
                     name: "topWallLeft", textureName: "wall_horz")
        addStaticBox(rect: CGRect(x: tHoleRightX, y: topY, width: size.width - tHoleRightX, height: wallThickness),
                     name: "topWallRight", textureName: "wall_horz")
        
        // Низ: дыра 120
        let bottomY: CGFloat = 0
        let bHoleLeftX = (size.width - bottomHoleWidth) / 2
        let bHoleRightX = bHoleLeftX + bottomHoleWidth
        addStaticBox(rect: CGRect(x: 0, y: bottomY, width: bHoleLeftX, height: wallThickness),
                     name: "bottomWallLeft", textureName: "wall_horz")
        addStaticBox(rect: CGRect(x: bHoleRightX, y: bottomY, width: size.width - bHoleRightX, height: wallThickness),
                     name: "bottomWallRight", textureName: "wall_horz")
        
        // Платформа
        let platformWidth = size.width * 0.65
        let platformRect = CGRect(x: (size.width - platformWidth)/2,
                                  y: (size.height - platformHeight)/2,
                                  width: platformWidth,
                                  height: platformHeight)
        addStaticBox(rect: platformRect, name: "platform", textureName: "platform")
    }

    private func addStaticBox(rect: CGRect, name: String, textureName: String?) {
        let node: SKSpriteNode
        if let tn = textureName {
            let tex = SKTexture(imageNamed: tn)
            tex.filteringMode = .nearest
            node = SKSpriteNode(texture: tex, color: .clear, size: rect.size)
        } else {
            node = SKSpriteNode(color: .white.withAlphaComponent(0.12), size: rect.size)
        }
        node.position = CGPoint(x: rect.midX, y: rect.midY)
        node.name = name

        let body = SKPhysicsBody(rectangleOf: rect.size)
        body.isDynamic = false
        body.friction = 0.0
        body.restitution = 0.0
        body.categoryBitMask = Cat.ground
        body.contactTestBitMask = Cat.unit | Cat.player
        body.collisionBitMask = Cat.unit | Cat.player
        node.physicsBody = body

        addChild(node)
    }

    // MARK: Player
    private func spawnPlayer() {
        let p = PlayerNode(size: playerSize, textureName: "hero")
        p.position = CGPoint(x: size.width * 0.25,
                             y: wallThickness + playerSize.height * 0.5 + 2)
        let body = SKPhysicsBody(rectangleOf: playerSize)
        body.affectedByGravity = true
        body.allowsRotation = false
        body.friction = 0.0
        body.restitution = 0.0
        body.linearDamping = 0.05
        body.categoryBitMask = Cat.player
        body.contactTestBitMask = Cat.ground | Cat.unit | Cat.bonus
        body.collisionBitMask = Cat.ground | Cat.unit
        p.physicsBody = body
        addChild(p)
        player = p
        updatePlayerTintForBonus()
    }

    // MARK: Units & Bonuses
    private func spawnUnitAtTopHole() {
        let minX = topHoleCenterX - topHoleWidth/2
        let maxX = topHoleCenterX + topHoleWidth/2
        let x = CGFloat.random(in: minX...maxX)
        let y = size.height + unitSize.height
        let unit = UnitNode(size: unitSize, textureName: "enemy")
        unit.position = CGPoint(x: x, y: y)

        let body = SKPhysicsBody(rectangleOf: unitSize)
        body.affectedByGravity = true
        body.allowsRotation = false
        body.friction = 0.0
        body.restitution = 0.0
        body.linearDamping = 0.05
        body.categoryBitMask = Cat.unit
        body.contactTestBitMask = Cat.ground | Cat.bullet | Cat.hole | Cat.player
        body.collisionBitMask = Cat.ground | Cat.player
        unit.physicsBody = body

        // изначально смотрим вниз-вправо (как угодно) — потом скорректируем при выборе направления
        unit.xScale = 1
        addChild(unit)
    }

    private func spawnBonusCrateMaybe() {
        guard Int.random(in: 0..<8) == 0 else { return } // 12.5%

        let minX = topHoleCenterX - topHoleWidth/2
        let maxX = topHoleCenterX + topHoleWidth/2
        let x = CGFloat.random(in: minX...maxX)
        let y = size.height + 24

        let crate = SKShapeNode(rectOf: CGSize(width: 18, height: 18), cornerRadius: 3)
        crate.fillColor = .systemTeal
        crate.strokeColor = .clear
        crate.name = "bonus"
        crate.position = CGPoint(x: x, y: y)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 18))
        body.affectedByGravity = true
        body.allowsRotation = false
        body.friction = 0.1
        body.restitution = 0.0
        body.linearDamping = 0.1
        body.categoryBitMask = Cat.bonus
        body.contactTestBitMask = Cat.player | Cat.ground | Cat.hole
        body.collisionBitMask = Cat.ground
        crate.physicsBody = body

        addChild(crate)
    }

    func startSpawning() {
        guard action(forKey: spawnActionKey) == nil else { return }
        let step = SKAction.run { [weak self] in
            self?.spawnUnitAtTopHole()
            self?.spawnBonusCrateMaybe()
        }
        run(.repeatForever(.sequence([step, .wait(forDuration: 0.8)])), withKey: spawnActionKey)
    }
    func stopSpawning() { removeAction(forKey: spawnActionKey) }

    // MARK: Input API
    func startMoveLeft()  { moveLeft = true;  player?.facing = .left  }
    func stopMoveLeft()   { moveLeft = false }
    func startMoveRight() { moveRight = true; player?.facing = .right }
    func stopMoveRight()  { moveRight = false }

    func playerJump() {
        guard let p = player, let body = p.physicsBody else { return }
        if isPlayerOnGround() {
            if body.velocity.dy < 0 { body.velocity.dy = 0 }
            body.applyImpulse(CGVector(dx: 0, dy: playerJumpImpulse))
        }
    }

    func playerShoot() {
        guard !state.isGameOver, let p = player else { return }
        let now = sceneTime
        if now - lastShotTime < fireCooldown { return }
        lastShotTime = now

        let dir: CGFloat = (p.facing == .right) ? 1 : -1
        let bullet = SKShapeNode(rectOf: bulletSize, cornerRadius: 1.5)
        bullet.fillColor = .white
        bullet.strokeColor = .clear
        bullet.name = "bullet"
        bullet.position = CGPoint(
            x: p.position.x + dir * (p.size.width/2 + bulletSize.width/2 + 2),
            y: p.position.y + p.size.height * 0.1
        )

        let body = SKPhysicsBody(rectangleOf: bulletSize)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.friction = 0.0
        body.linearDamping = 0.0
        body.categoryBitMask = Cat.bullet
        body.contactTestBitMask = Cat.unit
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: bulletSpeed * dir, dy: 0)
        bullet.physicsBody = body

        addChild(bullet)
        bullet.run(.sequence([.wait(forDuration: 2.0), .removeFromParent()]))
    }

    func resetWorld() {
        stopSpawning()
        removeAllActions()

        enumerateChildNodes(withName: "unit")   { n, _ in n.removeFromParent() }
        enumerateChildNodes(withName: "bullet") { n, _ in n.removeFromParent() }
        enumerateChildNodes(withName: "bonus")  { n, _ in n.removeFromParent() }
        player?.removeFromParent()

        baseTime = nil
        state.reset()
        lastShotTime = 0

        buildWorld()
        spawnPlayer()
        startSpawning()
        sceneTime = 0
    }

    // MARK: Contacts
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        // Юниты: выбор направления
        if let unit = a.node as? UnitNode, (b.categoryBitMask & Cat.ground) != 0 {
            handleUnitGroundContact(unit: unit, other: b.node)
        } else if let unit = b.node as? UnitNode, (a.categoryBitMask & Cat.ground) != 0 {
            handleUnitGroundContact(unit: unit, other: a.node)
        }

        // Пуля попала во врага → очки + убийство
        if (a.categoryBitMask & Cat.bullet) != 0, let unit = b.node as? UnitNode {
            a.node?.removeFromParent(); destroyUnit(unit)
        } else if (b.categoryBitMask & Cat.bullet) != 0, let unit = a.node as? UnitNode {
            b.node?.removeFromParent(); destroyUnit(unit)
        }

        // Враг касается игрока → смерть (если нет щита)
        if let _ = a.node as? UnitNode, (b.categoryBitMask & Cat.player) != 0 {
            if !shieldActive { killPlayer() }
        } else if let _ = b.node as? UnitNode, (a.categoryBitMask & Cat.player) != 0 {
            if !shieldActive { killPlayer() }
        }

        // Враг достиг сенсора дыры → пропуск
        if (a.categoryBitMask & Cat.hole) != 0, let unit = b.node as? UnitNode {
            unit.didCountMiss = true
            unit.removeFromParent()
            registerMiss()
        } else if (b.categoryBitMask & Cat.hole) != 0, let unit = a.node as? UnitNode {
            unit.didCountMiss = true
            unit.removeFromParent()
            registerMiss()
        }

        // Игрок подобрал бонус
        if (a.categoryBitMask & Cat.player) != 0, (b.categoryBitMask & Cat.bonus) != 0 {
            b.node?.removeFromParent(); grantRandomBonus()
        } else if (b.categoryBitMask & Cat.player) != 0, (a.categoryBitMask & Cat.bonus) != 0 {
            a.node?.removeFromParent(); grantRandomBonus()
        }
    }

    private func handleUnitGroundContact(unit: UnitNode, other: SKNode?) {
        if (other?.name?.contains("platform") ?? false), unit.moveDir == nil {
            let dir: CGFloat = unit.position.x < bottomHoleCenterX ? 1 : -1
            unit.moveDir = dir
            unit.applyFacingFromMoveDir()      // <-- флип спрайта
            unit.physicsBody?.velocity.dx = 0
            unit.physicsBody?.applyImpulse(CGVector(dx: 10 * dir, dy: 0))
            return
        }
        if (other?.name?.contains("bottomWall") ?? false) {
            let dir: CGFloat = unit.position.x < bottomHoleCenterX ? 1 : -1
            unit.moveDir = dir
            unit.applyFacingFromMoveDir()      // <-- флип спрайта
            if let body = unit.physicsBody, abs(body.velocity.dx) < 20 {
                body.velocity.dx = 0
                body.applyImpulse(CGVector(dx: 12 * dir, dy: 0))
            }
        }
    }

    // MARK: Events
    private func destroyUnit(_ unit: UnitNode) {
        unit.removeFromParent()
        state.kills += 1          // <— добавили убийства
        state.score += 10         // <— добавили очки
    }

    private func killPlayer() {
        guard !state.isGameOver, player.parent != nil else { return }
        state.lives -= 1
        player.removeFromParent()
        if state.lives <= 0 { gameOver(); return }
        run(.sequence([
            .wait(forDuration: 0.6),
            .run { [weak self] in self?.spawnPlayer() }
        ]))
    }

    private func registerMiss() {
        guard !state.isGameOver else { return }
        state.missesLeft -= 1
        if state.missesLeft <= 0 { gameOver() }
    }

    private func grantRandomBonus() {
        let kind: GameState.BonusKind = (Bool.random() ? .rapidFire : .shield)
        state.activeBonus = .init(kind: kind, timeLeft: kind.duration)
        updatePlayerTintForBonus()
    }

    private func updatePlayerTintForBonus() {
        guard let p = player else { return }
        if (state.activeBonus?.kind == .shield) { p.color = .systemGreen; p.colorBlendFactor = 0.6 }
        else                                     { p.color = .systemYellow; p.colorBlendFactor = 1.0 }
    }

    private func gameOver() {
        state.isGameOver = true
        state.finishRun()
        stopSpawning()
        enumerateChildNodes(withName: "unit")   { n, _ in n.removeFromParent() }
        enumerateChildNodes(withName: "bullet") { n, _ in n.removeFromParent() }
        enumerateChildNodes(withName: "bonus")  { n, _ in n.removeFromParent() }
        player?.removeFromParent()
    }

    // MARK: Update loop
    override func update(_ currentTime: TimeInterval) {
        sceneTime = currentTime
        if baseTime == nil {
            baseTime = currentTime
            state.startRun(at: currentTime)   // запустили забег ровно с текущего времени
        }
        
        state.tick(now: currentTime) // обновляем таймер на HUD
        
        
        // Игрок — движение
        if let body = player?.physicsBody {
            let dir: CGFloat = (moveLeft ? -1 : 0) + (moveRight ? 1 : 0)
            if dir != 0 { player.facing = (dir > 0) ? .right : .left }
            let vx = playerMoveSpeed * dir
            let vy = max(min(body.velocity.dy, 800), -800)
            body.velocity = CGVector(dx: vx, dy: vy)
        }
        
        
        // Бонус таймер
        if var ab = state.activeBonus, !state.isGameOver {
            ab.timeLeft -= 1.0 / 60.0
            state.activeBonus = (ab.timeLeft > 0) ? ab : nil
            if state.activeBonus == nil { updatePlayerTintForBonus() }
        }
        
        // Юниты — держим постоянный vx
        let maxVy: CGFloat = 600
        let holeLeftX  = (size.width - bottomHoleWidth) / 2
        let holeRightX = holeLeftX + bottomHoleWidth
        let holeTopY   = wallThickness + 2  // верх сенсора/отверстия
        enumerateChildNodes(withName: "unit") { node, _ in
            guard let u = node as? UnitNode, let body = u.physicsBody else { return }
            
            if let dir = u.moveDir {
                body.velocity = CGVector(dx: self.unitSpeedX * dir,
                                         dy: max(min(body.velocity.dy, 600), -600))
            }
            
            // === НАДЁЖНЫЙ УЧЁТ ПРОПУСКА ===
            if !u.didCountMiss,
               u.position.y <= holeTopY,
               u.position.x >= holeLeftX, u.position.x <= holeRightX
            {
                u.didCountMiss = true
                u.removeFromParent()
                self.registerMiss()
                return
            }
            
            // чистка далеко за экраном (без регистрация miss)
            if u.position.y < -500 || u.position.y > self.size.height + 500 ||
                u.position.x < -500 || u.position.x > self.size.width + 500 {
                u.removeFromParent()
            }
        }
    }
    
    // MARK: Ground ray
    private func isPlayerOnGround() -> Bool {
        guard let p = player else { return false }
        return rayHitsGround(from: CGPoint(x: p.position.x, y: p.frame.minY - 1),
                             to:   CGPoint(x: p.position.x, y: p.frame.minY - 8))
    }
    private func rayHitsGround(from start: CGPoint, to end: CGPoint) -> Bool {
        if let hit = physicsWorld.body(alongRayStart: start, end: end) {
            return (hit.categoryBitMask & Cat.ground) != 0
        }
        return false
    }
}

// MARK: Nodes

final class UnitNode: SKSpriteNode {
    var moveDir: CGFloat? = nil // -1 / +1
    var didCountMiss = false
    
    init(size: CGSize, textureName: String?) {
        if let tn = textureName {
            let tex = SKTexture(imageNamed: tn)
            super.init(texture: tex, color: .clear, size: size)
        } else {
            super.init(texture: nil, color: .white, size: size)
        }
        zPosition = 10
        name = "unit"
        // изначально смотрим вправо
        xScale = 1
        yScale = 1
    }

    func applyFacingFromMoveDir() {
        guard let dir = moveDir else { return }
        let s = abs(xScale)
        xScale = dir >= 0 ? s : -s
    }

    required init?(coder: NSCoder) { fatalError() }
}

final class PlayerNode: SKSpriteNode {
    enum Facing { case left, right }
    var facing: Facing = .right {
        didSet { applyFacing() }
    }

    init(size: CGSize, textureName: String?) {
        if let tn = textureName {
            let tex = SKTexture(imageNamed: tn)
            super.init(texture: tex, color: .clear, size: size)
        } else {
            super.init(texture: nil, color: .systemYellow, size: size)
        }
        zPosition = 20
        name = "player"
        colorBlendFactor = 1.0
        xScale = 1
        yScale = 1
    }

    private func applyFacing() {
        let s = abs(xScale)
        xScale = (facing == .right) ? s : -s
    }

    required init?(coder: NSCoder) { fatalError() }
}
