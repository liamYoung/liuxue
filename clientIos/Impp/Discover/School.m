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
@interface School ()<UITableViewDataSource, UITableViewDelegate, OTPageScrollViewDataSource,OTPageScrollViewDelegate,NSURLConnectionDataDelegate>{
    int Isload;
    NSTimer *theTimer;
}
@property (strong, nonatomic) NSMutableArray *commentArray;
@property (nonatomic, retain) NSMutableArray *discoverArray;
@property (nonatomic, retain) NSMutableDictionary *dicTable;
@property (nonatomic, retain) NSMutableDictionary *dicData;
@property (nonatomic, retain) NSMutableArray *temp;

@end

@implementation School


- (void)viewDidLoad {
    _commentArray = [[NSMutableArray alloc] initWithCapacity:10];
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
    
    Isload = 0;
    theTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(executeTest) userInfo:nil repeats:YES];
    return self;
}


-(void)executeTest
{
    if (Isload==1) {
        
        NSLog(@"test excute");
        Isload = 2;
        [self AddRecommendUser];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

#pragma mark - Initialize

- (void)initView
{
    /* tableView */
    UIImage *image = [UIImage imageNamed:@"card"];    
    CGRect frame = self.view.frame;
    frame.size.height -= 124;
    frame.origin.y = -10;

    OTPageView *PScrollView = [[OTPageView alloc] initWithFrame:frame];
    PScrollView.pageScrollView.dataSource = self;
    PScrollView.pageScrollView.delegate = self;
    PScrollView.pageScrollView.padding = frame.size.width - [image size].width;
    PScrollView.pageScrollView.leftRightOffset = 0;
    PScrollView.pageScrollView.frame = frame;
    [PScrollView.pageScrollView reloadData];

    [self.view setBackgroundColor:[HXAppUtility colorWithHexString:@"#ecf0f3" alpha:1.0f]];
    [self.view addSubview:PScrollView];
    
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@6 forKey:@"limit"];
    NSDictionary *pDic = @{@"recommend2": _country};
        [params setObject:pDic forKey:@"custom_fields"];
    
    [[HXAnSocialManager manager] sendRequest:@"users/search.json" method:AnSocialManagerGET params:params success:^(NSDictionary *response) {
        
        NSArray *array = [[response objectForKey:@"response"] objectForKey:@"users"];
        
        [_commentArray addObjectsFromArray:array];
        //缓存一下信息
        for (NSDictionary *user in array)
        {
            
            NSDictionary *reformedUser = [UserUtil reformUserInfoDic:user];
            
            HXUser *hxUser = [UserUtil getHXUserByUserId:reformedUser[@"userId"]];
            
            if (hxUser == nil) {
                hxUser = [HXUser initWithDict:reformedUser];
            }else{
                //update
                [hxUser setValuesFromDict:reformedUser];
            }
            Isload = 1;
            
        }
        
    } failure:^(NSDictionary *response) {
        NSLog(@"failure log: %@",[response description]);
    }];
    
}
-(void)AddRecommendUser{
    CGRect frame = CGRectMake(8, self.view.frame.size.height - 123, 15, 70);
    UILabel *pName = [[UILabel alloc] initWithFrame:frame];
    //    pName.textAlignment  = NSTextAlignmentCenter;
    pName.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:13];
    pName.text = @"达人学长";//[NSString stringWithFormat:@"%@达人学长",_country];
    pName.lineBreakMode = NSLineBreakByWordWrapping;
    pName.numberOfLines = 0;
    [self.view addSubview:pName];

    for (int i = 0; i < _commentArray.count; i++) {
        
        NSDictionary *dic =  [_commentArray objectAtIndex:i];
        UIImage *userimage;
        
        NSString *pUrl = @"";
        if ([dic objectForKey:@"photo"] && [[dic objectForKey:@"photo"] objectForKey:@"url"]) {
            pUrl = [[dic objectForKey:@"photo"] objectForKey:@"url"];
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:pUrl]];
            
            userimage =  [[UIImage alloc] initWithData:data];
            
        }
        else{
            userimage =  [UIImage imageNamed:@"friend_default"];
        }
        UIImageView *pView = [[UIImageView alloc] initWithImage:userimage];
        
        [self.view addSubview:pView];
        pView.layer.cornerRadius = 45/2;
        pView.clipsToBounds = YES;
        pView.layer.masksToBounds = YES;
        pView.frame=CGRectMake(30 + i * 50, self.view.frame.size.height - 120 ,40, 40);
        
        UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleFingerEvent:)];
        singleFingerOne.numberOfTouchesRequired = 1; //手指数
        singleFingerOne.numberOfTapsRequired = 1; //tap次数
        singleFingerOne.delegate= self;
        
        [pView addGestureRecognizer:singleFingerOne];
        pView.tag = i;
        
        
        pView.userInteractionEnabled=YES;
        
        CGRect frame = CGRectMake(30 + i * 50, self.view.frame.size.height - 85,40, 40);
        
        UILabel *pName = [[UILabel alloc] initWithFrame:frame];
        pName.textAlignment  = NSTextAlignmentCenter;
        [self.view addSubview:pName];
        UIFont *font = [UIFont fontWithName:@"STHeitiTC-Medium" size:10];
        pName.font = font;
        if ([dic objectForKey:@"firstName"]) {
            
            pName.text = [dic objectForKey:@"firstName"];
        }
        else{
            
            pName.text = [dic objectForKey:@"username"];
        }
        pName.adjustsFontSizeToFitWidth = YES;
    }
}

- (void)handleSingleFingerEvent:(UITapGestureRecognizer *)sender
{
    if(sender.numberOfTapsRequired == 1) {
        //单指单击
        NSLog(@"单指单击");
        
        NSArray *array = _commentArray;
        NSDictionary *dic = [array objectAtIndex:sender.view.tag];
        NSString *strClientId = [dic objectForKey:@"clientId"];
        NSString *strName = [dic objectForKey:@"username"];
        
        
        HXChatViewController *chatVc = [[HXIMManager manager] getChatViewWithTargetClientId:strClientId targetUserName:strName currentUserName:[HXUserAccountManager manager].userName];
        [self.navigationController pushViewController:chatVc animated:YES];
        
    }else if(sender.numberOfTapsRequired == 2){
        //单指双击
        NSLog(@"单指双击");
    }
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
