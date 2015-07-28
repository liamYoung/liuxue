//
//  HXChatHistoryViewController.m
//  Impp
//
//  Created by hsujahhu on 2015/3/17.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "HXChatHistoryViewController.h"
#import "HXAppUtility.h"
#import "HXChatViewController.h"
#import "HXChat+Additions.h"
#import "HXMessage+Additions.h"
#import "HXUser+Additions.h"
#import "UserUtil.h"
#import "ChatUtil.h"
#import "MessageUtil.h"
#import "CoreDataUtil.h"
#import "HXUserAccountManager.h"
#import "NotificationCenterUtil.h"
#import "HXTabBarViewController.h"
#import "HXIMManager.h"
#import "HXChatHistoryTableViewCell.h"
#import "HXChatHistoryAllViewController.h"
#import "UIColor+CustomColor.h"
#import <CoreData/CoreData.h>
#import "HXAnSocialManager.h"
#define VIEW_WIDTH self.view.frame.size.width

@interface HXChatHistoryViewController ()<UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *chatHistoryArray;
@property (strong, nonatomic) NSMutableArray *chatHistoryFilterArray;
@property (strong, nonatomic) UISearchBar* searchBar;
@property (strong, nonatomic) UISearchDisplayController* searchController;
@end

@implementation HXChatHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initView];
    [self initNavigationBar];
    
    /* Fix search bar frame bug */
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(fetchChatHistory)
                                                name:RefreshChatHistory
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(showMessageFromNotification:)
                                                name:ShowMessageFromNotificaiton
                                              object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self fetchChatHistory];
}

#pragma mark - Init

- (void)initData
{
    self.chatHistoryArray = [[NSMutableArray alloc]initWithCapacity:0];
    self.chatHistoryFilterArray = [[NSMutableArray alloc]initWithCapacity:0];
}

- (void)initView
{
    CGRect frame;
    
    
    frame = self.view.frame;
    frame.origin.y = self.searchBar.frame.size.height + self.searchBar.frame.origin.y;
    frame.size.height -= 64 + self.tabBarController.tabBar.frame.size.height + self.searchBar.frame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:frame
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    //self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
        [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[HXAppUtility colorWithHexString:@"#ecf0f3" alpha:1.0f]];
    
    NSLog(@"success log: %@",[HXUserAccountManager manager].clientId);
    NSDictionary* params = @{@"parties":[HXUserAccountManager manager].clientId};
    
    [[HXAnSocialManager manager]sendRequest:@"http://api.arrownock.com/v1/im/topics/query.json" method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        NSLog(@"success log: %@",[response description]);
        
        NSDictionary *friendInfo = response[@"response"][@"friend"];
        HXUser * friend = [UserUtil saveUserIntoDB:friendInfo];
        [UserUtil updatedUserFriendsWithCurrentUser:[HXUserAccountManager manager].userInfo targetUser:friend];
        [[NSNotificationCenter defaultCenter] postNotificationName:RefreshFriendList object:nil];
        
    } failure:^(NSDictionary* response){
        
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
    }];
    
    
    
}

- (void)initNavigationBar
{
    [HXAppUtility initNavigationTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav_logo"]]
                             barTintColor:[UIColor color1]
                                tintColor:[UIColor color5]
                       withViewController:self];
    
    UIBarButtonItem *createBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createButtonTapped)];
    [self.navigationItem setRightBarButtonItem:createBarButton];
}

