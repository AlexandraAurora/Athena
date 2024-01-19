//
//  Athena.m
//  Athena
//
//  Created by Alexandra Aurora Göttlicher
//

#import "Athena.h"
#import <substrate.h>
#import <rootless.h>
#import <CoreText/CoreText.h>
#import "Views/AthenaView.h"
#import "../Preferences/PreferenceKeys.h"

#pragma mark - SBFLockScreenDateView class properties

static AthenaView* athenaView(SBFLockScreenDateView* self, SEL _cmd) {
    return (AthenaView *)objc_getAssociatedObject(self, (void *)athenaView);
};
static void setAthenaView(SBFLockScreenDateView* self, SEL _cmd, AthenaView* rawValue) {
    objc_setAssociatedObject(self, (void *)athenaView, rawValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - SBFLockScreenDateView class hooks

/**
 * Sets up the Athena view.
 *
 * @param frame
 *
 * @return self
 */
static SBFLockScreenDateView* (* orig_SBFLockScreenDateView_initWithFrame)(SBFLockScreenDateView* self, SEL _cmd, CGRect frame);
static SBFLockScreenDateView* override_SBFLockScreenDateView_initWithFrame(SBFLockScreenDateView* self, SEL _cmd, CGRect frame) {
	SBFLockScreenDateView* orig = orig_SBFLockScreenDateView_initWithFrame(self, _cmd, frame);

	SBUILegibilityLabel* timeLabel = [self valueForKey:@"_timeLabel"];
	[timeLabel removeFromSuperview];

	[self setAthenaView:[[AthenaView alloc] init]];
	[[self athenaView] setTextColor:[timeLabel textColor]];
	[self addSubview:[self athenaView]];

	[[self athenaView] setTranslatesAutoresizingMaskIntoConstraints:NO];
	[NSLayoutConstraint activateConstraints:@[
		[[[self athenaView] topAnchor] constraintEqualToAnchor:[self topAnchor] constant:32],
		[[[self athenaView] leadingAnchor] constraintEqualToAnchor:[self leadingAnchor] constant:16],
		[[[self athenaView] trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-16],
		[[[self athenaView] bottomAnchor] constraintEqualToAnchor:[self bottomAnchor]]
	]];

	return orig;
}

/**
 * Updates Athena's clock whenever iOS would update the stock one.
 */
static void (* orig_SBFLockScreenDateView__updateLabels)(SBFLockScreenDateView* self, SEL _cmd);
static void override_SBFLockScreenDateView__updateLabels(SBFLockScreenDateView* self, SEL _cmd) {
	orig_SBFLockScreenDateView__updateLabels(self, _cmd);

	SBUILegibilityLabel* timeLabel = [self valueForKey:@"_timeLabel"];
	[[self athenaView] setTextColor:[timeLabel textColor]];

	// The labels are updated too soon, so we have to wait a tiny bit.
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[[self athenaView] updateLabels];
	});
}

/**
 * Updates Athena's clock alpha whenever iOS would update the stock one.
 */
static void (* orig_SBFLockScreenDateView__updateLabelAlpha)(SBFLockScreenDateView* self, SEL _cmd);
static void override_SBFLockScreenDateView__updateLabelAlpha(SBFLockScreenDateView* self, SEL _cmd) {
	orig_SBFLockScreenDateView__updateLabelAlpha(self, _cmd);
	UILabel* timeLabel = [self valueForKey:@"_timeLabel"];
	[[self athenaView] fadeWithAlpha:[timeLabel alpha]];
}

#pragma mark - SBFLockScreenDateSubtitleView class hooks

/**
 * Removes the date and charging label.
 */
static void (* orig_SBFLockScreenDateSubtitleView_didMoveToWindow)(SBFLockScreenDateSubtitleView* self, SEL _cmd);
static void override_SBFLockScreenDateSubtitleView_didMoveToWindow(SBFLockScreenDateSubtitleView* self, SEL _cmd) {
	orig_SBFLockScreenDateSubtitleView_didMoveToWindow(self, _cmd);
	[self removeFromSuperview];
}

#pragma mark - CSTimerView class hooks

/**
 * Removes the timer view.
 *
 * @param frame
 *
 * @return self
 */
static CSTimerView* (* orig_CSTimerView_initWithFrame)(CSTimerView* self, SEL _cmd, CGRect frame);
static CSTimerView* override_CSTimerView_initWithFrame(CSTimerView* self, SEL _cmd, CGRect frame) {
	return nil;
}

#pragma mark - SBUIProudLockIconView class hooks

/**
 * Decreases the proud lock's size and moves it down.
 *
 * @param frame
 */
static void (* orig_SBUIProudLockIconView_setFrame)(SBUIProudLockIconView* self, SEL _cmd, CGRect frame);
static void override_SBUIProudLockIconView_setFrame(SBUIProudLockIconView* self, SEL _cmd, CGRect frame) {
	orig_SBUIProudLockIconView_setFrame(self, _cmd, frame);
	[self setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
	[self setCenter:CGPointMake(self.center.x, self.center.y + 20)];
}

#pragma mark - CSCombinedListViewController class hooks

/**
 * Pushes the notifications down.
 *
 * @return The edge insets.
 */
static UIEdgeInsets (* orig_CSCombinedListViewController__listViewDefaultContentInsets)(CSCombinedListViewController* self, SEL _cmd);
static UIEdgeInsets override_CSCombinedListViewController__listViewDefaultContentInsets(CSCombinedListViewController* self, SEL _cmd) {
	UIEdgeInsets orig = orig_CSCombinedListViewController__listViewDefaultContentInsets(self, _cmd);
	orig.top += 25;
	return orig;
}

#pragma mark - Preferences

/**
 * Loads the user's preferences.
 */
static void load_preferences() {
    preferences = [[NSUserDefaults alloc] initWithSuiteName:kPreferencesIdentifier];

    [preferences registerDefaults:@{
        kPreferenceKeyEnabled: @(kPreferenceKeyEnabledDefaultValue)
    }];

    pfEnabled = [[preferences objectForKey:kPreferenceKeyEnabled] boolValue];
}

/**
 * Initializes the tweak.
 */
__attribute((constructor)) static void initialize() {
	load_preferences();

    if (!pfEnabled) {
        return;
    }

	// Load the font into memory.
	NSData* data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:ROOT_PATH_NS(@"/var/mobile/Library/codes.aurora.athena/Inter-BoldItalic.ttf")]];
	CFErrorRef error;
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGFontRef font = CGFontCreateWithDataProvider(provider);
	if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
		CFStringRef errorDescription = CFErrorCopyDescription(error);
		CFRelease(errorDescription);
	}
	CFRelease(font);
	CFRelease(provider);

	class_addProperty(NSClassFromString(@"SBFLockScreenDateView"), "athenaView", (objc_property_attribute_t[]){{"T", "@\"AthenaView\""}, {"N", ""}, {"V", "_athenaView"}}, 3);
	class_addMethod(NSClassFromString(@"SBFLockScreenDateView"), @selector(setAthenaView:), (IMP)&setAthenaView, "v@:@");
	class_addMethod(NSClassFromString(@"SBFLockScreenDateView"), @selector(athenaView), (IMP)&athenaView, "@@:");

    MSHookMessageEx(objc_getClass("SBFLockScreenDateView"), @selector(initWithFrame:), (IMP)&override_SBFLockScreenDateView_initWithFrame, (IMP *)&orig_SBFLockScreenDateView_initWithFrame);
	MSHookMessageEx(objc_getClass("SBFLockScreenDateView"), @selector(_updateLabels), (IMP)&override_SBFLockScreenDateView__updateLabels, (IMP *)&orig_SBFLockScreenDateView__updateLabels);
	MSHookMessageEx(objc_getClass("SBFLockScreenDateView"), @selector(_updateLabelAlpha), (IMP)&override_SBFLockScreenDateView__updateLabelAlpha, (IMP *)&orig_SBFLockScreenDateView__updateLabelAlpha);
	MSHookMessageEx(objc_getClass("SBFLockScreenDateSubtitleView"), @selector(didMoveToWindow), (IMP)&override_SBFLockScreenDateSubtitleView_didMoveToWindow, (IMP *)&orig_SBFLockScreenDateSubtitleView_didMoveToWindow);
	MSHookMessageEx(objc_getClass("CSTimerView"), @selector(initWithFrame:), (IMP)&override_CSTimerView_initWithFrame, (IMP *)&orig_CSTimerView_initWithFrame);
	MSHookMessageEx(objc_getClass("SBUIProudLockIconView"), @selector(setFrame:), (IMP)&override_SBUIProudLockIconView_setFrame, (IMP *)&orig_SBUIProudLockIconView_setFrame);
	MSHookMessageEx(objc_getClass("CSCombinedListViewController"), @selector(_listViewDefaultContentInsets), (IMP)&override_CSCombinedListViewController__listViewDefaultContentInsets, (IMP *)&orig_CSCombinedListViewController__listViewDefaultContentInsets);
}
