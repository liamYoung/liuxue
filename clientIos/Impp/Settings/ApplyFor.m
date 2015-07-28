//
//  ApplyFor.m
//  LewApplyForController
//
//  Created by deng on 15/3/5.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import "ApplyFor.h"
#import "HXIMManager.h"
#import "HXUserAccountManager.h"
#import "UIViewController+LewPopupViewController.h"
#import "LewPopupViewAnimationFade.h"
#import "LewPopupViewAnimationSlide.h"
#import "LewPopupViewAnimationSpring.h"
#import "LewPopupViewAnimationDrop.h"

@implementation ApplyFor

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:[[self class] description] owner:self options:nil];
        CGRect frame2 = _innerView.frame;
        _innerView.frame = frame2;
        [self addSubview:_innerView];
    }
    [self setUserInteractionEnabled:YES];
    
    [_innerView setUserInteractionEnabled:YES];
    [_text1 setDelegate:self];
    [_text2 setDelegate:self];
    [_text3 setDelegate:self];

    return self;
}


+ (instancetype)defaultApplyFor{
    return [[ApplyFor alloc]initWithFrame:CGRectMake(0, 0, 300, 400)];
}


+ (instancetype)defaultPopupView{
    return [[ApplyFor alloc]initWithFrame:CGRectMake(0, 0, 300, 400)];
}

- (IBAction)dismissAction:(id)sender{
    if (self.text1.text.length <= 0 || self.text2.text.length <= 0 )
    {
        [_label setText:@"请输入您的大学和专业。"];
        return;
    }
    
    [_parentVC lew_dismissPopupView];
    NSDictionary *customData = @{@"name":[HXUserAccountManager manager].nickName,
                                 @"notification_alert":@"求帮助信息"};
    
    NSString *pmessage = [NSString stringWithFormat:@"学校:%@,专业：%@,邮箱：%@,ID %@",self.text1.text,self.text2.text,self.text3.text,[HXUserAccountManager manager].userId];
    
    [[[HXIMManager manager]anIM] sendMessage:pmessage
                                  customData:customData
                                   toClients:[NSSet setWithObject:@"AIMRWRND8L1EI9XPAC7YAWM"]
                              needReceiveACK:YES];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
        [self.text1 resignFirstResponder];
     [self.text2 resignFirstResponder];
     [self.text3 resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}
@end