- (void)createButtonTapped
{
    HXChatHistoryAllViewController *vc = [[HXChatHistoryAllViewController alloc]init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - TableView Delegate Datasource

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 94;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchController.searchResultsTableView)
        return self.chatHistoryFilterArray.count;
    else
        return self.chatHistoryArray.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"chatHistoryCell";
    
    HXChat *chatSession;
    
    if (tableView == self.searchController.searchResultsTableView)
        chatSession = self.chatHistoryFilterArray[indexPath.row];
    else
        chatSession = self.chatHistoryArray[indexPath.row];
    
    HXMessage *lastMessage = [ChatUtil getLastMessage:chatSession];
    NSString *lastStr = [MessageUtil configureLastMessage:lastMessage];
    NSInteger unreadCount = [ChatUtil unreadCount:chatSession];
    
    NSString *userName = [NSString stringWithFormat:@"%@",chatSession.topicName];
    NSLog(@"chatSession.topicOwner:%@",chatSession.topicOwner.userName);
    
    NSString *photoUrl = chatSession.topicOwner.photoURL;

   // if ([lastStr isEqualToString:@""]) lastStr = @"...";
    
    HXChatHistoryTableViewCell *cell = [[HXChatHistoryTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                                         reuseIdentifier:cellIdentifier
                                                                                   title:userName
                                                                                subtitle:lastStr
                                                                               timestamp:lastMessage.timestamp
                                                                                photoUrl:photoUrl
                                                                        placeholderImage:[UIImage imageNamed:@"friend_default"]
                                                                              badgeValue:unreadCount];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    
    HXChat *chatSession;
    if (tableView == self.searchController.searchResultsTableView)
        chatSession = self.chatHistoryFilterArray[indexPath.row];
    else
        chatSession = self.chatHistoryArray[indexPath.row];
    
    BOOL isTopicMode = [chatSession.topicId isEqualToString:@""] ? NO:YES;
    HXChatViewController *chatVc = [[HXChatViewController alloc]initWithChatInfo:chatSession setTopicMode:isTopicMode];
    [self.navigationController pushViewController:chatVc animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        // Remove the row from data model
        NSMutableArray* chatSessions;
        if (tableView == self.searchController.searchResultsTableView)
            chatSessions = self.chatHistoryFilterArray;
        else
            chatSessions = self.chatHistoryArray;
        
        [ChatUtil deleteChatHistory:chatSessions[indexPath.row]];
        [chatSessions removeObjectAtIndex:indexPath.row];
        
        // Request table view to reload
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
        [self.tableView reloadData];
    }
}


#pragma mark - Fetch Chat History in DB
- (void)fetchChatHistory
{
    [HXUserAccountManager manager].userInfo = [UserUtil getHXUserByClientId:[HXIMManager manager].clientId];
    self.chatHistoryArray = [[[HXUserAccountManager manager].userInfo.topics allObjects]mutableCopy];
    
    self.chatHistoryArray = [[self.chatHistoryArray sortedArrayUsingComparator:(NSComparator)^(HXChat* obj1, HXChat* obj2){
        NSString *lastName1 = obj1.topicName;
        NSString *lastName2 = obj2.topicName;
        return [lastName1 compare:lastName2]; }] mutableCopy];

//    for (int i = 0; i < [self.chatHistoryArray count]; i ++)
//    {
//        NSLog(@"HHHHHHHHHHHH  %@", [self.chatHistoryArray objectAtIndex:i]);
//
//    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
#pragma mark - UISearchBar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchBar.placeholder = NSLocalizedString(@"請輸入群組名稱", nil);
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchBar.placeholder = NSLocalizedString(@"搜尋群組", nil);
}

#pragma mark - UISearchDisplayDelegate

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"userName contains[c] %@", searchText];    
    resultPredicate = [NSPredicate predicateWithFormat:@"topicName contains[c] %@", searchText];
    self.chatHistoryFilterArray = [[self.chatHistoryArray filteredArrayUsingPredicate:resultPredicate]mutableCopy];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

#pragma mark - Show remote notification chat view

- (void)showMessageFromNotification:(NSNotification *)notice
{
    NSDictionary *noticeInfo = notice.object;
    HXChat *chatSession = noticeInfo[@"chatSession"];
    BOOL isTopicMode = [noticeInfo[@"mode"] isEqualToString:@"topic"] ? YES:NO;
    HXChatViewController *chatVc = [[HXChatViewController alloc]initWithChatInfo:chatSession setTopicMode:isTopicMode];
    [self.navigationController pushViewController:chatVc animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
