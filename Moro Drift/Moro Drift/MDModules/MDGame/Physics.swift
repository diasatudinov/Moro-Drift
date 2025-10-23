import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    
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
    
    // бонусы
    enum BonusKind {
        case rapidFire, shield
        var label: String {
            switch self {
            case .rapidFire: return "Rapid Fire"
            case .shield:    return "Shield"
            }
        }
        var duration: TimeInterval { 8 }
    }
    
    // MARK: State (HUD/public)
    private(set) var score: Int = 0
    private(set) var lives: Int = 3
    private let maxMisses: Int = 5
    private(set) var missesLeft: Int = 5
    private(set) var isGameOver: Bool = false
    
    // активный бонус
    private(set) var activeBonus: (kind: BonusKind, timeLeft: TimeInterval)? = nil
    
    // внутреннее
    private var player: PlayerNode!
    private var moveLeft = false
    private var moveRight = false
    private var spawnActionKey = "spawnLoop"
    private var lastShotTime: TimeInterval = 0
    private var fireCooldown: TimeInterval { // зависит от бонуса
        if let bonus = activeBonus, bonus.kind == .rapidFire { return 0.12 }
        return 0.35
    }
    private var shieldActive: Bool { activeBonus?.kind == .shield }
    
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
    
    // MARK: World build
    private func buildWorld() {
        removeAllChildren()
        
        // Боковые стены
        addStaticBox(rect: CGRect(x: 0, y: 0, width: wallThickness, height: size.height), name: "leftWall")
        addStaticBox(rect: CGRect(x: size.width - wallThickness, y: 0, width: wallThickness, height: size.height), name: "rightWall")
        
        // Верхняя стена с дырой (100)
        let topY = size.height - wallThickness
        let tHoleLeftX = (size.width - topHoleWidth) / 2
        let tHoleRightX = tHoleLeftX + topHoleWidth
        addStaticBox(rect: CGRect(x: 0, y: topY, width: tHoleLeftX, height: wallThickness), name: "topWallLeft")
        addStaticBox(rect: CGRect(x: tHoleRightX, y: topY, width: size.width - tHoleRightX, height: wallThickness), name: "topWallRight")
        
        // Нижняя стена с дырой (120)
        let bottomY: CGFloat = 0
        let bHoleLeftX = (size.width - bottomHoleWidth) / 2
        let bHoleRightX = bHoleLeftX + bottomHoleWidth
        addStaticBox(rect: CGRect(x: 0, y: bottomY, width: bHoleLeftX, height: wallThickness), name: "bottomWallLeft")
        addStaticBox(rect: CGRect(x: bHoleRightX, y: bottomY, width: size.width - bHoleRightX, height: wallThickness), name: "bottomWallRight")
        
        // Сенсор дыры (невидимый, без коллизий, только контакты)
        let holeRect = CGRect(x: bHoleLeftX, y: bottomY, width: bottomHoleWidth, height: wallThickness + 2)
        let holeSensor = SKNode()
        holeSensor.name = "holeSensor"
        let holeBody = SKPhysicsBody(rectangleOf: holeRect.size, center: CGPoint(x: holeRect.midX, y: holeRect.midY))
        holeBody.isDynamic = false
        holeBody.categoryBitMask = Cat.hole
        holeBody.contactTestBitMask = Cat.unit
        holeBody.collisionBitMask = 0
        holeSensor.physicsBody = holeBody
        addChild(holeSensor)
        
        // Центральная платформа
        let platformWidth = size.width * 0.65
        let platformRect = CGRect(x: (size.width - platformWidth)/2,
                                  y: (size.height - platformHeight)/2,
                                  width: platformWidth,
                                  height: platformHeight)
        addStaticBox(rect: platformRect, name: "platform")
    }
    
    private func addStaticBox(rect: CGRect, name: String) {
        let node = SKSpriteNode(color: .white.withAlphaComponent(0.12), size: rect.size)
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
        let p = PlayerNode(size: playerSize)
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
    }
    
    // MARK: Units & Bonuses
    private func spawnUnitAtTopHole() {
        let minX = topHoleCenterX - topHoleWidth/2
        let maxX = topHoleCenterX + topHoleWidth/2
        let x = CGFloat.random(in: minX...maxX)
        let y = size.height + unitSize.height
        let unit = UnitNode(size: unitSize)
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
        addChild(unit)
    }
    
    private func spawnBonusCrateMaybe() {
        // ~12.5% шанс на ящик
        guard Int.random(in: 0..<8) == 0 else { return }
        
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
        run(.repeatForever(.sequence([step, .wait(forDuration: 0.8)])),
            withKey: spawnActionKey)
    }
    
    func stopSpawning() { removeAction(forKey: spawnActionKey) }
    
    // MARK: Input API (SwiftUI)
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
        guard !isGameOver, let p = player else { return }
        
        let now = CACurrentMediaTime()          // <-- вместо view.scene?.currentTime
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
        
        enumerateChildNodes(withName: "unit") { node, _ in node.removeFromParent() }
        enumerateChildNodes(withName: "bullet") { node, _ in node.removeFromParent() }
        enumerateChildNodes(withName: "bonus") { node, _ in node.removeFromParent() }
        player?.removeFromParent()
        
        score = 0
        lives = 3
        missesLeft = maxMisses
        isGameOver = false
        activeBonus = nil
        lastShotTime = 0
        
        buildWorld()
        spawnPlayer()
        startSpawning()
    }
    
    // MARK: Contacts
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        
        // Юниты vs земля → передаём куда именно врезались
        if let unit = a.node as? UnitNode, (b.categoryBitMask & Cat.ground) != 0 {
            handleUnitGroundContact(unit: unit, other: b.node)
        } else if let unit = b.node as? UnitNode, (a.categoryBitMask & Cat.ground) != 0 {
            handleUnitGroundContact(unit: unit, other: a.node)
        }
        
        // Bullet vs Unit → очки
        if (a.categoryBitMask & Cat.bullet) != 0, let unit = b.node as? UnitNode {
            a.node?.removeFromParent(); destroyUnit(unit)
        } else if (b.categoryBitMask & Cat.bullet) != 0, let unit = a.node as? UnitNode {
            b.node?.removeFromParent(); destroyUnit(unit)
        }
        
        // Unit touches Player → смерть игрока (если нет щита)
        if let unit = a.node as? UnitNode, (b.categoryBitMask & Cat.player) != 0 {
            if !shieldActive { killPlayer() }
            // Юнита не удаляем — это враг
        } else if let unit = b.node as? UnitNode, (a.categoryBitMask & Cat.player) != 0 {
            if !shieldActive { killPlayer() }
        }
        
        // Unit reaches hole sensor → пропуск
        if (a.categoryBitMask & Cat.hole) != 0, let unit = b.node as? UnitNode {
            unit.removeFromParent(); registerMiss()
        } else if (b.categoryBitMask & Cat.hole) != 0, let unit = a.node as? UnitNode {
            unit.removeFromParent(); registerMiss()
        }
        
        // Player picks bonus
        if (a.categoryBitMask & Cat.player) != 0, (b.categoryBitMask & Cat.bonus) != 0 {
            b.node?.removeFromParent(); grantRandomBonus()
        } else if (b.categoryBitMask & Cat.player) != 0, (a.categoryBitMask & Cat.bonus) != 0 {
            a.node?.removeFromParent(); grantRandomBonus()
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        if (a.categoryBitMask & Cat.player) != 0 && (b.categoryBitMask & Cat.ground) != 0 {
            (a.node as? PlayerNode)?.groundContacts -= 1
        } else if (b.categoryBitMask & Cat.player) != 0 && (a.categoryBitMask & Cat.ground) != 0 {
            (b.node as? PlayerNode)?.groundContacts -= 1
        }
    }
    
    private func handleUnitGroundContact(unit: UnitNode, other: SKNode?) {
        // Первый раз на ПЛАТФОРМЕ — выбрать стартовое направление
        if isPlatform(other), unit.moveDir == nil {
            let dir: CGFloat = unit.position.x < bottomHoleCenterX ? 1 : -1
            unit.moveDir = dir
            unit.physicsBody?.velocity.dx = 0
            unit.physicsBody?.applyImpulse(CGVector(dx: 10 * dir, dy: 0)) // мягкий старт
            return
        }

        // Впервые (или снова) коснулись НИЖНЕГО ПОЛА — переоценить строго к дыре
        if isBottomFloor(other) {
            let dir: CGFloat = unit.position.x < bottomHoleCenterX ? 1 : -1
            unit.moveDir = dir
            if let body = unit.physicsBody, abs(body.velocity.dx) < 20 {
                body.velocity.dx = 0
                body.applyImpulse(CGVector(dx: 12 * dir, dy: 0))
            }
        }
    }
    
    // MARK: Game events
    private func destroyUnit(_ unit: UnitNode) {
        unit.removeFromParent()
        score += 10
    }
    
    private func killPlayer() {
        guard !isGameOver else { return }
        lives -= 1
        // короткая «смерть» с респавном
        player.removeFromParent()
        if lives <= 0 {
            gameOver()
            return
        }
        // респавн через 0.6 c
        run(.sequence([
            .wait(forDuration: 0.6),
            .run { [weak self] in self?.spawnPlayer() }
        ]))
    }
    
    private func registerMiss() {
        guard !isGameOver else { return }
        missesLeft -= 1
        if missesLeft <= 0 {
            gameOver()
        }
    }
    
    private func grantRandomBonus() {
        // если уже есть активный — обновим таймер/перезапишем
        let kind: BonusKind = (Bool.random() ? .rapidFire : .shield)
        activeBonus = (kind, kind.duration)
        // визуально можно подсветить игрока при щите
        updatePlayerTintForBonus()
    }
    
    private func updatePlayerTintForBonus() {
        guard let p = player else { return }
        if shieldActive {
            p.color = .systemGreen; p.colorBlendFactor = 0.6
        } else {
            p.color = .systemYellow; p.colorBlendFactor = 1.0
        }
    }
    
    private func gameOver() {
        isGameOver = true
        stopSpawning()
        // можно очистить оставшихся юнитов/пули
        enumerateChildNodes(withName: "unit") { n, _ in n.removeFromParent() }
        enumerateChildNodes(withName: "bullet") { n, _ in n.removeFromParent() }
        enumerateChildNodes(withName: "bonus") { n, _ in n.removeFromParent() }
    }
    
    // MARK: Update loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        // Обновляем бонус таймер
        if var ab = activeBonus {
            ab.timeLeft -= min(1.0/60.0, 1.0/30.0) // примерно каждый кадр
            if ab.timeLeft <= 0 {
                activeBonus = nil
                updatePlayerTintForBonus()
            } else {
                activeBonus = ab
            }
        }
        
        // Движение игрока по удержанию
        if let body = player?.physicsBody {
            let dir: CGFloat = (moveLeft ? -1 : 0) + (moveRight ? 1 : 0)
            if dir != 0 { player.facing = (dir > 0) ? .right : .left }
            let vx = playerMoveSpeed * dir
            let vy = max(min(body.velocity.dy, 800), -800)
            body.velocity = CGVector(dx: vx, dy: vy)
        }
        
        // Боты едут к дыре с постоянным vx, если уже выбрали направление
