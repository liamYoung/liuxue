//
//  SchoolCard.m
//  Impp
//
//  Created by Herxun on 2015/3/30.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "SchoolCard.h"
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

@interface SchoolCard ()<UITableViewDataSource, UITableViewDelegate, OTPageScrollViewDataSource,OTPageScrollViewDelegate,NSURLConnectionDataDelegate>
{
    NSTimer *theTimer;
    int Isload;
}
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic, retain) NSMutableDictionary *dicData;


@end

@implementation SchoolCard

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}

- (id)initWithData:(NSDictionary *)array
{
    if (self == [super init])
    {
        self.dicData = [NSMutableDictionary dictionaryWithDictionary:array];
    }
    Isload = 0;
    [self initView];
    theTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(executeTest) userInfo:nil repeats:YES];
    return self;
}

-(void)executeTest
{
    if (Isload==1) {
        
        NSLog(@"test excute");
        [_tableView reloadData];
        Isload = 2;
    }
}
- (void)viewWillAppear:(BOOL)animated
{
   
}

#pragma mark - Initialize

- (void)initView
{
    NSDictionary *dic = [self.dicData copy];
    
    UIImage *image = [UIImage imageNamed:@"card"];
    
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [image size].width, [image size].height)];
    UIImageView *imageViewBg = [[UIImageView alloc] initWithImage:image];
    [cell addSubview:imageViewBg];
    
    UIImageView *imageViewPic = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [image size].width, 160)];
    [imageViewPic setImageWithURL:[NSURL URLWithString:[dic objectForKey:@"pic"]]];
    imageViewPic.layer.cornerRadius = 6;
    imageViewPic.layer.masksToBounds = YES;
    [cell addSubview:imageViewPic];
    
    UIImageView *imageViewNameBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 120, cell.frame.size.width, 40)];
    [imageViewNameBg setImage:[UIImage imageNamed:@"ImageBg.png"]];
    [cell addSubview:imageViewNameBg];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, cell.frame.size.width - 40, 30)];
    label.textColor = [UIColor whiteColor];
    label.text = [dic objectForKey:@"name"];
    [imageViewNameBg addSubview:label];
    
    _cell =cell;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 159, cell.frame.size.width, 193) style:UITableViewStylePlain];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [cell addSubview:_tableView];

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@99 forKey:@"limit"];
    NSDictionary *pDic = @{@"collage": [dic objectForKey:@"name"]};
    [params setObject:pDic forKey:@"custom_fields"];
    
    [[HXAnSocialManager manager] sendRequest:@"users/search.json" method:AnSocialManagerGET params:params success:^(NSDictionary *response) {
        NSArray *array = [[response objectForKey:@"response"] objectForKey:@"users"];
        
        [self.dicData setObject:array forKey:@"usersss"];
        
        [self performSelectorOnMainThread:@selector(showNoneXuezhang) withObject:nil waitUntilDone:NO];
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
            
        }
        
        Isload=1;
    } failure:^(NSDictionary *response) {
        NSLog(@"failure log: %@",[response description]);
    }];
    
}

- (void)showNoneXuezhang
{
    NSArray *array = [self.dicData objectForKey:@"usersss"];
    if (array.count == 0)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(80, 200, 160, 40)];
        label.text = @"暂无学长...";
        [_cell addSubview:label];
    }
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
    NSArray *array = [self.dicData objectForKey:@"usersss"];
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"schoolCardcell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        NSArray *array = [self.dicData objectForKey:@"usersss"];
        NSDictionary *dic = [array objectAtIndex:indexPath.row];
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 65)];
        
        UIButton *btnInfo = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnInfo setFrame:CGRectMake(0, 0, 320, 65)];
        [btnInfo addTarget:self action:@selector(cellAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:btnInfo];
        
        UIButton *btnHead = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnHead setFrame:CGRectMake(10, 12.5, 40, 40)];
        btnHead.layer.cornerRadius = 3;
        btnHead.layer.masksToBounds = YES;

        NSString *pUrl = @"";
        if ([dic objectForKey:@"photo"] && [[dic objectForKey:@"photo"] objectForKey:@"url"]) {
            pUrl = [[dic objectForKey:@"photo"] objectForKey:@"url"];
        }
       
        [btnHead setImageWithURL:[NSURL URLWithString:pUrl] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"explore_circle"]];
        [btnHead addTarget:self action:@selector(headAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:btnHead];

        UIImage *imageLiao = [UIImage imageNamed:@"liao.png"];
        UIButton *btnLiao = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnLiao setTag:indexPath.row];
        [btnLiao setFrame:CGRectMake(160, 15, imageLiao.size.width, imageLiao.size.height)];
        [btnLiao setImage:imageLiao forState:UIControlStateNormal];
        [btnLiao addTarget:self action:@selector(talkAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:btnLiao];

        UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(60, 7, 90, 30)];

        labelName.text = [dic objectForKey:@"firstName"];
        labelName.font = [UIFont systemFontOfSize:16];
        [cell addSubview:labelName];
        
        UILabel *labelXi = [[UILabel alloc] initWithFrame:CGRectMake(60, 37, 70, 20)];
        
        if ([dic objectForKey:@"customFields"] && [[dic objectForKey:@"customFields"] objectForKey:@"major"]) {
              labelXi.text = [[dic objectForKey:@"customFields"] objectForKey:@"major"];
        }
        
        
                        [labelXi setTextColor:[UIColor grayColor]];
                        labelXi.font = [UIFont systemFontOfSize:12];
                        [cell addSubview:labelXi];
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
    
    //self.userInfo.clientId
    //self.userInfo.userName
    

                    NSLog(@"talkAction true");
                    
                    NSArray *array = [self.dicData objectForKey:@"usersss"];
                    NSDictionary *dic = [array objectAtIndex:btn.tag];
                    NSString *strClientId = [dic objectForKey:@"clientId"];
                    NSString *strName = [dic objectForKey:@"username"];
                    
                    HXChatViewController *chatVc = [[HXIMManager manager] getChatViewWithTargetClientId:strClientId targetUserName:strName currentUserName:[HXUserAccountManager manager].userName];
                    [_theSchool.navigationController pushViewController:chatVc animated:YES];
                    
                    return;

    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"AAAAAAAAAAAAAAA ");
//    HXWallViewController *vc = [[HXWallViewController alloc]initWithWallInfo:[[HXUserAccountManager manager].userInfo.toDict mutableCopy]];
//    [self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
