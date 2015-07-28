//
//  HXFriendSearchViewController.m
//  Impp
//
//  Created by Herxun on 2015/3/31.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "HXFriendSearchViewController.h"
#import "HXAppUtility.h"
#import "UIColor+CustomColor.h"
#import "UILabel+customLabel.h"
#import "UIFont+customFont.h"
#import "HXAnSocialManager.h"
#import "UIView+Toast.h"
#import "HXCustomButton.h"
#import "UserUtil.h"
#import "HXCustomTableViewCell.h"
#import "HXUserAccountManager.h"
#import "HXIMManager.h"
#import "HXFriendProfileViewController.h"
#import "HXUser+Additions.h"
#import "UIColor+CustomColor.h"

#define VIEW_WIDTH self.view.frame.size.width
@interface HXFriendSearchViewController ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, HXCustomCellSearchDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *usersArray;

@property (strong, nonatomic) NSMutableArray *allusersArray;
@property (strong, nonatomic) UISearchBar* searchBar;
@end

@implementation HXFriendSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.searchBar resignFirstResponder];
}

-(void)viewWillLayoutSubviews{
    self.navigationController.navigationBar.backItem.backBarButtonItem
    =[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"返回", nil)
                                      style:UIBarButtonItemStylePlain
                                     target:self
                                     action:nil];
}

#pragma mark - Initialize

- (id)init
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        [self initData];
        [self initView];
        [self initNavigationBar];
    }
    return self;
}

