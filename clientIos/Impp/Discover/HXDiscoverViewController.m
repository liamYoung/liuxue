//
//  HXDiscoverViewController.m
//  Impp
//
//  Created by Herxun on 2015/3/30.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "HXDiscoverViewController.h"
#import "HXAppUtility.h"
#import "HXWallViewController.h"
#import "HXUserAccountManager.h"
#import "HXCustomTableViewCell.h"
#import "NotificationCenterUtil.h"
#import "UIColor+CustomColor.h"
#import "School.h"
#import "OTPageScrollView.h"
#import "OTPageView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HXAppUtility.h"
#import "HXAnSocialManager.h"
#import "UserUtil.h"
#import "HXChatViewController.h"
#import "HXIMManager.h"
@interface HXDiscoverViewController ()<NSURLConnectionDataDelegate,OTPageScrollViewDataSource,OTPageScrollViewDelegate,UIGestureRecognizerDelegate>{
    int Isload;
     NSTimer *theTimer;
}
@property (strong, nonatomic) NSMutableArray *commentArray;
@property (strong, nonatomic) NSMutableArray *discoverArray;
@end

@implementation HXDiscoverViewController

- (void)viewDidLoad {
   _commentArray = [[NSMutableArray alloc] initWithCapacity:10];
    [super viewDidLoad];
    [self initData];
    [self initNavigationBar];
    Isload = 0;
    theTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(executeTest) userInfo:nil repeats:YES];

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
    frame.size.height -= 64;
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
    NSDictionary *pDic = @{@"recommend1": @"ALL"};
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

-(void)AddRecommendUser
{
//    CGRect frame = CGRectMake(0,self.view.frame.size.height - 167 ,90,50);
//    UILabel *pName = [[UILabel alloc] initWithFrame:frame];
//    pName.textAlignment  = NSTextAlignmentCenter;
//    [self.view addSubview:pName];
//    UIFont *font = [UIFont fontWithName:@"STHeitiTC-Medium" size:12];
//    pName.font = font;
//    pName.text = @"留学达人：";
    
    for (int i = 0; i < _commentArray.count; i++)
    {
        NSDictionary *dic =  [_commentArray objectAtIndex:i];
        UIImage *userimage;
        
        NSString *pUrl = @"";
        if ([dic objectForKey:@"photo"] && [[dic objectForKey:@"photo"] objectForKey:@"url"]) {
            pUrl = [[dic objectForKey:@"photo"] objectForKey:@"url"];
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:pUrl]];
            userimage =  [[UIImage alloc] initWithData:data];
        }
        else
        {
            userimage =  [UIImage imageNamed:@"friend_default"];
        }
        
        UIImageView *pView = [[UIImageView alloc] initWithImage:userimage];
        
        [self.view addSubview:pView];
        pView.layer.cornerRadius = 45/2;
        pView.clipsToBounds = YES;
        pView.layer.masksToBounds = YES;
        pView.frame=CGRectMake(10 + i * 60, self.view.frame.size.height - 120, 50, 50);
        
        UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleFingerEvent:)];
        singleFingerOne.numberOfTouchesRequired = 1; //手指数
        singleFingerOne.numberOfTapsRequired = 1; //tap次数
        singleFingerOne.delegate= self;

        [pView addGestureRecognizer:singleFingerOne];
        pView.tag = i;
        pView.userInteractionEnabled=YES;
        
        CGRect frame = CGRectMake(10+i*60,self.view.frame.size.height - 85 ,50,50);
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

    NSString *str = [[[dic objectForKey:@"des"] stringByAppendingString:[dic objectForKey:@"des"]] stringByAppendingString:[dic objectForKey:@"des"]];
    UIFont *font = [UIFont systemFontOfSize:13];
    CGSize size = CGSizeMake(cell.frame.size.width - 20,135);
    CGRect labelRect = [str boundingRectWithSize:size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  attributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName] context:nil];
    UILabel *labelDes = [[UILabel alloc]initWithFrame:CGRectMake(10, 170, labelRect.size.width, labelRect.size.height)];
    labelDes.text = str;
    labelDes.font = [UIFont systemFontOfSize:13];
    labelDes.lineBreakMode = NSLineBreakByWordWrapping;
    labelDes.numberOfLines = 0;
    [cell addSubview:labelDes];
    
//    UILabel *labelDes = [[UILabel alloc] initWithFrame:CGRectMake(10, 170, cell.frame.size.width - 20, 135)];
//    labelDes.lineBreakMode = NSLineBreakByWordWrapping;
//    labelDes.numberOfLines = 0;
////    [labelDes setBackgroundColor:[UIColor redColor]];
//    labelDes.text = [dic objectForKey:@"des"];
//    [cell addSubview:labelDes];

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

- (void)initData
{
    NSString *URLPath = [NSString stringWithFormat:@"http://7xkmqv.com1.z0.glb.clouddn.com/configSchoolCon.json"];
    NSURL *URL = [NSURL URLWithString:URLPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL
                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                            timeoutInterval:20.0];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
        
        if (!error && responseCode == 200) {
            id res = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

            NSLog(@"res %@", res);

            if (res && [res isKindOfClass:[NSArray class]])
            {
                self.discoverArray = [res copy];
                [self initView];
            } else {
                NSLog(@"error 1.");
            }
        } else {
            NSLog(@"error 2.");
        }
    }];
}

- (void)pageScrollView:(OTPageScrollView *)pageScrollView didTapPageAtIndex:(NSInteger)index{
    NSLog(@"didTapPageAtIndex cell at %d",index);
    
    NSDictionary *dic = [self.discoverArray objectAtIndex:index];
    School *school = [[School alloc] initWithData:[dic objectForKey:@"school"]];
    school.country = [dic objectForKey:@"name"];
    
    [self.navigationController pushViewController:school animated:YES];
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
