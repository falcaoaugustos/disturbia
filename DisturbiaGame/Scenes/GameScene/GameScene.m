//
//  GameScene.m
//  DisturbiaGame
//
//  Created by Augusto Falcão on 10/19/17.
//  Copyright © 2017 Augusto Falcão. All rights reserved.
//

#import "GameScene.h"
#import "ContactListener.h"

@implementation GameScene

#pragma mark - Scene Cycle

- (instancetype)initWithSize:(CGSize)size andDistance:(NSNumber *)distance andInsanity:(NSNumber *)insanity
{
    if (self = [super initWithSize:size]) {
        self.inMiniPuzzle = 0;

        self.distance = [distance integerValue];
        self.insanity = [insanity integerValue];

        self.data = [[PlistManager sharedManager] readFile];

        self.countJump = 0;
        self.insanityFamily = 0;

        [self.physicsWorld setContactDelegate: self];
        [self setShouldEnableEffects:YES];

        [self setup];
    }
    return self;
}

#pragma mark - Life cycle methods

- (void) didMoveToView:(SKView *)view
{
    self.data = [[PlistManager sharedManager] readFile];

    self.distance = [[self.data objectForKey:@"Distance"] integerValue];

    self.insanity = [self maxBetween:0 and:[[self.data objectForKey:@"Insanity"] integerValue]];
    [self modifyInsanity];

    [self play];
}

- (void)update:(CFTimeInterval)currentTime
{
    [self modifyDistance];
    [self modifyInsanity];
}

#pragma mark - Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.hero jump:self.countJump andParent:self];
    self.countJump++;
}

#pragma mark - Creators

- (void)setup
{
    [self createWorld];
    [self createInsanityBar];
    [self createScoreLabel];
    [self createHero];
    [self createGround];
    [self createPickup];
    [self createEnemy];
    [self createFX];
    [self createPause];
    [self resetStoredValues];
}

- (void) createInsanityBar
{
    _insanityBar = [InsanityBar createNodeOnParent: self];
}

- (void)createFX
{
    self.visualFX = [NSArray arrayWithObjects: @"CIPixellate", @"CISpotLight", @"CIColorPosterize", @"CISpotColor", @"CIColorInvert", nil];
}

- (void)createScoreLabel
{
    _distanceLabel = [Score createNodeOnParent: self];
    [_distanceLabel setNewScoreValue: _distance];
}

- (void)createWorld
{
    [Background addNewNodeBackgroundTo: self];

    [PauseButton createNodeOnParent: self];

    self.physicsWorld.contactDelegate = self;
    self.physicsWorld.gravity = CGVectorMake(0, -3);
}

- (void) createHero
{
    self.hero = [Hero createNodeOn:self];
    self.hero.position = CGPointMake(self.frame.size.width / 6, self.frame.size.height / 4 + self.frame.size.height / 2);
    self.hero.zPosition = 100;
}

- (void)createGround
{
    [Ground createNodeOnParent: self];
}

- (void)createPause
{
    _pauseLabel = [PauseLabel createNodeOnParent: self];
}

- (void)resetStoredValues
{
    [self.data setObject: @0 forKey:@"Points"];
    [self.data setObject: @0 forKey:@"Insanity"];
    [self.data setObject: @0 forKey:@"Distance"];

    [[PlistManager sharedManager] writeFileWith: self.data];
}

#pragma mark - Actions

- (void)setPlayerWith:(NSURL *)url
{
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.numberOfLoops = -1;
    [self.audioPlayer play];
}

- (void)updateFXWith:(NSString *)fx andVolume:(CGFloat)volume andInsanityFamily:(NSInteger)insanityFamily
{
    [self setFilter: [CIFilter filterWithName: [NSString stringWithFormat:@"%@", fx]]];

    [self.audioPlayer setVolume: volume];
    NSURL *url = [NSURL fileURLWithPath: [[NSBundle mainBundle]  pathForResource: [NSString stringWithFormat:@"%ld", insanityFamily - 1] ofType:@"wav"]];
    [self setPlayerWith: url];

    self.insanityFamily = insanityFamily;
}

- (void)fxWillChange
{
    if (self.insanity > 80 && self.insanityFamily != 6)
        [self updateFXWith: self.visualFX[4] andVolume: 0.1 andInsanityFamily: 6];
    else if (self.insanity > 60 && self.insanity < 81 && self.insanityFamily != 5)
        [self updateFXWith: self.visualFX[3] andVolume: 0.05 andInsanityFamily: 5];
    else if (self.insanity > 40 && self.insanity < 61 && self.insanityFamily != 4)
        [self updateFXWith: self.visualFX[2] andVolume: 0.1 andInsanityFamily: 4];
    else if (self.insanity > 25 && self.insanity < 41 && self.insanityFamily != 3)
        [self updateFXWith: self.visualFX[1] andVolume: 0.05 andInsanityFamily: 3];
    else if (self.insanity > 10 && self.insanity < 26 && self.insanityFamily != 2)
        [self updateFXWith: self.visualFX[0] andVolume: 0.1 andInsanityFamily: 2];
    else if(self.insanity < 11 && self.insanityFamily != 1)
        [self updateFXWith: @"0" andVolume: 1.0 andInsanityFamily: 1];
}

