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

@interface School ()<OTPageScrollViewDataSource,OTPageScrollViewDelegate,NSURLConnectionDataDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *discoverArray;
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
    
    UIImage *image = [UIImage imageNamed:@"card"];
    
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [image size].width, [image size].height)];
    UIImageView *imageViewBg = [[UIImageView alloc] initWithImage:image];
    [cell addSubview:imageViewBg];
    
    UIImageView *imageViewPic = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [image size].width, 160)];
    [imageViewPic setImageWithURL:[NSURL URLWithString:[dic objectForKey:@"pic"]]];
    [cell addSubview:imageViewPic];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, cell.frame.size.width - 40, 40)];
    label.textColor = [UIColor whiteColor];
    label.text = [dic objectForKey:@"name"];
    [cell addSubview:label];
    
    UILabel *labelDes = [[UILabel alloc] initWithFrame:CGRectMake(10, 170, cell.frame.size.width - 20, 160)];
    labelDes.lineBreakMode = NSLineBreakByWordWrapping;
    labelDes.numberOfLines = 0;
    labelDes.text = [dic objectForKey:@"des"];
    [cell addSubview:labelDes];
    
    return cell;
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
