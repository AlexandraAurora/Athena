//
//  AthenaView.m
//  Athena
//
//  Created by Alexandra Aurora Göttlicher
//

#import "AthenaView.h"
#import "../../Preferences/PreferenceKeys.h"

@implementation AthenaView
/**
 * Initializes the Athena view.
 */
- (instancetype)init {
    self = [super init];

    if (self) {
        load_preferences();

        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:pfUseAmericanFormat ? @"hh:mm" : @"HH:mm"];

        [self setFillTimeLabel:[[UILabel alloc] init]];
        [self setOutlineTimeLabel1:[[UILabel alloc] init]];
        [self setOutlineTimeLabel2:[[UILabel alloc] init]];
        [self setOutlineTimeLabel3:[[UILabel alloc] init]];

        for (UILabel* label in @[[self fillTimeLabel], [self outlineTimeLabel1], [self outlineTimeLabel2], [self outlineTimeLabel3]]) {
            [label setFont:[UIFont fontWithName:@"Inter-BoldItalic" size:48]];
            [label setTextAlignment:pfAlignment];
            [self addSubview:label];

            [label setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [[label heightAnchor] constraintEqualToConstant:40],
                [[label leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]],
                [[label trailingAnchor] constraintEqualToAnchor:[self trailingAnchor]]
            ]];
        }

        [NSLayoutConstraint activateConstraints:@[
            [[[self outlineTimeLabel3] bottomAnchor] constraintEqualToAnchor:[self topAnchor]]
        ]];

        [NSLayoutConstraint activateConstraints:@[
            [[[self outlineTimeLabel2] topAnchor] constraintEqualToAnchor:[[self outlineTimeLabel3] bottomAnchor]]
        ]];

        [NSLayoutConstraint activateConstraints:@[
            [[[self outlineTimeLabel1] topAnchor] constraintEqualToAnchor:[[self outlineTimeLabel2] bottomAnchor]]
        ]];

        [NSLayoutConstraint activateConstraints:@[
            [[[self fillTimeLabel] topAnchor] constraintEqualToAnchor:[[self outlineTimeLabel1] bottomAnchor]]
        ]];

        [self updateLabels];
    }

    return self;
}

/**
 * Updates the labels with the current time.
 */
- (void)updateLabels {
    NSDate* now = [NSDate date];
    NSString* timeString = [_dateFormatter stringFromDate:now];

    NSDictionary* strokeTextAttributes = @{
        NSStrokeColorAttributeName: [[self textColor] colorWithAlphaComponent:1],
        NSForegroundColorAttributeName: [UIColor clearColor],
        NSStrokeWidthAttributeName: @(-4)
    };

    [[self fillTimeLabel] setText:timeString];
    [[self fillTimeLabel] setTextColor:[[self textColor] colorWithAlphaComponent:1]];

    for (UILabel* label in @[[self outlineTimeLabel1], [self outlineTimeLabel2], [self outlineTimeLabel3]]) {
        [label setAttributedText:[[NSAttributedString alloc] initWithString:timeString attributes:strokeTextAttributes]];
    }
}

/**
 * Fades the labels in or out.
 *
 * @param alpha The alpha to fade to.
 */
- (void)fadeWithAlpha:(CGFloat)alpha {
    [UIView animateWithDuration:0.5 animations:^{
        [[self fillTimeLabel] setAlpha:alpha];
        [[self outlineTimeLabel1] setAlpha:alpha];
        [[self outlineTimeLabel2] setAlpha:alpha];
        [[self outlineTimeLabel3] setAlpha:alpha];
    }];
}

/**
 * Loads the user's preferences.
 */
static void load_preferences() {
    preferences = [[NSUserDefaults alloc] initWithSuiteName:kPreferencesIdentifier];

    [preferences registerDefaults:@{
		kPreferenceKeyAlignment: @(kPreferenceKeyAlignmentDefaultValue),
		kPreferenceKeyUseAmericanFormat: @(kPreferenceKeyUseAmericanFormatDefaultValue)
    }];

	pfAlignment = [[preferences objectForKey:kPreferenceKeyAlignment] unsignedIntegerValue];
	pfUseAmericanFormat = [[preferences objectForKey:kPreferenceKeyUseAmericanFormat] boolValue];
}
@end
