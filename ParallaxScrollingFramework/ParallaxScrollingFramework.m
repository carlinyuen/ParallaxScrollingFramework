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
	NSString* const ParallaxScrollingKeyFrameTranslateX = @"translationX";
	NSString* const ParallaxScrollingKeyFrameTranslateY = @"translationY";
	NSString* const ParallaxScrollingKeyFrameScaleX = @"scaleX";
	NSString* const ParallaxScrollingKeyFrameScaleY = @"scaleY";
	NSString* const ParallaxScrollingKeyFrameRotation = @"rotation";

	#define KEYFRAME_KEY_VIEW @"view"
	#define KEYFRAME_KEY_FRAMES @"frames"
    #define KEYPATH_OBSERVER @"contentOffset"

@interface ParallaxScrollingFramework()

	/** Keyframes for hashed views */
	@property (nonatomic, strong) NSMutableDictionary* keyframes;

@end

@implementation ParallaxScrollingFramework

/** @brief Initialize data-related properties */
- (id)initWithScrollView:(UIScrollView *)scrollView
{
    self = [super init];
    if (self)
	{
		_keyframes = [[NSMutableDictionary alloc] init];
		
		_direction = ParallaxScrollingFrameworkDirectionHorizontal;
		
		_enabled = true;
		
		[self setScrollView:scrollView];
    }
    return self;
}

- (void)dealloc
{
    // Make sure we remove observer from scrollview
	[_scrollView removeObserver:self forKeyPath:KEYPATH_OBSERVER];
}


#pragma mark - Class Functions

