/**
	@file	ParallaxScrollingFramework.m
	@author	Carlin
	@date	8/5/13
	@brief	Simple framework for keyframing animations based on offset in a Scrollview for parallax effect.
*/
//  Copyright (c) 2013 Carlin. All rights reserved.


#import "ParallaxScrollingFramework.h"

	NSString* const ParallaxScrollingKeyFrameOffset = @"offset";
	NSString* const ParallaxScrollingKeyFrameAlpha = @"alpha";
	NSString* const ParallaxScrollingKeyFrameOriginX = @"originX";
	NSString* const ParallaxScrollingKeyFrameOriginY = @"originY";
	NSString* const ParallaxScrollingKeyFrameScaleX = @"scaleX";
	NSString* const ParallaxScrollingKeyFrameScaleY = @"scaleY";
	NSString* const ParallaxScrollingKeyFrameRotation = @"rotation";

	#define KEYFRAME_KEY_VIEW @"view"
	#define KEYFRAME_KEY_FRAMES @"frames"

@interface ParallaxScrollingFramework()

	/** Scrollview to create parallax animation on */
	@property (nonatomic, weak) UIScrollView* scrollView;

	/** Keyframes for hashed views */
	@property (nonatomic, strong) NSMutableDictionary* keyframes;

@end

@implementation ParallaxScrollingFramework

/** @brief Initialize data-related properties */
- (id)initWithScrollView:(UIScrollView *)scrollView
{
    self = [super init];
    if (self) {
		_keyframes = [[NSMutableDictionary alloc] init];
		
		[self setScrollView:scrollView];
    }
    return self;
}


#pragma mark - Class Functions

/** @brief Sets a keyframe for a given view (that we hash to keep track of).
		We will automatically interpolate between keyframes (linearly only)
		for animations. All properties need to be defined, or undefined
		behavior is likely (they will default all to 0). If a keyframe
		already exists at the offset, it will be overwritten.
	@param frame A dictionary of properties you want to affect 
		(origin == translation, and offset == where you want the keyframe
		to take effect during scrolling). Example:
		@{
			ParallaxScrollingKeyFrameOffset : @(300),
			ParallaxScrollingKeyFrameOriginX : @(target.x),
			ParallaxScrollingKeyFrameOriginY : @(target.y),
			ParallaxScrollingKeyFrameScaleX : @(1.2)
			ParallaxScrollingKeyFrameScaleY : @(1.2)
			ParallaxScrollingKeyFrameAlpha : @(.8),
			// Omitted rotation if ok with it being 0
		}
	@param view View that you want to keyframe on.
*/
- (void)setKeyFrame:(NSDictionary*)frame forView:(UIView *)view
{
	NSNumber* hash = @([view hash]);
	NSMutableDictionary* data = [self.keyframes objectForKey:hash];
	if (!data) {
		debugLog(@"creating new view data");
		[self.keyframes setObject:[[NSMutableDictionary alloc] init] forKey:hash];
		data = [self.keyframes objectForKey:hash];
		[data setObject:view forKey:KEYFRAME_KEY_VIEW];
	}

	NSMutableArray* frames = [data objectForKey:KEYFRAME_KEY_FRAMES];
	if (!frames) {
		debugLog(@"creating new frames");
		[data setObject:[[NSMutableArray alloc] init] forKey:KEYFRAME_KEY_FRAMES];
		frames = [data objectForKey:KEYFRAME_KEY_FRAMES];
	}
	
	int index = [self indexOfInsertion:frame inArray:frames];
	debugLog(@"setKeyFrame: %i indexOfInsertion: %i", frames.count, index);
	
	[frames insertObject:frame atIndex:index];
}

