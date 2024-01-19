//
//  Athena.h
//  Athena
//
//  Created by Alexandra Aurora Göttlicher
//

#import <UIKit/UIKit.h>

@class AthenaView;

NSUserDefaults* preferences;
BOOL pfEnabled;

@interface SBUILegibilityLabel : UILabel
@end

@interface SBFLockScreenDateView : UIView
@property(nonatomic)AthenaView* athenaView;
@end

@interface SBFLockScreenDateSubtitleView : UIView
@end

@interface CSTimerView : UIView
@end

@interface SBUIProudLockIconView : UIView
@end

@interface CSCombinedListViewController : UIViewController
@end