/** @brief Sets a keyframe for a given view (that we hash to keep track of).
		We will automatically interpolate between keyframes (linearly only)
		for animations. All properties need to be defined, or undefined
		behavior is likely (they will default all to 0). If a keyframe
		already exists at the offset, it will be overwritten.
	@param frame A dictionary of properties you want to affect 
		(translation == translation, and offset == where you want the keyframe
		to take effect during scrolling). Example:
		@{
			ParallaxScrollingKeyFrameOffset : @(300),
			ParallaxScrollingKeyFrameTranslateX : @(target.x),
			ParallaxScrollingKeyFrameTranslateY : @(target.y),
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
		[self.keyframes setObject:[[NSMutableDictionary alloc] init] forKey:hash];
		data = [self.keyframes objectForKey:hash];
		[data setObject:view forKey:KEYFRAME_KEY_VIEW];
	}

	NSMutableArray* frames = [data objectForKey:KEYFRAME_KEY_FRAMES];
	if (!frames) {
		[data setObject:[[NSMutableArray alloc] init] forKey:KEYFRAME_KEY_FRAMES];
		frames = [data objectForKey:KEYFRAME_KEY_FRAMES];
	}
	
	int index = [self indexOfInsertion:frame inArray:frames];
	
	[frames insertObject:frame atIndex:index];
}

/** @brief Sets a keyframe for a given view (that we hash to keep track of).
		We will automatically interpolate between keyframes (linearly only)
		for animations. All properties need to be defined, or undefined
		behavior is likely (they will default all to 0). If a keyframe
		already exists at the offset, it will be overwritten.
	@param offset Where during the scroll to keyframe.
	@param translation Essentially a affine translation, where to position the element. Will be relative to their frame.translation.
	@param scale Scaling for UIView in both x & y axes, negative to flip.
	@param rotation Rotation for UIView, in radians.
	@param alpha Transparency for UIView, from 0 to 1.
	@param view UIView that you want to keyframe on.
*/
- (void)setKeyFrameWithOffset:(CGFloat)offset translate:(CGPoint)translation
	scale:(CGSize)scale rotate:(CGFloat)rotation alpha:(CGFloat)alpha
	forView:(UIView*)view
{
	[self setKeyFrame:@{
		ParallaxScrollingKeyFrameOffset : @(offset),
		ParallaxScrollingKeyFrameTranslateX : @(translation.x),
		ParallaxScrollingKeyFrameTranslateY : @(translation.y),
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
	CGFloat offset = 0;
	switch (self.direction) {
		case ParallaxScrollingFrameworkDirectionVertical:
			offset = self.scrollView.contentOffset.y;
			break;
			
		case ParallaxScrollingFrameworkDirectionHorizontal:
		default:
			offset = self.scrollView.contentOffset.x;
	}

	// Iterate through all the keys (objects that have been keyframed)
	[self.keyframes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
	{
		// Setup & get frames to interpolate with
		UIView* view = [(NSDictionary*)obj objectForKey:KEYFRAME_KEY_VIEW];
		NSArray* frames = [(NSDictionary*)obj objectForKey:KEYFRAME_KEY_FRAMES];

		// If not enabled, use first keyframe
		CGSize scale;
		CGPoint translation;
		CGFloat alpha = 0, rotation = 0;
		if (!self.enabled) {
			translation = CGPointMake(
				[frames[0][ParallaxScrollingKeyFrameTranslateX] floatValue],
				[frames[0][ParallaxScrollingKeyFrameTranslateY] floatValue]
			);
			scale = CGSizeMake(
				[frames[0][ParallaxScrollingKeyFrameScaleX] floatValue],
				[frames[0][ParallaxScrollingKeyFrameScaleY] floatValue]
			);
			alpha = [frames[0][ParallaxScrollingKeyFrameAlpha] floatValue];
			rotation = [frames[0][ParallaxScrollingKeyFrameRotation] floatValue];
		}
		else	// Animator enabled, find proper keyframe
		{
			int index = [self indexOfInsertion:@{
				ParallaxScrollingKeyFrameOffset : @(offset)
			} inArray:frames];
			NSDictionary* prev = (index > 0) ? frames[index - 1] : nil;
			NSDictionary* next = (index < frames.count) ? frames[index] : nil;

			// If we hit any frames dead on, or if one keyframe exists and
			//	the other doesn't, then we skip interpolation.
			if (prev
				&& ([prev[ParallaxScrollingKeyFrameOffset] floatValue] == offset
					|| !next))
			{
				translation = CGPointMake(
					[prev[ParallaxScrollingKeyFrameTranslateX] floatValue],
					[prev[ParallaxScrollingKeyFrameTranslateY] floatValue]
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
				translation = CGPointMake(
					[next[ParallaxScrollingKeyFrameTranslateX] floatValue],
					[next[ParallaxScrollingKeyFrameTranslateY] floatValue]
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
				CGFloat startOffset = [prev[ParallaxScrollingKeyFrameOffset] floatValue];
				CGFloat interpolation
					= (offset - startOffset)
						/ ([next[ParallaxScrollingKeyFrameOffset] floatValue] - startOffset);
					
				translation = CGPointMake(
					[self interpolate: [prev[ParallaxScrollingKeyFrameTranslateX] floatValue]
						with: [next[ParallaxScrollingKeyFrameTranslateX] floatValue]
						to: interpolation
					],
					[self interpolate: [prev[ParallaxScrollingKeyFrameTranslateY] floatValue]
						with: [next[ParallaxScrollingKeyFrameTranslateY] floatValue]
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
						translation.x, translation.y),
					rotation),
				scale.width, scale.height);

		// Debugging
//		NSLog(@"%@", @{
//			ParallaxScrollingKeyFrameTranslateX : @(translation.x),
//			ParallaxScrollingKeyFrameTranslateY : @(translation.y),
//			ParallaxScrollingKeyFrameScaleX : @(scale.width),
//			ParallaxScrollingKeyFrameScaleY : @(scale.height),
//			ParallaxScrollingKeyFrameRotation : @(rotation),
//			ParallaxScrollingKeyFrameAlpha : @(alpha)
//		});
	}];
}


#pragma mark - Data Management

/** @brief Set new scrollView */
- (void)setScrollView:(UIScrollView *)scrollView
{
	[_scrollView removeObserver:self forKeyPath:KEYPATH_OBSERVER];
	_scrollView = scrollView;
	[_scrollView addObserver:self forKeyPath:KEYPATH_OBSERVER
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
- (CGFloat)interpolate:(CGFloat)f1 with:(CGFloat)f2 to:(CGFloat)f3
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
