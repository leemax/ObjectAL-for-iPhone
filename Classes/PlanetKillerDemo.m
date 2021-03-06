//
//  PlanetKillerDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "PlanetKillerDemo.h"
#import "SimpleIphoneAudio.h"
#import "MainScene.h"
#import "ImageButton.h"
#import "RNG.h"


#define SHOOT_SOUND @"Pew.caf"
#define EXPLODE_SOUND @"Pow.caf"


#pragma mark -
#pragma mark Private Methods

@interface PlanetKillerDemo (Private)

- (void) pointTo:(float) angleInRadians;
- (void) shoot:(float) angleInRadians;
- (void) removePlanet:(CCNode*) planet;
- (void) removeBullet:(CCNode*) bullet;

@end

#pragma mark -
#pragma mark PlanetKillerDemo

@implementation PlanetKillerDemo

#pragma mark Object Management

+(id) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [self node]];
	return scene;
}

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Build UI
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);

		ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
		button.anchorPoint = ccp(1,1);
		button.position = ccp(size.width, size.height);
		[self addChild:button z:250];

		
		// Build game assets
		innerPlanetRect = CGRectMake(center.x - 50, center.y - 50, 100, 100);
		outerPlanetRect = CGRectMake(30, 30, size.width-60, size.height-60);

		ship = [CCSprite spriteWithFile:@"RocketShip.png"];
		ship.position = center;
		[self addChild:ship];
		
		planets = [[NSMutableArray arrayWithCapacity:20] retain];
		bullets = [[NSMutableArray arrayWithCapacity:20] retain];
		
		CCNode* planet = [CCSprite spriteWithFile:@"Jupiter.png"];
		impactDistanceSquared = planet.contentSize.width/2 * planet.contentSize.width/2;
	}
	return self;
}

- (void) dealloc
{
	[planets release];
	[bullets release];

	// Note: Normally you wouldn't purge SimpleIphoneAudio when leaving a scene.
	// I'm doing it here to provide a clean slate for the other demos.
	[SimpleIphoneAudio purgeSharedInstance];

	[super dealloc];
}


#pragma mark Utility

/** Point the ship.
 *
 * @param angleInRadians The angle to point the ship.
 */
- (void) pointTo:(float) angleInRadians
{
	ship.rotation = CC_RADIANS_TO_DEGREES(angleInRadians);
}


/** Build a bullet and shoot it 300 pixels in the specified direction.
 *
 * @param angleInRadians The angle to shoot at.
 */
- (void) shoot:(float) angleInRadians
{
	[self pointTo:angleInRadians];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CGPoint initialPoint = ccp(center.x + sin(angleInRadians)*50,
							   center.y + cos(angleInRadians)*50);
	CGPoint endPoint = ccp(center.x + sin(angleInRadians)*300,
						   center.y + cos(angleInRadians)*300);
	
	CCSprite* bullet = [CCSprite spriteWithFile:@"Ganymede.png"];
	bullet.scale = 0.3;
	bullet.position = initialPoint;
	[self addChild:bullet];
	[bullets addObject:bullet];
	
	CCIntervalAction* action = [CCSequence actions:
								[CCMoveTo actionWithDuration:1.0 position:endPoint],
								[CCCallFuncN actionWithTarget:self selector:@selector(removeBullet:)],
								nil];
	[bullet runAction:action];
	[[SimpleIphoneAudio sharedInstance] playEffect:SHOOT_SOUND];
}


- (void) removePlanet:(CCNode*) planet
{
	[planets removeObject:planet];
	[self removeChild:planet cleanup:YES];
}


- (void) removeBullet:(CCNode*) bullet
{
	[bullets removeObject:bullet];
	[self removeChild:bullet cleanup:YES];
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
	[[SimpleIphoneAudio sharedInstance] preloadEffect:SHOOT_SOUND];
	[[SimpleIphoneAudio sharedInstance] preloadEffect:EXPLODE_SOUND];
	[[SimpleIphoneAudio sharedInstance] playBg:@"PlanetKiller.mp3" loop:YES];

	self.isTouchEnabled = YES;
	[self schedule:@selector(onAddPlanet) interval:0.2];
	[self schedule:@selector(onGameUpdate)];
}


