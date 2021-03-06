//
//  Button.m
//
//  Created by Karl Stenerud on 10-01-21.
//

#import "Button.h"


#pragma mark Button

@implementation Button

#pragma mark Object Management

+ (id) buttonWithTouchablePortion:(CCNode*) node target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTouchablePortion:node target:target selector:selector] autorelease];
}

- (id) initWithTouchablePortion:(CCNode*) node target:(id) targetIn selector:(SEL) selectorIn;
{
	if(nil != (self = [super init]))
	{
		self.touchablePortion = node;
		
		touchPriority = 0;
		targetedTouches = YES;
		swallowTouches = YES;
		isTouchesEnabled = YES;
		
		target = targetIn;
		selector = selectorIn;
		
		self.isRelativeAnchorPoint = YES;
		self.anchorPoint = ccp(0.5, 0.5);
	}
	return self;
}

#pragma mark Event Handlers

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if([self touch:touch hitsNode:touchablePortion])
	{
		touchInProgress = YES;
		buttonWasDown = YES;
		[self onButtonDown];
		return YES;
	}
	return NO;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{	
	if(touchInProgress)
	{
		if([self touch:touch hitsNode:touchablePortion])
		{
			if(!buttonWasDown)
			{
				[self onButtonDown];
			}
		}
		else
		{
			if(buttonWasDown)
			{
				[self onButtonUp];
			}
		}
	}
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{	
	if(buttonWasDown)
	{
		[self onButtonUp];
	}
	if(touchInProgress && [self touch:touch hitsNode:touchablePortion])
	{
		touchInProgress = NO;
		[self onButtonPressed];
	}
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(buttonWasDown)
	{
		[self onButtonUp];
	}
	touchInProgress = NO;
}

- (void) onButtonDown
{
	buttonWasDown = YES;
}

- (void) onButtonUp
{
	buttonWasDown = NO;
}

- (void) onButtonPressed
{
	[target performSelector:selector withObject:self];
}

#pragma mark Properties

- (GLubyte) opacity
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			return ((id<CCRGBAProtocol>)child).opacity;
		}
	}
	return 255;
}

- (void) setOpacity:(GLubyte) value
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			((id<CCRGBAProtocol>)child).opacity =  value;
		}
	}
}

- (ccColor3B) color
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			return ((id<CCRGBAProtocol>)child).color;
		}
	}
	return ccWHITE;
}

- (void) setColor:(ccColor3B) value
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			((id<CCRGBAProtocol>)child).color =  value;
		}
	}
}

@synthesize touchablePortion;

- (void) setTouchablePortion:(CCNode *) value
{
	if(nil != touchablePortion)
	{
		[self removeChild:touchablePortion cleanup:YES];
	}
	touchablePortion = value;
	[self addChild:touchablePortion];
	self.contentSize = touchablePortion.contentSize;
	touchablePortion.anchorPoint = ccp(0,0);
	touchablePortion.position = ccp(0,0);
}

@end