/** @brief Sets a keyframe for a given view (that we hash to keep track of).
		We will automatically interpolate between keyframes (linearly only)
		for animations. All properties need to be defined, or undefined
		behavior is likely (they will default all to 0). If a keyframe
		already exists at the offset, it will be overwritten.
	@param offset Where during the scroll to keyframe.
	@param origin Essentially a affine translation, where to position the element. Will be relative to their frame.origin.
	@param scale Scaling for UIView in both x & y axes, negative to flip.
	@param rotation Rotation for UIView, in radians.
	@param alpha Transparency for UIView, from 0 to 1.
	@param view UIView that you want to keyframe on.
*/
- (void)setKeyFrameWithOffset:(float)offset origin:(CGPoint)origin
	scale:(CGSize)scale rotation:(float)rotation alpha:(float)alpha
	forView:(UIView*)view
{
	[self setKeyFrame:@{
		ParallaxScrollingKeyFrameOffset : @(offset),
		ParallaxScrollingKeyFrameOriginX : @(origin.x),
		ParallaxScrollingKeyFrameOriginY : @(origin.y),
		ParallaxScrollingKeyFrameScaleX : @(scale.width),
		ParallaxScrollingKeyFrameScaleY : @(scale.height),
		ParallaxScrollingKeyFrameRotation : @(rotation),
		ParallaxScrollingKeyFrameAlpha : @(alpha)
	} forView:view];
}

/** @brief Removes all keyframes that were set for a given view, or if no
		view is given, then for all views.
	@param view UIView that should have keyframes removed, 
		or nil to have all keyframes removed. 
*/
- (void)clearKeyFrames:(UIView*)view
{
	if (view)	// Remove frames from only the hashed view
	{
		[[[self.keyframes objectForKey:@([view hash])] objectForKey:KEYFRAME_KEY_FRAMES] removeAllObjects];
	}
	else	// Remove all keyframes from all hashed objects
	{
		// Iterate through all the keys (objects that have been keyframed)
		[self.keyframes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[[(NSDictionary*)obj objectForKey:KEYFRAME_KEY_FRAMES] removeAllObjects];
		}];
	}
}

