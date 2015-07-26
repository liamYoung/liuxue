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

@interface School ()<UITableViewDataSource, UITableViewDelegate, OTPageScrollViewDataSource,OTPageScrollViewDelegate,NSURLConnectionDataDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *discoverArray;
@property (nonatomic, retain) NSMutableDictionary *dicTable;
@property (nonatomic, retain) NSMutableDictionary *dicData;

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
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 160, cell.frame.size.width, 190) style:UITableViewStylePlain];
//    [tableView setBackgroundColor:[UIColor redColor]];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [cell addSubview:tableView];
    
    [self.dicTable setObject:tableView forKey:[NSString stringWithFormat:@"%d", index]];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@99 forKey:@"limit"];
    [params setObject:@"yang" forKey:@"username"];
    //    [params setObject:[dic objectForKey:@"name"] forKey:@"XXX"];
    
    [[HXAnSocialManager manager] sendRequest:@"users/search.json" method:AnSocialManagerGET params:params success:^(NSDictionary *response) {
        NSLog(@"success log: %@",[response description]);
        NSArray *array = [[response objectForKey:@"response"] objectForKey:@"users"];
        [self.dicData setObject:array forKey:[NSString stringWithFormat:@"%d", index]];
        [tableView reloadData];
//        for (int i = 0; i < [array count]; i ++)
//        {
//            NSDictionary *dicXuejie = [array objectAtIndex:i];
//            [self.dicTable setObject:array forKey:[NSString stringWithFormat:@"%d", index]];
//
//            //[NSURL URLWithString:[[dicXuejie objectForKey:@"photo"] objectForKey:@"url"]]
////            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
////            [btn setFrame:CGRectMake(i * 50, 310, 40, 40)];
////            [btn setImageWithURL:[NSURL URLWithString:[dic objectForKey:@"pic"]] forState:UIControlStateNormal];
////            [cell addSubview:btn];
////            [btn setTag:i];
////            [btn addTarget:self action:@selector(xuejieChose:) forControlEvents:UIControlEventTouchUpInside];
//        }
    } failure:^(NSDictionary *response) {
        NSLog(@"failure log: %@",[response description]);
    }];


    return cell;
}

#pragma mark - Table view delegate method

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    for (id key in self.dicTable)
    {
        if ([tableView isEqual:[self.dicTable objectForKey:key]])
        {
            for (id key2 in self.dicTable)
            {
                if ([key isEqualToString:key2])
                {
                    NSLog(@"Find key3 : %@ , value3: %@",key2,[self.dicTable objectForKey:key2]);
                    NSArray *array = [self.dicData objectForKey:key2];
                    return [array count];
                }
            }
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"discoverCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        for (id key in self.dicTable)
        {
            if ([tableView isEqual:[self.dicTable objectForKey:key]])
            {
                for (id key2 in self.dicTable)
                {
                    if ([key isEqualToString:key2])
                    {
                        NSLog(@"Find key3 : %@ , value3: %@",key2,[self.dicTable objectForKey:key2]);
                        NSArray *array = [self.dicData objectForKey:key2];
                        NSDictionary *dic = [array objectAtIndex:indexPath.row];
//                        cell = [[HXCustomTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier title:[dic objectForKey:@"username"] photoUrl:nil image:[UIImage imageNamed:@"explore_circle"] badgeValue:0 style:HXCustomCellStyleDefault];
                        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 65)];
                        
                        UIButton *btnInfo = [UIButton buttonWithType:UIButtonTypeCustom];
                        [btnInfo setFrame:CGRectMake(0, 0, 320, 65)];
//                        [btnInfo setImageWithURL:[NSURL URLWithString:[dic objectForKey:@"pic"]] forState:UIControlStateNormal];
                        [btnInfo addTarget:self action:@selector(cellAction:) forControlEvents:UIControlEventTouchUpInside];
                        [cell addSubview:btnInfo];
                        
                        UIButton *btnHead = [UIButton buttonWithType:UIButtonTypeCustom];
                        [btnHead setFrame:CGRectMake(10, 20, 50, 50)];
                        [btnHead setImageWithURL:[NSURL URLWithString:@""] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"explore_circle"]];
                        [btnHead addTarget:self action:@selector(headAction:) forControlEvents:UIControlEventTouchUpInside];
                        [cell addSubview:btnHead];

                        UIButton *btnLiao = [UIButton buttonWithType:UIButtonTypeCustom];
                        [btnLiao setFrame:CGRectMake(0, 0, 60, 40)];
                        [btnLiao setImageWithURL:[NSURL URLWithString:@""] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"explore_circle"]];
                        [btnLiao addTarget:self action:@selector(talkAction:) forControlEvents:UIControlEventTouchUpInside];
                        [cell addSubview:btnLiao];

                        
                        UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(75, 5, 120, 40)];
                        labelName.text = [dic objectForKey:@"username"];
                        labelName.font = [UIFont systemFontOfSize:30];
                        [cell addSubview:labelName];
                        
                        UILabel *labelXi = [[UILabel alloc] initWithFrame:CGRectMake(60, 45, cell.frame.size.width - 120, 40)];
                        labelXi.text = [dic objectForKey:@"updated_at"];
                        [cell addSubview:labelXi];

                    }
                }
            }
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)cellAction:(UIButton *)btn
{
    NSLog(@"cellAction %d", btn.tag);
}

- (void)headAction:(UIButton *)btn
{
    NSLog(@"headAction %d", btn.tag);
}

- (void)talkAction:(UIButton *)btn
{
    NSLog(@"talkAction %d", btn.tag);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"AAAAAAAAAAAAAAA ");
//    HXWallViewController *vc = [[HXWallViewController alloc]initWithWallInfo:[[HXUserAccountManager manager].userInfo.toDict mutableCopy]];
//    [self.navigationController pushViewController:vc animated:YES];
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
