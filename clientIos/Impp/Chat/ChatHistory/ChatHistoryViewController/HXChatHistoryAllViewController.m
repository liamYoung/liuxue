//
//  HXChatHistoryAllViewController.m
//  Impp
//
//  Created by hsujahhu on 2015/3/17.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "HXChatHistoryAllViewController.h"
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
#import "HXCustomTableViewCell.h"
#import "UIColor+CustomColor.h"
#import <CoreData/CoreData.h>
#define VIEW_WIDTH self.view.frame.size.width

@interface HXChatHistoryAllViewController ()<UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate,UISearchBarDelegate, UISearchDisplayDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *chatHistoryArray;
@property (strong, nonatomic) NSMutableArray *chatHistoryFilterArray;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UISearchBar* searchBar;
@property (strong, nonatomic) UISearchDisplayController* searchController;
@end

@implementation HXChatHistoryAllViewController

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
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView Delegate Datasource

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"title %d",self.chatHistoryArray.count);

    if (tableView == self.searchController.searchResultsTableView)
        return self.chatHistoryFilterArray.count;
    else
        return self.chatHistoryArray.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"friendListCell";
    
    HXCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSString *title;
    NSString *photoUrl;
    NSInteger badgeValue = 0;
    
    if (tableView == self.searchController.searchResultsTableView) {
        NSMutableDictionary *dic = self.chatHistoryFilterArray[indexPath.row];
        title = [dic objectForKey:@"name"];
//        photoUrl = user.photoURL;
        
    }else{
        NSMutableDictionary *dic = self.chatHistoryArray[indexPath.row];
        title = [dic objectForKey:@"name"];
//        photoUrl = user.photoURL;
    }
    NSLog(@"title %@",title);
    
    if (cell == nil)
    {
        cell = [[HXCustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:cellIdentifier
                                                      title:title
                                                   photoUrl:photoUrl
                                                      image:[UIImage imageNamed:@"friend_default"]
                                                 badgeValue:badgeValue
                                                      style:HXCustomCellStyleDefault];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else{
        [cell reuseCellWithTitle:title photoUrl:photoUrl image:[UIImage imageNamed:@"friend_default"] badgeValue:badgeValue];
    }
//    cell.defaultDelegate = self;
    [cell setIndexValue:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    
    NSMutableDictionary *dic;
    if (tableView == self.searchController.searchResultsTableView)
        dic = self.chatHistoryFilterArray[indexPath.row];
    else
        dic = self.chatHistoryArray[indexPath.row];
    
//    BOOL isTopicMode = [chatSession.topicId isEqualToString:@""] ? NO:YES;
//    HXChatViewController *chatVc = [[HXChatViewController alloc]initWithChatInfo:chatSession setTopicMode:isTopicMode];
    
    [[[HXIMManager manager]anIM] addClients:[NSSet setWithObject:[HXIMManager manager].clientId] toTopicId:[dic objectForKey:@"id"] success:^(NSString *topicId) {
        NSLog(@"AnIM addClients successful :%@",dic);
        
         HXUser *currentUser = [HXUserAccountManager manager].userInfo;
         NSMutableArray *selectedItems = [[NSMutableArray alloc]initWithCapacity:0];
        [selectedItems addObject:currentUser];
        
        HXChat *topicChatSession = [ChatUtil createChatSessionWithUser:selectedItems                                                               topicId:[dic objectForKey:@"id"]
                                                             topicName:[dic objectForKey:@"name"]
                                                       currentUserName:[HXUserAccountManager manager].userInfo.userName
                                                    topicOwnerClientId:[dic objectForKey:@"owner"]];
        
        
        [currentUser addTopicsObject:topicChatSession];
        //[[NSNotificationCenter defaultCenter]postNotificationName:RefreshChatHistory object:nil];

        [self dismissViewControllerAnimated:YES completion:nil];

    } failure:^(ArrownockException *exception) {
        NSLog(@"AnIm addClients failed, error : %@", exception.getMessage);
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
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
//    NSError* error;
//    [self.fetchedResultsController performFetch:&error];
//    if (error) {
//        NSLog(@"error: %@", [error localizedDescription]);
//    }
//    [self.chatHistoryArray removeAllObjects];
//    
//    if ([HXUserAccountManager manager].userId) {
//        for (int i = 0; i < self.fetchedResultsController.fetchedObjects.count; i++) {
//            HXChat* chat = self.fetchedResultsController.fetchedObjects[i];
//            [self.chatHistoryArray addObject:chat];
//        }
//    }
    
//        [[[HXIMManager manager] anIM] getTopicList:[HXUserAccountManager manager].userId  success:^(NSMutableArray *topicList) {
    
    [[[HXIMManager manager] anIM] getTopicList:^(NSMutableArray *topicList) {
        NSLog(@"success log get All TopicList : %@",topicList);
        [self.chatHistoryArray removeAllObjects];
        
        [self.chatHistoryArray addObjectsFromArray:topicList];
        
        for (int i = 0; i < [self.chatHistoryArray count]; i ++)
        {
            NSLog(@"HHHHHHHHHHHH  %@", [self.chatHistoryArray objectAtIndex:i]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });

    } failure:^(ArrownockException *exception) {
        NSLog(@"failrue log get All TopicList : %@",[exception getMessage]);
    }];
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
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"ANY users.UserName contains[c] %@ || topicName contains[c] %@", searchText,searchText];
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

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HXChat"
                                              inManagedObjectContext:[CoreDataUtil sharedContext]];
    [fetchRequest setIncludesPropertyValues:NO];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat
                                :@"currentClientId == %@ && ANY messages != nil",
                                [HXIMManager manager].clientId]];
    //[fetchRequest setPredicate:nil];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updatedTimestamp"
                                                                   ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:[CoreDataUtil sharedContext]
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        // Do NOT use abort() in product.
        abort();
#endif
    }
    
    return _fetchedResultsController;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    //[self.tableView reloadData];
    return;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
