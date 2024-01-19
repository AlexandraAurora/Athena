//
//  AthenaView.m
//  Athena
//
//  Created by Alexandra Aurora Göttlicher
//

#import <UIKit/UIKit.h>

NSUserDefaults* preferences;
NSUInteger pfAlignment;
BOOL pfUseAmericanFormat;

@interface AthenaView : UIView {
    NSDateFormatter* _dateFormatter;
}
@property(nonatomic)UILabel* fillTimeLabel;
@property(nonatomic)UILabel* outlineTimeLabel1;
@property(nonatomic)UILabel* outlineTimeLabel2;
@property(nonatomic)UILabel* outlineTimeLabel3;
@property(nonatomic)UIColor* textColor;
- (void)updateLabels;
- (void)fadeWithAlpha:(CGFloat)alpha;
@end