- (void)initData
{
    self.usersArray = [[NSMutableArray alloc]initWithCapacity:0];
    self.allusersArray = [[NSMutableArray alloc]initWithCapacity:0];
}
-(void)LetUserTOMaster{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    //        //[HXUserAccountManager manager].userInfo.userId
    //        HXChat* chat = chatSessions[indexPath.row];
    //        NSSet *pusers = chat.users;
    //        HXUser *target = (HXUser*)[pusers.allObjects  objectAtIndex:0];
    //        NSLog(@"clientId%@",target.userId);
    //        NSLog(@"userName%@",target.userName);
    //
    //        NSLog(@"userName%@",target.clientId);
    //
    //        NSLog(@"userName%@",target.currentUserId);
    [params setObject:@"55b7271f3641d800000008af" forKey:@"user_id"];
    
    //1 用户  0 管理员  X 》 100 学长  X-100 = 积分
    [params setObject:[NSNumber numberWithInt:100] forKey:@"age"];
    [params setObject:@"曼彻斯特大学" forKey:@"last_name"];
    NSDictionary *customData = @{@"collage":@"曼彻斯特城市大学",@"major":@"会计系",@"recommend2":@"英国"};
    //@"recommend1":@"ALL",
    [params setObject:customData forKey:@"custom_fields"];
    
    
    [[HXAnSocialManager manager]sendRequest:@"users/update.json" method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        
        NSLog(@"success log: %@",[response description]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (response[@"response"][@"user"][@"photo"]) {
                NSString *photoUrl = response[@"response"][@"user"][@"photo"][@"url"];
                [HXUserAccountManager manager].userInfo.photoURL = photoUrl;
                NSError *error;
                [[CoreDataUtil sharedContext] save:&error];
                if (error) {
                    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                }
            }
            
        });
        
        
    }failure:^(NSDictionary* response){
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
        
        if ([response objectForKey:@"meta"]) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"無法更改"
                                                            message:@"出現一點問題"
                                                           delegate:nil
                                                  cancelButtonTitle:@"好"
                                                  otherButtonTitles:nil, nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        }
        
    }];
    
}
-(void)lookAllUser{
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
   [params setObject:@"999" forKey:@"limit"];
    [params setObject:@"U001" forKey:@"userName"];
    
    [[HXAnSocialManager manager]sendRequest:@"users/search.json" method:AnSocialManagerGET params:params success:^(NSDictionary* response){
        NSLog(@"lookAllUser success log: %@",[response description]);
        NSMutableArray *tempUsersArray = [response[@"response"][@"users"] mutableCopy];
        
        
        /* To sync with server*/
        [self.allusersArray removeAllObjects];
        [self.allusersArray addObjectsFromArray:tempUsersArray];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self   deleteAllUser];
        });
        
    } failure:^(NSDictionary* response){
        
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
    }];
}
-(void)deleteAllUser{
    
     NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *paramsis = [[NSMutableArray alloc] init];
    for (int i=0; i < self.allusersArray.count; i++) {
       NSDictionary *PPro =   [self.allusersArray objectAtIndex:i];
       [paramsis addObject:[PPro objectForKey:@"id"]];
    }
    
    NSString *string = [paramsis componentsJoinedByString:@","];
    
    [params setObject:string forKey:@"user_ids"];
    
    [[HXAnSocialManager manager] sendRequest:@"users/delete.json" method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        NSLog(@"deleteAllUser success log: %@",[response description]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
         
        });
        
    } failure:^(NSDictionary* response){
        
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
    }];
}
- (void)initView
{
    /* search bar */
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f,0.0f, VIEW_WIDTH, 44.0f)];
    [self.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.searchBar setTranslucent:NO];
    [self.searchBar setShowsCancelButton:NO];
    self.searchBar.delegate = self;
    self.searchBar.tintColor = [UIColor color11];
    self.searchBar.placeholder = NSLocalizedString(@"請輸入好友名稱並按下搜尋", nil);
    [self.view addSubview:self.searchBar];
    
    /* tableView */
    CGRect frame = self.view.frame;
    frame.size.height -= 64 + self.searchBar.frame.size.height;
    frame.origin.y = self.searchBar.frame.origin.y + self.searchBar.frame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:frame
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(50, 50, 200, 75);
    button.tag = 0;
    
    [button setTitle:@"deleteAllUser" forState:UIControlStateNormal];
    
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [button addTarget:self action:@selector(lookAllUser)  forControlEvents :UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button2.frame = CGRectMake(50, 90, 200, 75);
    button2.tag = 0;
    
    [button2 setTitle:@"beMaster" forState:UIControlStateNormal];
    
    [button2.titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [button2 addTarget:self action:@selector(LetUserTOMaster)  forControlEvents :UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
}

- (void)initNavigationBar
{
    [HXAppUtility initNavigationTitle:NSLocalizedString(@"加入新好友", nil) barTintColor:[UIColor color1] withViewController:self];
}

#pragma mark - Table view delegate method

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.usersArray.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"friendSearchCell";
    
    HXCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    HXUser *user = self.usersArray[indexPath.row];
    
    if (cell == nil)
    {
        cell = [[HXCustomTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier title:user.userName photoUrl:user.photoURL image:[UIImage imageNamed:@"friend_default"] badgeValue:0 style:HXCustomCellStyleSearch];
    }else{
        [cell reuseCellWithTitle:user.userName photoUrl:user.photoURL image:[UIImage imageNamed:@"friend_default"] badgeValue:0];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    [cell setButtonTag:indexPath.row];
    
    if ([UserUtil checkFriendRelationshipWithCliendId:user.clientId]) {
        
        [cell showLabelWithTitle:NSLocalizedString(@"已是好友", nil)];
        
    }else if ([UserUtil checkFollowRelationshipWithCliendId:user.clientId]){
        
        [cell updateTitle:NSLocalizedString(@"已送邀請", nil) TitleColor:[UIColor color1]];
        [cell setButtonDisable];
        
    }else{
        [cell updateTitle:NSLocalizedString(@"加入好友", nil) TitleColor:[UIColor color3]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - HXCustomCell search delegate

- (void)customCellButtonTapped:(UIButton *)sender
{
    HXUser *user = self.usersArray[sender.tag];
    HXCustomButton *button = (HXCustomButton *)sender;
    [button updateTitle:NSLocalizedString(@"已送邀請", nil) TitleColor:[UIColor color1]];
    button.enabled = NO;
    NSDictionary *params = @{@"user_id":[HXUserAccountManager manager].userId,
                             @"target_user_id":user.userId};
    
    [[HXAnSocialManager manager]sendRequest:@"friends/requests/send.json" method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        NSLog(@"success log: %@",[response description]);
        
    } failure:^(NSDictionary* response){
        
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
    }];
    
    params = @{@"user_id":[HXUserAccountManager manager].userId,
               @"target_user_id":user.userId};
    NSLog(@"target_user_id:%@",user.userId);
    [[HXAnSocialManager manager]sendRequest:@"friends/add.json" method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        NSLog(@"success log: %@",[response description]);
        
        HXUser *user = [UserUtil saveUserIntoDB:response[@"response"][@"friend"]];
        [UserUtil updatedUserFollowsWithCurrentUser:[HXUserAccountManager manager].userInfo targetUser:user];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view makeImppToast:NSLocalizedString(@"發送好友請求成功", nil) navigationBarHeight:64];
        });
    } failure:^(NSDictionary* response){
        
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
    }];
    
    [[HXIMManager manager] sendFriendRequestMessageWithClientId:user.clientId targetUserName:user.userName];
    
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:searchBar.text forKey:@"username"];
    
    [[HXAnSocialManager manager]sendRequest:@"users/search.json" method:AnSocialManagerGET params:params success:^(NSDictionary* response){
        NSLog(@"success log: %@",[response description]);
        NSMutableArray *tempUsersArray = [response[@"response"][@"users"] mutableCopy];
    
        
        /* To sync with server*/
        [self.usersArray removeAllObjects];
        
        for (NSDictionary *user in tempUsersArray)
        {
            
            NSDictionary *reformedUser = [UserUtil reformUserInfoDic:user];
            
            HXUser *hxUser = [UserUtil getHXUserByUserId:reformedUser[@"userId"]];
            
            if (hxUser == nil) {
                hxUser = [HXUser initWithDict:reformedUser];
            }else{
                //update
                [hxUser setValuesFromDict:reformedUser];
            }
            
            if (![hxUser.clientId isEqualToString:[HXIMManager manager].clientId]) {
                [self.usersArray addObject:hxUser];
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
       
    } failure:^(NSDictionary* response){
        
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
