//
//  CrossFadeDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "cocos2d.h"
#import "ObjectAL.h"

/**
 * Demo of crossfading between two sources.
 * Use the slider to crossfade.
 */
@interface CrossFadeDemo : CCColorLayer
{
	ALDevice* device;
	ALContext* context;
	ALSource* firstSource;
	ALSource* secondSource;
	ALBuffer* firstBuffer;
	ALBuffer* secondBuffer;
}

+(id) scene;

@end
