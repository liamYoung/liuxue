//
//  HXDiscoverViewController.h
//  Impp
//
//  Created by Herxun on 2015/3/30.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "School.h"
@interface SchoolCard : UIViewController
@property (strong, nonatomic) UIView *cell;

@property (strong, nonatomic) School *theSchool;
- (id)initWithData:(NSDictionary *)array;

@end