- (void)createPickup
{
    if (self.distance < 1000)
        self.pickupTimer = [NSTimer scheduledTimerWithTimeInterval: 4.5 + ((arc4random() % 10) / 10.0) target:self selector:@selector(addPickup) userInfo:nil repeats:YES];
    else if (self.distance < 2000)
        self.obstacleTimer = [NSTimer scheduledTimerWithTimeInterval: 6.5 + ((arc4random() % 20) / 10.0) target:self selector:@selector(addPickup) userInfo:nil repeats:YES];
    else
        self.obstacleTimer = [NSTimer scheduledTimerWithTimeInterval: 8.5 + ((arc4random() % 30) / 10.0) target:self selector:@selector(addPickup) userInfo:nil repeats:YES];
}

-(void)addPickup
{
    [OrangePickup createNodeOnParent: self];
}

- (void)createEnemy
{
    if (self.distance < 1000)
        self.obstacleTimer = [NSTimer scheduledTimerWithTimeInterval: 2.5 + ((arc4random() % 10) / 10.0) target:self selector:@selector(addEnemy) userInfo:nil repeats:YES];
    else if (self.distance < 2000)
        self.obstacleTimer = [NSTimer scheduledTimerWithTimeInterval: 1.5 + ((arc4random() % 20) / 10.0) target:self selector:@selector(addEnemy) userInfo:nil repeats:YES];
    else
        self.obstacleTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 + ((arc4random() % 30) / 10.0) target:self selector:@selector(addEnemy) userInfo:nil repeats:YES];
}

- (void)addEnemy
{
    int sort = arc4random()%3;

    if (sort == 0)
        [GiantScientist createNodeOnParent: self];
    else
        [Scientist createNodeOnParent: self];
}

- (void)die
{
    [self resetStoredValues];

    [self.audioPlayer stop];
    self.audioPlayer = nil;

    [self.obstacleTimer invalidate];

    SKTransition *reveal = [SKTransition fadeWithDuration:.5f];
    DeathScene *newScene = [DeathScene sceneWithSize: self.size];
    [self.scene.view presentScene: newScene transition: reveal];
}

#pragma mark - Score and Death

- (void)modifyDistance
{
    self.distance++;
    [self.distanceLabel setText:[NSString stringWithFormat:@"%ld", (unsigned long)self.distance]];
}

- (void)modifyInsanity
{
    if (self.insanity >= 100) [self die];
    else if (self.auxInsanity % 50 == 49)
    {
        self.auxInsanity = 0;
        self.insanity++;
        [self fxWillChange];
        [self.insanityBar setProgress: self.insanity];
    }
    else self.auxInsanity++;
}

- (NSInteger)calculatePoints
{
    return 2 + [[NSNumber numberWithDouble:(self.distance / 1000)] integerValue];
}

- (NSInteger)maxBetween:(NSInteger)a and:(NSInteger)b
{
    return a > b ? a : b;
}

#pragma mark - Physics Contact Delegate

- (void) didBeginContact: (SKPhysicsContact *) contact
{
    [(id<ContactListener>) contact.bodyA.node didBeginContact: contact];
    [(id<ContactListener>) contact.bodyB.node didBeginContact: contact];
}

- (void) didEndContact: (SKPhysicsContact *) contact
{
    [(id<ContactListener>) contact.bodyA.node didEndContact: contact];
    [(id<ContactListener>) contact.bodyB.node didEndContact: contact];
}

#pragma mark - Pause Button Delegate

- (void) play
{
    self.obstacleTimer = [NSTimer scheduledTimerWithTimeInterval:3.4 target:self selector:@selector(addEnemy) userInfo:nil repeats:YES];
    [_pauseLabel setText: @""];
    [self runAction: [SKAction playSoundFileNamed: [NSString stringWithFormat: @"tap"] waitForCompletion: NO]];
    [self setPaused: NO];

    [self setUserInteractionEnabled:YES];

    [self.audioPlayer play];

    if (self.insanity > 80)
        [self setFilter: [CIFilter filterWithName: [NSString stringWithFormat:@"%@", self.visualFX[4]]]];
    else if (self.insanity > 60)
        [self setFilter: [CIFilter filterWithName: [NSString stringWithFormat:@"%@", self.visualFX[3]]]];
    else if (self.insanity > 40)
        [self setFilter: [CIFilter filterWithName: [NSString stringWithFormat:@"%@", self.visualFX[2]]]];
    else if (self.insanity > 25)
        [self setFilter: [CIFilter filterWithName: [NSString stringWithFormat:@"%@", self.visualFX[1]]]];
    else if (self.insanity > 10)
        [self setFilter: [CIFilter filterWithName: [NSString stringWithFormat:@"%@", self.visualFX[0]]]];
    else
        [self setFilter: [CIFilter filterWithName: @""]];
}

- (void) pause
{
    [self runAction: [SKAction playSoundFileNamed: [NSString stringWithFormat: @"tap"] waitForCompletion: NO] completion:^{[self setPaused: YES];}];
    [self.obstacleTimer invalidate];
    _pauseLabel.text = @"PAUSED";

    [self setUserInteractionEnabled:NO];

    [self.audioPlayer pause];
}

#pragma mark - Ground Delegate

- (void) groundDidTouched
{
    _countJump = 0;
}

#pragma mark - Orange Pickup Delegate

- (void) orangePickupDidCollected
{
    _insanity = [self maxBetween: 0 and: _insanity - 15];
    [self modifyInsanity];
}

#pragma mark - Scientist Delegate

- (void) scientistDidContacted
{
    _insanity = _insanity + 20;
    [self modifyInsanity];
}

#pragma mark - Giant Scientist Delegate

- (void) giantScientistDidContacted
{
    _insanity = _insanity + 40;
    [self modifyInsanity];
}

@end
