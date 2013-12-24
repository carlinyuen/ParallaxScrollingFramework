/**
	@file	ParallaxScrollingFramework.h
	@author	Carlin
	@date	8/5/13
	@brief	Simple framework for keyframing animations based on offset in a Scrollview for parallax effect
*/
//  Copyright (c) 2013 Carlin. All rights reserved.


#import <Foundation/Foundation.h>

	extern NSString* const ParallaxScrollingKeyFrameOffset;
	extern NSString* const ParallaxScrollingKeyFrameTranslateX;
	extern NSString* const ParallaxScrollingKeyFrameTranslateY;
	extern NSString* const ParallaxScrollingKeyFrameAlpha;
	extern NSString* const ParallaxScrollingKeyFrameScaleX;
	extern NSString* const ParallaxScrollingKeyFrameScaleY;
	extern NSString* const ParallaxScrollingKeyFrameRotation;

	typedef enum {
		ParallaxScrollingFrameworkDirectionHorizontal,
		ParallaxScrollingFrameworkDirectionVertical
	} ParallaxScrollingFrameworkDirection;

@interface ParallaxScrollingFramework : NSObject

	/** Set tracking on horizontal or vertical scroll */
	@property (nonatomic, assign) ParallaxScrollingFrameworkDirection direction;

	/** Turn on and off animator */
	@property (nonatomic, assign) bool enabled;

	/** Scrollview to create parallax animation on */
	@property (nonatomic, weak) UIScrollView* scrollView;

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
				ParallaxScrollingKeyFrameTranslateX : @(target.x),
				ParallaxScrollingKeyFrameTranslateY : @(target.y),
				ParallaxScrollingKeyFrameScaleX : @(1.2)
				ParallaxScrollingKeyFrameScaleY : @(1.2)
				ParallaxScrollingKeyFrameAlpha : @(.8),
				// Omitted rotation if ok with it being 0
			}
		@param view View that you want to keyframe on.
	*/
	- (void)setKeyFrame:(NSDictionary*)frame forView:(UIView*)view;

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
	- (void)setKeyFrameWithOffset:(CGFloat)offset
		translate:(CGPoint)translation
		scale:(CGSize)scale
		rotate:(CGFloat)rotation
		alpha:(CGFloat)alpha
		forView:(UIView*)view;

	/** @brief Removes all keyframes that were set for a given view, or if no
			view is given, then for all views.
		@param view UIView that should have keyframes removed, 
			or nil to have all keyframes removed. 
	*/
	- (void)clearKeyFrames:(UIView*)view;

	/** @brief Sets the scrollview to keyframe on during init */
	- (id)initWithScrollView:(UIScrollView*)scrollView;

@end
