ParallaxScrollingFramework
==========================

Simple framework for keyframing parallax scrolling animations of UIViews in an iOS project.

Keywords: ios, iphone, ipad, parallax, scrolling, scrollview, uiview, animation, tutorial, walkthrough, framework

## About
Did you see that IFTTT app tutorial? Daymn some smooth moves there. The word on
the street was that the tutorial was made with JS/CSS/HTML5 though, and here's
my attempt at a native solution for that: the **ParallaxScrollingFramework**.

### Features of this framework:
 * Keyframe animation with any UIView based on scroll position of UIScrollView.
 * Simple, easy, integration. Works for vertical or horizontal scrolling.
 * Handles affine transforms and transparency, manages keyframes automatically.
 * Hashes UIViews to keep track of them, no need for keeping track of string keys.
 * Interpolates between keyframes linearly, working on cubic interpolation.

### Details
Properties you can keyframe on:
 - **offset :** What point on scrollView keyframe should be. Based on contentOffset.
 - **translate :** Translation, relative to frame.origin of UIView.
 - **scale :** Scaling using CGAffineTransform, negative values flip view.
 - **rotate :** Rotation using CGAffineTransform, measured in radians.
 - **alpha :** Regular ol' UIView transparency, from 0 to 1.

## Usage
You can set this up on any UIScrollView in seconds! Just a few easy steps:

 1. #import "ParallaxScrollingFramework.h"
 2. @property (nonatomic, strong) ParllaxScrollingFramework \*animator;
 3. self.animator = [[ParallaxScrollingFramework alloc] initWithScrollView:self.scrollView];

And that's it! You're ready to go. All you have to do now, is add some keyframes
for any UIView (ideally a subview of the UIScrollView). Sample code below:

	[self.animator
		setKeyFrameWithOffset:100	// Indicates where keyframe is in ScrollView
		translate:CGPointZero		// Translation, relative to frame.origin
		scale:CGSizeMake(1, 1)		// Scaling using CGAffineTransform
		rotate:0					// Rotation also using CGAffineTransform
		alpha:1
		forView:self.loginButton];

	[self.animator
		setKeyFrameWithOffset:300
		translate:CGPointMake(50, 100)
		scale:CGSizeMake(1.2, 1.2)
		rotate:0
		alpha:0.5
		forView:self.loginButton];

	// Alternate syntax, don't screw up the properties!
	//	If you don't define a property, it defaults to 0.
	[self.animator setKeyFrame:@{
		ParallaxScrollingKeyFrameOffset : @(450),
		ParallaxScrollingKeyFrameTranslateX : @(target.x),
		ParallaxScrollingKeyFrameTranslateY : @(target.y),
		ParallaxScrollingKeyFrameScaleX : @(1)
		ParallaxScrollingKeyFrameScaleY : @(2)
		ParallaxScrollingKeyFrameAlpha : @(1),
		// Omitted rotation, will default to 0
	} forView:self.loginButton];

Done!