/** Game loop.
 * Check for bullet collisions with planets.
 */
- (void) onGameUpdate
{
	CCNode* bulletToRemove = nil;
	CCNode* planetToRemove = nil;

	// Naive collision detection algorithm
	for(CCNode* bullet in bullets)
	{
		for(CCNode* planet in planets)
		{
			float xDistance = planet.position.x - bullet.position.x;
			float yDistance = planet.position.y - bullet.position.y;
			if(xDistance * xDistance + yDistance * yDistance < impactDistanceSquared)
			{
				bulletToRemove = bullet;
				planetToRemove = planet;
				break;
			}
		}
		if(nil != bulletToRemove)
		{
			break;
		}
	}
	if(nil != bulletToRemove)
	{
		[self removeBullet:bulletToRemove];
		[self removePlanet:planetToRemove];
		[[SimpleIphoneAudio sharedInstance] playEffect:EXPLODE_SOUND];
	}
}

/** Add a planet to a random location on the screen in between the inner
 * and outer bounds.
 * The planet fades in, remains for awhile, then fades out.
 */
- (void) onAddPlanet
{
	float rangeX = (innerPlanetRect.origin.x - outerPlanetRect.origin.x) * 2;
	float rangeY = (innerPlanetRect.origin.y - outerPlanetRect.origin.y) * 2;
	
	float randomX = [[RNG sharedInstance] randomNumberFrom:0 to:rangeX];
	float randomY = [[RNG sharedInstance] randomNumberFrom:0 to:rangeY];
	
	CGPoint position = ccp(randomX+outerPlanetRect.origin.x, randomY+outerPlanetRect.origin.y);
	if(position.x > innerPlanetRect.origin.x)
	{
		position.x += innerPlanetRect.size.width;
	}
	if(position.y > innerPlanetRect.origin.y)
	{
		position.y += innerPlanetRect.size.height;
	}
	
	CCSprite* planet = [CCSprite spriteWithFile:@"Jupiter.png"];
	planet.position = position;
	planet.opacity = 0;
	[self addChild:planet];
	[planets addObject:planet];
	
	CCSequence* action = [CCSequence actions:
						  [CCFadeIn actionWithDuration:0.5],
						  [CCDelayTime actionWithDuration:3.0],
						  [CCFadeOut actionWithDuration:0.5],
						  [CCCallFuncN actionWithTarget:self selector:@selector(removePlanet:)],
						  nil];
	[planet runAction:action];
}


- (void) onExitPressed
{
	[self unschedule:@selector(onAddPlanet)];
	[self unschedule:@selector(onGameUpdate)];
	self.isTouchEnabled = NO;
	[[SimpleIphoneAudio sharedInstance] stopEverything];
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}


- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
	UITouch *touch = [touches anyObject];
	
	if( touch ) {
		// Landscape mode, so Y is really X, with 0 = left.
		// X is really Y, with 0 = bottom.  Subtract from 320 to put 0 = top.
		
		CGPoint location = ccp([touch locationInView:[touch view]].y, [touch locationInView:[touch view]].x);
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);
		
		float angle = M_PI/2 - atan((location.y - center.y) / (location.x - center.x));
		if(location.x < center.x)
		{
			angle = M_PI + angle;
		}
		
		[self shoot:angle];
	}
}


- (void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *) event
{
	UITouch *touch = [touches anyObject];
	
	if( touch ) {
		// Landscape mode, so Y is really X, with 0 = left.
		// X is really Y, with 0 = bottom.  Subtract from 320 to put 0 = top.
		
		CGPoint location = ccp([touch locationInView:[touch view]].y, [touch locationInView:[touch view]].x);
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);
		
		float angle = M_PI/2 - atan((location.y - center.y) / (location.x - center.x));
		if(location.x < center.x)
		{
			angle = M_PI + angle;
		}
		
		[self pointTo:angle];
	}
}

@end
