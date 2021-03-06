//
//  Player.swift
//  PierreThePenguinDos
//
//  Created by Sparrow on 10/7/18.
//  Copyright © 2018 ParanoidWacko. All rights reserved.
//

import Foundation
import SpriteKit

class Player: SKSpriteNode, GameSprite {
    fileprivate static let KEY_ANIMATION_FLAP = "flapAnimation"
    fileprivate static let KEY_ANIMATION_SOAR = "soarAnimation"
    fileprivate static let KEY_ANIMATION_STAR = "starPower"
    
    var initialSize = CGSize(width: 64, height: 64)
    var textureAtlas: SKTextureAtlas = SKTextureAtlas(named: TextureAtlasName.Pierre.rawValue)
    var flyAnimation = SKAction()
    var soarAnimation = SKAction()
    var flapping = false
    let maxFlappingForce: CGFloat = 57000
    let maxHeight: CGFloat = 1000
    var health: Int = 3
    let maxHealth = 3
    var invulnerable = false
    var damaged = false
    var damageAnimation = SKAction()
    var dieAnimation = SKAction()
    var forwardVelocity: CGFloat = 200
    
    init() {
        super.init(texture: nil, color: .clear, size: initialSize)
        createAnimations()
        self.run(soarAnimation, withKey: Player.KEY_ANIMATION_SOAR)
        
        let bodyTexture = textureAtlas.textureNamed(TextureName.PierreFlying3.rawValue)
        self.physicsBody = SKPhysicsBody(texture: bodyTexture, size: self.size)
        self.physicsBody?.linearDamping = 0.9
        self.physicsBody?.mass = 30
        self.physicsBody?.allowsRotation = false
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.penguin.rawValue
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy.rawValue | PhysicsCategory.ground.rawValue | PhysicsCategory.powerup.rawValue | PhysicsCategory.coin.rawValue | PhysicsCategory.crate.rawValue
        self.physicsBody?.collisionBitMask = PhysicsCategory.ground.rawValue
        
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.velocity.dy = 80
        let startGravitySequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run {
                self.physicsBody?.affectedByGravity = true
            }
            ])
        self.run(startGravitySequence)
    }
    
    func createAnimations() {
        let rotateUpAction = SKAction.rotate(byAngle: 0, duration: 0.475)
        rotateUpAction.timingMode = .easeOut
        let rotateDownAction = SKAction.rotate(byAngle: -1, duration: 0.8)
        rotateDownAction.timingMode = .easeIn
        
        let flyFrames: [SKTexture] = [
            textureAtlas.textureNamed(TextureName.PierreFlying1.rawValue),
            textureAtlas.textureNamed(TextureName.PierreFlying2.rawValue),
            textureAtlas.textureNamed(TextureName.PierreFlying3.rawValue),
            textureAtlas.textureNamed(TextureName.PierreFlying4.rawValue),
            textureAtlas.textureNamed(TextureName.PierreFlying3.rawValue),
            textureAtlas.textureNamed(TextureName.PierreFlying2.rawValue)
        ]
        let flyAction = SKAction.animate(with: flyFrames, timePerFrame: 0.03)
        flyAnimation = SKAction.group([SKAction.repeatForever(flyAction)])//, rotateUpAction])
        
        let soarFrames: [SKTexture] = [textureAtlas.textureNamed(TextureName.PierreFlying1.rawValue)]
        let soarAction = SKAction.animate(with: soarFrames, timePerFrame: 1)
        soarAnimation = SKAction.group([SKAction.repeatForever(soarAction)])//, rotateDownAction])
        
        let damageStart = SKAction.run {
            self.physicsBody?.categoryBitMask = PhysicsCategory.damagedPenguin.rawValue
        }
        let slowFade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.35),
            SKAction.fadeAlpha(to: 0.7, duration: 0.35)
            ])
        let fastFade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.2),
            SKAction.fadeAlpha(to: 0.7, duration: 0.2)
            ])
        let fadeOutAndIn = SKAction.sequence([
            SKAction.repeat(slowFade, count: 2),
            SKAction.repeat(fastFade, count: 5),
            SKAction.fadeAlpha(by: 1, duration: 0.15)
            ])
        let damageEnd = SKAction.run {
            self.physicsBody?.categoryBitMask = PhysicsCategory.penguin.rawValue
            self.damaged = false
        }
        self.damageAnimation = SKAction.sequence([
            damageStart,
            fadeOutAndIn,
            damageEnd
            ])

        let startDie = SKAction.run {
            self.texture = self.textureAtlas.textureNamed(TextureName.PierreDead.rawValue)
            self.physicsBody?.affectedByGravity = false
            self.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        }
        let endDie = SKAction.run {
            self.physicsBody?.affectedByGravity = true
        }
        self.dieAnimation = SKAction.sequence([
            startDie,
            SKAction.scale(to: 1.3, duration: 0.5),
            SKAction.wait(forDuration: 0.5),
            SKAction.rotate(toAngle: 3, duration: 1.5),
            SKAction.wait(forDuration: 0.5),
            endDie
            ])
    }
    
    func onTap() {
        
    }
    
    func update() {
        if self.flapping {
            var forceToApply = maxFlappingForce
            if position.y > 600 {
                let percentageOfMaxHeight = position.y / maxHeight
                let flappingForceSubtraction = percentageOfMaxHeight * maxFlappingForce
                forceToApply -= flappingForceSubtraction
            }
            self.physicsBody?.applyForce(CGVector(dx: 0, dy: forceToApply))
        }
        
        self.physicsBody?.velocity.dx = self.forwardVelocity
    }
    
    func startFlapping() {
        if self.health <= 0 {
            return
        }
        self.removeAction(forKey: Player.KEY_ANIMATION_SOAR)
        self.run(flyAnimation, withKey: Player.KEY_ANIMATION_FLAP)
        self.flapping = true
    }
    
    func stopFlapping() {
        if self.health <= 0 {
            return
        }
        self.removeAction(forKey: Player.KEY_ANIMATION_FLAP)
        self.run(soarAnimation, withKey: Player.KEY_ANIMATION_SOAR)
        self.flapping = false
    }
    
    func die() {
        self.alpha = 1
        self.removeAllActions()
        self.run(self.dieAnimation)
        self.flapping = false
        self.forwardVelocity = 0
        
        if let gameScene = self.parent as? GameScene {
            gameScene.gameOver()
        }
    }
    
    func takeDamage() {
        if self.invulnerable || self.damaged {
            return
        }
        self.damaged = true
        self.health -= 1
        if self.health <= 0 {
            self.die()
        } else {
            self.run(self.damageAnimation)
        }
        if let audioAction = AudioManager.AudioAction(of: AudioName.Hurt) {
            self.run(audioAction)
        }
    }
    
    func starPower() {
        self.removeAction(forKey: Player.KEY_ANIMATION_STAR)
        self.forwardVelocity = 400
        self.invulnerable = true
        let starSequence = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.wait(forDuration: 8),
            SKAction.scale(to: 1, duration: 1),
            SKAction.run {
                self.forwardVelocity = 200
                self.invulnerable = false
            }
            ])
        self.run(starSequence, withKey: Player.KEY_ANIMATION_STAR)
        if let audioAction = AudioManager.AudioAction(of: AudioName.PowerUp) {
            self.run(audioAction)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
