//
//  HXFriendViewController.m
//  Impp
//
//  Created by hsujahhu on 2015/3/17.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "HXFriendViewController.h"
#import "HXIMManager.h"
#import "HXUser+Additions.h"
#import "HXUserAccountManager.h"
#import "HXAnSocialManager.h"
#import "CoreDataUtil.h"
#import "UserUtil.h"
#import "ChatUtil.h"
#import "HXFriendProfileViewController.h"
#import "HXChat+Additions.h"
#import "HXFriendRequestViewController.h"
#import "HXChatViewController.h"
#import "HXAppUtility.h"
#import "NotificationCenterUtil.h"
#import "UIColor+CustomColor.h"
#import "MessageUtil.h"
#import "HXCustomTableViewCell.h"
#import <CoreData/CoreData.h>

#define STATUS_BAR_HEIGHT [UIApplication sharedApplication].statusBarFrame.size.height
#define VIEW_WIDTH self.view.frame.size.width
#define STATIC_CELL_ARRAY @[@"新的朋友",@"群組聊天"];
#define ADD_FRIEND_REQUEST @"_ADD_FRIEND_REQUEST_"
#define FRIEND_REQUEST_APPROVE @"_FRIEND_REQUEST_APPROVE_"
#define FRIEND_REQUEST_REJECT @"_FRIEND_REQUEST_REJECT_"

@interface HXFriendViewController ()<UITableViewDataSource, UITableViewDelegate ,UIActionSheetDelegate, UISearchBarDelegate, UISearchDisplayDelegate, HXIMManagerTopicDelegate, HXCustomCellDefaultDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *friendsArray;
@property (strong, nonatomic) NSMutableArray *friendsFilterArray;
@property (strong, nonatomic) UISearchBar* contactSearchBar;
@property (strong, nonatomic) UISearchDisplayController* searchController;
@end

@implementation HXFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init
    [self initData];
    [self initView];
    [self initNavigationBar];
    
    /* Fix search bar frame bug */
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList) name:RefreshFriendList object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateList];
}

- (void)viewWillDisappear:(BOOL)animated
{

}

- (void)initData
{
    self.friendsArray = [[NSMutableArray alloc]initWithCapacity:0];
    self.friendsFilterArray = [[NSMutableArray alloc]initWithCapacity:0];
}

- (void)initView
{
    
    /* search bar */
    self.contactSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f,0.0f,VIEW_WIDTH, 44.0f)];
    [self.contactSearchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.contactSearchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.contactSearchBar setTranslucent:NO];
    [self.contactSearchBar setShowsCancelButton:NO];
    self.contactSearchBar.delegate = self;
    self.contactSearchBar.tintColor = [UIColor color11];
    self.contactSearchBar.placeholder = NSLocalizedString(@"搜尋好友", nil);
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitle:NSLocalizedString(@"取消", nil)];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor color2]];
    [self.view addSubview:self.contactSearchBar];
    
    /* search controller */
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.contactSearchBar contentsController:self];
    
    [self.searchController setValue:[NSNumber numberWithInt:UITableViewStyleGrouped]
                             forKey:@"_searchResultsTableViewStyle"];
    self.searchController.searchResultsTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.searchController.searchResultsTitle = @"沒有結果";
    [self setSearchController:self.searchController];
    [self.searchController setDelegate:self];
    [self.searchController setSearchResultsDelegate:self];
    [self.searchController setSearchResultsDataSource:self];
    
    /* tableView */
    CGRect frame = self.view.frame;
    frame.origin.y = self.contactSearchBar.frame.origin.y + self.contactSearchBar.frame.size.height;
    frame.size.height -= 64 + self.contactSearchBar.frame.size.height + self.tabBarController.tabBar.frame.size.height;
    
    self.tableView = [[UITableView alloc] initWithFrame:frame
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
}

- (void)initNavigationBar
{
    [HXAppUtility initNavigationTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav_logo"]]
                             barTintColor:[UIColor color1]
                                tintColor:[UIColor color5]
                       withViewController:self];
}

#pragma mark - Fetch Method

- (void)updateList
{
    [HXUserAccountManager manager].userInfo = [UserUtil getHXUserByClientId:[HXIMManager manager].clientId];
    self.friendsArray = [[[HXUserAccountManager manager].userInfo.friends allObjects]mutableCopy];
    self.friendsArray = [[self.friendsArray sortedArrayUsingComparator:(NSComparator)^(HXUser* obj1, HXUser* obj2){
        NSString *lastName1 = obj1.userName;
        NSString *lastName2 = obj2.userName;
        return [lastName1 compare:lastName2]; }] mutableCopy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
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
    if (tableView == self.searchController.searchResultsTableView)
    {
        return self.friendsFilterArray.count;
    }
    else
    {
        return self.friendsArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"friendListCell";
    
    HXCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSString *title;
    UIImage *image;
    NSString *photoUrl;
    NSInteger badgeValue = 0;
    if (tableView == self.searchController.searchResultsTableView) {
        HXUser *user = self.friendsFilterArray[indexPath.row];
        title = user.userName;
        image = [UIImage imageNamed:@"friend_default"];
        photoUrl = user.photoURL;

    }else{
        HXUser *user = self.friendsArray[indexPath.row];
        title = user.userName;
        image = [UIImage imageNamed:@"friend_default"];
        photoUrl = user.photoURL;
    }
    
    if (cell == nil)
    {
        cell = [[HXCustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:cellIdentifier
                                                      title:title
                                                   photoUrl:photoUrl
                                                      image:image
                                                 badgeValue:badgeValue
                                                      style:HXCustomCellStyleDefault];
         cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else{
        [cell reuseCellWithTitle:title photoUrl:photoUrl image:image badgeValue:badgeValue];
    }
    cell.defaultDelegate = self;
    [cell setIndexValue:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HXUser *user = self.friendsArray[indexPath.row];
    HXChatViewController *chatVc = [[HXIMManager manager]getChatViewWithTargetClientId:user.clientId targetUserName:user.userName currentUserName:[HXUserAccountManager manager].userName];
    [self.navigationController pushViewController:chatVc animated:YES];
}

#pragma mark - HXCustomCell default delegate

- (void)customCellPhotoTapped:(NSUInteger)index
{
//    HXFriendProfileViewController *vc = [[HXFriendProfileViewController alloc]initWithUserInfo:self.friendsArray[index]];
//    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
//    [self presentViewController:nav animated:YES completion:nil];
//    NSLog(@"%d",(int)index);
}

#pragma mark - UISearchDisplayDelegate

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"userName contains[c] %@", searchText];
    self.friendsFilterArray = [[self.friendsArray filteredArrayUsingPredicate:resultPredicate]mutableCopy];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.contactSearchBar scopeButtonTitles]
                                      objectAtIndex:[self.contactSearchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