/** @brief Called everytime the content offset changes on the observed scrollView. Updates the affine transform for views. */
- (void)updateFrame
{
	float offset = self.scrollView.contentOffset.y;
	debugLog(@"updateFrame: %f", offset);

	// Iterate through all the keys (objects that have been keyframed)
	[self.keyframes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
	{
		// Setup & get frames to interpolate with
		UIView* view = [(NSDictionary*)obj objectForKey:KEYFRAME_KEY_VIEW];
		NSArray* frames = [(NSDictionary*)obj objectForKey:KEYFRAME_KEY_FRAMES];
		int index = [self indexOfInsertion:@{
			ParallaxScrollingKeyFrameOffset : @(offset)
		} inArray:frames];
		NSDictionary* prev = (index > 0) ? frames[index - 1] : nil;
		NSDictionary* next = (index < frames.count) ? frames[index] : nil;
		CGPoint origin;
		CGSize scale;
		float alpha = 0, rotation = 0;
		
		// If we hit any frames dead on, or if one keyframe exists and
		//	the other doesn't, then we skip interpolation.
		if (prev
			&& ([prev[ParallaxScrollingKeyFrameOffset] floatValue] == offset
				|| !next))
		{
			origin = CGPointMake(
				[prev[ParallaxScrollingKeyFrameOriginX] floatValue],
				[prev[ParallaxScrollingKeyFrameOriginY] floatValue]
			);
			scale = CGSizeMake(
				[prev[ParallaxScrollingKeyFrameScaleX] floatValue],
				[prev[ParallaxScrollingKeyFrameScaleY] floatValue]
			);
			alpha = [prev[ParallaxScrollingKeyFrameAlpha] floatValue];
			rotation = [prev[ParallaxScrollingKeyFrameRotation] floatValue];
		}
		else if (next
			&& ([next[ParallaxScrollingKeyFrameOffset] floatValue] == offset
				|| !prev))
		{
			origin = CGPointMake(
				[next[ParallaxScrollingKeyFrameOriginX] floatValue],
				[next[ParallaxScrollingKeyFrameOriginY] floatValue]
			);
			scale = CGSizeMake(
				[next[ParallaxScrollingKeyFrameScaleX] floatValue],
				[next[ParallaxScrollingKeyFrameScaleY] floatValue]
			);
			alpha = [next[ParallaxScrollingKeyFrameAlpha] floatValue];
			rotation = [next[ParallaxScrollingKeyFrameRotation] floatValue];
		}
		else if (prev && next)	// Have to interpolate between the two points
		{
			float startOffset = [prev[ParallaxScrollingKeyFrameOffset] floatValue];
			float interpolation
				= (offset - startOffset)
					/ ([next[ParallaxScrollingKeyFrameOffset] floatValue] - startOffset);
				
			origin = CGPointMake(
				[self interpolate: [prev[ParallaxScrollingKeyFrameOriginX] floatValue]
					with: [next[ParallaxScrollingKeyFrameOriginX] floatValue]
					to: interpolation
				],
				[self interpolate: [prev[ParallaxScrollingKeyFrameOriginY] floatValue]
					with: [next[ParallaxScrollingKeyFrameOriginY] floatValue]
					to: interpolation
				]
			);
			scale = CGSizeMake(
				[self interpolate: [prev[ParallaxScrollingKeyFrameScaleX] floatValue]
					with: [next[ParallaxScrollingKeyFrameScaleX] floatValue]
					to: interpolation
				],
				[self interpolate: [prev[ParallaxScrollingKeyFrameScaleY] floatValue]
					with: [next[ParallaxScrollingKeyFrameScaleY] floatValue]
					to: interpolation
				]
			);
			alpha = [self
				interpolate: [prev[ParallaxScrollingKeyFrameAlpha] floatValue]
				with: [next[ParallaxScrollingKeyFrameAlpha] floatValue]
				to: interpolation
			];
			rotation = [self
				interpolate: [prev[ParallaxScrollingKeyFrameRotation] floatValue]
				with: [next[ParallaxScrollingKeyFrameRotation] floatValue]
				to: interpolation
			];
		}

		// Only change if in range
		if (alpha >= 0 && alpha <= 1) {
			view.alpha = alpha;
		}

		// Linear Algebra: scale, then rotate, then translate
		view.transform =
			CGAffineTransformScale(
				CGAffineTransformRotate(
					CGAffineTransformTranslate(
						CGAffineTransformIdentity,
						origin.x, origin.y),
					rotation),
				scale.width, scale.height);
				
		// Debugging
//		debugObject((@{
//			ParallaxScrollingKeyFrameOriginX : @(origin.x),
//			ParallaxScrollingKeyFrameOriginY : @(origin.y),
//			ParallaxScrollingKeyFrameScaleX : @(scale.width),
//			ParallaxScrollingKeyFrameScaleY : @(scale.height),
//			ParallaxScrollingKeyFrameRotation : @(rotation),
//			ParallaxScrollingKeyFrameAlpha : @(alpha)
//		}));
	}];
}


#pragma mark - Data Management

/** @brief Set new scrollView */
- (void)setScrollView:(UIScrollView *)scrollView
{
	[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
	_scrollView = scrollView;
	[_scrollView addObserver:self forKeyPath:@"contentOffset"
		options:NSKeyValueObservingOptionNew context:nil];
}


#pragma mark - Utilty Functions

/** @brief Returns index of insertion */
- (int)indexOfInsertion:(NSDictionary*)obj inArray:(NSArray*)array
{
	return [array indexOfObject:obj
		inSortedRange:NSMakeRange(0, array.count)
		options:NSBinarySearchingInsertionIndex
		usingComparator:^NSComparisonResult(id obj1, id obj2)
		{
			NSNumber* n1 = [(NSDictionary*)obj1 objectForKey:ParallaxScrollingKeyFrameOffset];
			NSNumber* n2 = [(NSDictionary*)obj2 objectForKey:ParallaxScrollingKeyFrameOffset];
			return [n1 compare:n2];
		}];
}

/** @brief Interpolates between two points
	@param f1 Starting point
	@param f2 Ending point
	@param f3 Scale between 0-1 to interpolate to, 0 = f1, 1 = f2.
*/
- (float)interpolate:(float)f1 with:(float)f2 to:(float)f3
{
	return (f2 - f1) * f3 + f1;
}

#pragma mark - Delegates

/** @brief Tracking the updating of the scrollview */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if (object == self.scrollView) {
		[self updateFrame];
	}
}

@end