//        let bHoleLeftX = (size.width - bottomHoleWidth) / 2
//        let bHoleRightX = bHoleLeftX + bottomHoleWidth
        
        let speedX: CGFloat = unitSpeedX
        let maxVy: CGFloat = 600
        let bHoleLeftX = (size.width - bottomHoleWidth) / 2
        let bHoleRightX = bHoleLeftX + bottomHoleWidth

        enumerateChildNodes(withName: "unit") { node, _ in
            guard let unit = node as? UnitNode, let body = unit.physicsBody else { return }

            if let dir = unit.moveDir {
                body.velocity = CGVector(
                    dx: speedX * dir,
                    dy: max(min(body.velocity.dy, maxVy), -maxVy)
                )
            }

            // Если у уровня нижнего пола и по X внутри отверстия — считаем, что «упал в дыру»
            let nearBottom = unit.position.y <= (self.wallThickness + unit.size.height * 0.5 + 2)
            if nearBottom && unit.position.x >= bHoleLeftX && unit.position.x <= bHoleRightX {
                unit.removeFromParent()
                // если у тебя есть учёт пропуска через сенсор — это можно не делать здесь
            }

            // Чистка ушедших за экран
            if unit.position.y < -150 { unit.removeFromParent() }
        }
        
        // чистим пули за края
        enumerateChildNodes(withName: "bullet") { node, _ in
            if node.position.x < -100 || node.position.x > self.size.width + 100 {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: Ground checks / ray
    private func isPlayerOnGround() -> Bool {
        guard let p = player else { return false }
        return rayHitsGround(from: CGPoint(x: p.position.x, y: p.frame.minY - 1),
                             to:   CGPoint(x: p.position.x, y: p.frame.minY - 8))
    }
    
    private func isNodeOnGround(_ node: SKNode) -> Bool {
        let minY = node.frame.minY
        return rayHitsGround(from: CGPoint(x: node.position.x, y: minY - 1),
                             to:   CGPoint(x: node.position.x, y: minY - 8))
    }
    
    private func rayHitsGround(from start: CGPoint, to end: CGPoint) -> Bool {
        if let hit = physicsWorld.body(alongRayStart: start, end: end) {
            return (hit.categoryBitMask & Cat.ground) != 0
        }
        return false
    }
    
    private func isUnitOnGround(_ u: SKNode) -> Bool {
        let start = CGPoint(x: u.position.x, y: u.frame.minY - 1)
        let end   = CGPoint(x: u.position.x, y: u.frame.minY - 8)
        if let hit = physicsWorld.body(alongRayStart: start, end: end) {
            return (hit.categoryBitMask & Cat.ground) != 0
        }
        return false
    }

    private var bottomHoleLeftX: CGFloat { (size.width - bottomHoleWidth) / 2 }
    private var bottomHoleRightX: CGFloat { bottomHoleLeftX + bottomHoleWidth }
    
    private func isBottomFloor(_ node: SKNode?) -> Bool {
        (node?.name?.contains("bottomWall") ?? false)
    }
    private func isPlatform(_ node: SKNode?) -> Bool {
        (node?.name?.contains("platform") ?? false)
    }
}

// MARK: - Nodes

final class UnitNode: SKSpriteNode {
    var moveDir: CGFloat? = nil // -1 / +1
    init(size: CGSize) {
        super.init(texture: nil, color: .white, size: size)
        zPosition = 10
        name = "unit"
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class PlayerNode: SKSpriteNode {
    enum Facing { case left, right }
    var facing: Facing = .right
    var groundContacts: Int = 0 { didSet { groundContacts = max(0, groundContacts) } }
    
    init(size: CGSize) {
        super.init(texture: nil, color: .systemYellow, size: size)
        zPosition = 20
        name = "player"
        colorBlendFactor = 1.0
    }
    required init?(coder: NSCoder) { fatalError() }
}
