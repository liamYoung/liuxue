//
//  HXUserAccountManager.m
//  IMChat
//
//  Created by Herxun on 2015/1/8.
//  Copyright (c) 2015年 Herxun. All rights reserved.
//

#import "HXUserAccountManager.h"
#import "HXAnSocialManager.h"
#import "HXIMManager.h"
#import "UserUtil.h"
#import "HXAnSocialManager.h"
#import "AnSocialPathConstant.h"
@interface HXUserAccountManager ()
@property (strong, nonatomic) NSMutableDictionary *clientIdToContactsInfoDic;
@end

@implementation HXUserAccountManager
#pragma mark - Init

+ (HXUserAccountManager *)manager
{
    static HXUserAccountManager *_manager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _manager = [[HXUserAccountManager alloc] init];
    });
    return _manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.likeDic = [[NSMutableDictionary alloc]initWithCapacity:0];
    }
    return self;
}

- (void)saveContactsIds:(NSArray *)contacts
{
    if (!self.clientIdToContactsInfoDic)
        self.clientIdToContactsInfoDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    [contacts enumerateObjectsUsingBlock:^(id contact, NSUInteger idx, BOOL *stop) {
        if (contact[@"clientId"])
            [self.clientIdToContactsInfoDic setObject:contact forKey:contact[@"clientId"]];
    }];
}

- (NSDictionary *)getContactInfoForClientId:(NSString *)clientId
{
    return self.clientIdToContactsInfoDic[clientId];
}

- (void)userSignedInWithId:(NSString *)userId name:(NSString *)name clientId:(NSString *)clientId
{
    self.userId = userId;
    self.userName = name;
    self.clientId = clientId;
    if ( self.userInfo.nickName != nil) {
        self.nickName = self.userInfo.nickName;
    }
    else{
        self.nickName =name;
    }
    self.photoUrl = self.userInfo.photoURL;
    self.coverPhotoUrl = self.userInfo.coverPhotoURL;
    self.email = @"";

    [[HXAnSocialManager manager]fetchFriendInfo];

    [HXIMManager manager].isGetTopicList = NO;
    
    if (clientId)
    {
        [HXIMManager manager].clientId = [clientId mutableCopy];
        NSLog(@"CLIENT ID : %@", clientId);
        dispatch_async(dispatch_get_main_queue(), ^{
           [[HXIMManager manager] checkIMConnection];
        });
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@{@"userId": userId ? userId : @"",
                                                       @"userName": name ? name : @"",
                                                       @"clientId": clientId ? clientId : @""}
                                              forKey:@"lastLoggedInUser"];
    

}

- (void)userSignedOut
{
    [[[HXIMManager manager]anIM] unbindAnPushService:AnPushTypeiOS success:^{
        NSLog(@"AnIM unbindAnPushService successful");
    } failure:^(ArrownockException *exception) {
        NSLog(@"AnIm unbindAnPushService failed, error : %@", exception.getMessage);
    }];
    [[[HXIMManager manager]anIM] disconnect];
    self.userId = nil;
    self.userName = nil;
    self.clientId = nil;
    [HXIMManager manager].clientId = nil;
    self.userInfo = nil;
    [[NSUserDefaults standardUserDefaults] setObject:nil
                                              forKey:@"lastLoggedInUser"];
}
- (void)saveUserIntoDB:(NSDictionary *)userInfo
{
    /* save user info into DB */
    NSDictionary *reformedUser = [UserUtil reformUserInfoDic:userInfo];
    HXUser *hxUser = [UserUtil getHXUserByUserId:reformedUser[@"userId"]] ?
    [UserUtil getHXUserByUserId:reformedUser[@"userId"]] : [UserUtil getHXUserByClientId:reformedUser[@"clientId"]];
    
    if (hxUser == nil) {
        hxUser = [HXUser initWithDict:reformedUser];
    }else{
        //update
        [hxUser setValuesFromDict:reformedUser];
    }
    [HXUserAccountManager manager].userInfo = hxUser;
    
}
- (void)refreshUserInfo:(NSDictionary *)userInfo
{
     NSDictionary *reformedUser = [UserUtil reformUserInfoDic:userInfo];
     HXUser *hxUser = [HXUser initWithDict:reformedUser];
    
     [HXUserAccountManager manager].userInfo = hxUser;
    
    self.age = hxUser.age;
    self.userId = hxUser.userId;
    self.userName = hxUser.userName;
    self.clientId = hxUser.clientId;
    if ( self.userInfo.nickName != nil) {
        self.nickName = self.userInfo.nickName;
    }
    else{
        self.nickName = hxUser.userName;
    }
    self.photoUrl = self.userInfo.photoURL;
    self.coverPhotoUrl = self.userInfo.coverPhotoURL;
    self.email = @"";

    
    
    
}
- (void)updateUser
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[HXUserAccountManager manager].userInfo.userId forKey:@"user_id"];
    
    
    [[HXAnSocialManager manager]sendRequest:USERS_UPDATE method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        
        NSDictionary *user = [[response objectForKey:@"response"] objectForKey:@"user"];
       [[HXUserAccountManager manager] refreshUserInfo:user];
        NSLog(@"success log: %@",[response description]);
        NSLog(@"collage:%@",[HXUserAccountManager manager].userInfo.collage);
        NSLog(@"major:%@",[HXUserAccountManager manager].userInfo.major);
        
    }failure:^(NSDictionary* response){
        NSLog(@"Error: %@", [[response objectForKey:@"meta"] objectForKey:@"message"]);
        
        if ([response objectForKey:@"meta"]) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"用户资料更新错误"
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
@end
