//
//  ApplyFor.h
//  LewApplyForController
//
//  Created by deng on 15/3/5.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ApplyFor : UIView <UITextFieldDelegate>
@property (nonatomic, strong)IBOutlet UIView *innerView;
@property (nonatomic, strong)IBOutlet UITextField *text1,*text2,*text3;
@property (nonatomic, strong)IBOutlet UILabel *label;
@property (nonatomic, weak)UIViewController *parentVC;


+ (instancetype)defaultApplyFor;
@end
