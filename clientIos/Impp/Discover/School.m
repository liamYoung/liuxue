//
//  School.m
//  Impp
//
//  Created by Herxun on 2015/3/30.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "School.h"
#import "HXAppUtility.h"
#import "HXWallViewController.h"
#import "HXUserAccountManager.h"
#import "HXCustomTableViewCell.h"
#import "NotificationCenterUtil.h"
#import "UIColor+CustomColor.h"
#import "OTPageScrollView.h"
#import "OTPageView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HXAppUtility.h"
#import "HXAnSocialManager.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "HXChatViewController.h"
#import "HXIMManager.h"
#import "UserUtil.h"
#import "SchoolCard.h"
@interface School ()<UITableViewDataSource, UITableViewDelegate, OTPageScrollViewDataSource,OTPageScrollViewDelegate,NSURLConnectionDataDelegate>
@property (nonatomic, retain) NSMutableArray *discoverArray;
@property (nonatomic, retain) NSMutableDictionary *dicTable;
@property (nonatomic, retain) NSMutableDictionary *dicData;
@property (nonatomic, retain) NSMutableArray *temp;

@end

@implementation School

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self initNavigationBar];
}

- (id)initWithData:(NSArray *)array
{
    if (self == [super init])
    {
        self.discoverArray = [array copy];
        self.dicTable = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.dicData = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.temp = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

#pragma mark - Initialize

- (void)initView
{
    /* tableView */
    CGRect frame = self.view.frame;
    frame.size.height -= 124;
    frame.origin.y = 0;

    OTPageView *PScrollView = [[OTPageView alloc] initWithFrame:frame];
    PScrollView.pageScrollView.dataSource = self;
    PScrollView.pageScrollView.delegate = self;
    PScrollView.pageScrollView.padding = 76;
    PScrollView.pageScrollView.leftRightOffset = 0;
    PScrollView.pageScrollView.frame = frame;
    [PScrollView.pageScrollView reloadData];

    [self.view setBackgroundColor:[HXAppUtility colorWithHexString:@"#ecf0f3" alpha:1.0f]];
    [self.view addSubview:PScrollView];
}

- (NSInteger)numberOfPageInPageScrollView:(OTPageScrollView*)pageScrollView{
    return [self.discoverArray count];
}

- (UIView*)pageScrollView:(OTPageScrollView*)pageScrollView viewForRowAtIndex:(int)index{
    NSDictionary *dic = self.discoverArray[index];
    
    SchoolCard *pcard = [[SchoolCard alloc] initWithData:dic];
    [_temp addObject:pcard];
    pcard.theSchool = self;
    
    return pcard.cell;
}

- (CGSize)sizeCellForPageScrollView:(OTPageScrollView*)pageScrollView
{
    UIImage *image = [UIImage imageNamed:@"card"];
    return CGSizeMake([image size].width, [image size].height);
}


- (void)initNavigationBar
{
    [HXAppUtility initNavigationTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav_logo"]]
                             barTintColor:[UIColor color1]
                                tintColor:[UIColor color5]
                       withViewController:self];
}

- (void)pageScrollView:(OTPageScrollView *)pageScrollView didTapPageAtIndex:(NSInteger)index{
    NSLog(@"didTapPageAtIndex cell at %d",index);
    
//    NSDictionary *dic = [self.discoverArray objectAtIndex:index];
//    School *school = [[School alloc] initWithData:[dic objectForKey:@"school"]];
//    [self.navigationController pushViewController:school animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    NSLog(@"scrollViewDidEndDecelerating cell at %d",index);
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
