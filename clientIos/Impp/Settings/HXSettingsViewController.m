//
//  HXSettingsViewController.m
//  Impp
//
//  Created by hsujahhu on 2015/3/17.
//  Copyright (c) 2015年 hsujahhu. All rights reserved.
//

#import "HXSettingsViewController.h"
#import "HXAppUtility.h"
#import "HXUserAccountManager.h"
#import "UIColor+CustomColor.h"
#import "HXCustomButton.h"
#import "AnSocialFile.h"
#import "HXAnSocialManager.h"
#import "HXLoginSignupViewController.h"
#import "AnSocialPathConstant.h"
#import "HXLoadingView.h"
#import "CoreDataUtil.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "HXIMManager.h"
#import "HXAnSocialManager.h"
#import "UserUtil.h"
#import "ApplyFor.h"
#import "UIViewController+LewPopupViewController.h"
#import "LewPopupViewAnimationFade.h"
#import "LewPopupViewAnimationSlide.h"
#import "LewPopupViewAnimationSpring.h"
#import "LewPopupViewAnimationDrop.h"
#define SCREEN_WIDTH self.view.frame.size.width
#define SCREEN_HEIGHT self.view.frame.size.height

@interface HXSettingsViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UIImageView *photoImageView;
@property (strong, nonatomic) UILabel *userNameLabel;
@property (strong, nonatomic) NSData *photo;
@property (strong, nonatomic) UITableView* tableView;
@end

@implementation HXSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self initNavigationBar];
}

- (void)initNavigationBar
{
    [HXAppUtility initNavigationTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav_logo"]]
                             barTintColor:[UIColor color1]
                                tintColor:[UIColor color5]
                       withViewController:self];
}

- (void)initView
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 120)];
    imageView.backgroundColor=[UIColor color1];
    [self.view addSubview:imageView];
    
    
    CGRect frame;
    frame = self.view.frame;
    CGRect tableFrame = CGRectMake(0 , 120  , frame.size.width, frame.size.height);

    self.tableView = [[UITableView alloc] initWithFrame:tableFrame
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    //self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
        [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    [self.view setBackgroundColor:[HXAppUtility colorWithHexString:@"#ecf0f3" alpha:1.0f]];
    
    UITapGestureRecognizer *photoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped)];
    self.photoImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"friend_default"]];
    self.photoImageView.frame = CGRectMake(20, 20, 80, 80);
    self.photoImageView.layer.cornerRadius = 80/2;
    self.photoImageView.clipsToBounds = YES;
    self.photoImageView.layer.masksToBounds = YES;
    self.photoImageView.userInteractionEnabled = YES;
    [self.photoImageView addGestureRecognizer:photoTap];
    [self.view addSubview:self.photoImageView];
    
    if ([HXUserAccountManager manager].photoUrl){
        NSLog(@"url:%@",[HXUserAccountManager manager].photoUrl);
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadWithURL:[NSURL URLWithString:[HXUserAccountManager manager].photoUrl]
                         options:0
                        progress:^(NSInteger receivedSize, NSInteger expectedSize){}
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished){
                           if (image) {
                               self.photoImageView.image = image;
                               self.photoImageView.contentMode = UIViewContentModeScaleAspectFill;
                           }
                           
                       }];
    }
    
    self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(120,30,SCREEN_WIDTH, 28)];
    [self.userNameLabel setBackgroundColor:[UIColor clearColor]];
    [self.userNameLabel setFont:[UIFont fontWithName:@"STHeitiTC-Medium" size:25]];
    [self.userNameLabel setTextColor:[UIColor whiteColor]];
    self.userNameLabel.text = [HXUserAccountManager manager].userInfo.nickName;
    self.userNameLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.userNameLabel];
    
    
}

#pragma mark - Listener
-(void)addRegisetView{
    
}
- (void)logoutButtonTapped
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [[HXUserAccountManager manager]userSignedOut];
    HXLoginSignupViewController *lgVc = [[HXLoginSignupViewController alloc]init];
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:lgVc];
    
    [UIApplication sharedApplication].keyWindow.rootViewController = nav;
}

- (void)photoTapped
{
    NSString *button1 = NSLocalizedString(@"拍攝照片", nil);
    NSString *button2 = NSLocalizedString(@"選取照片", nil);
    
    NSString *cancelTitle = NSLocalizedString(@"取消", nil);
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:button1, button2, nil];
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionsheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    switch (buttonIndex) {
        case 0: {
            // take photo
            [self takePhoto];
            break;
        }
        case 1: {
            // select photo
            [self selectPhoto];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Pick up Photo Method
- (void)takePhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        //NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
        imagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        imagePicker.allowsEditing = YES;
        imagePicker.showsCameraControls = YES;
        imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
        });
    }
}

- (void)selectPhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController* cameraRollPicker = [[UIImagePickerController alloc] init];
        cameraRollPicker.navigationBar.barTintColor = [UIColor color3];
        cameraRollPicker.delegate = self;
        cameraRollPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:cameraRollPicker.sourceType];
        cameraRollPicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        cameraRollPicker.allowsEditing = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:cameraRollPicker animated:YES completion:nil];
        });
        
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([info objectForKey:@"UIImagePickerControllerEditedImage"])
    {
        UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
        /* resize the image */
        if (image.size.width > 150)
        {
            CGFloat fWidth = 150;
            CGFloat fHeight = fWidth * image.size.height / image.size.width;
            
            CGFloat scale = [[UIScreen mainScreen] scale];
            UIGraphicsBeginImageContext(CGSizeMake(fWidth*scale, fHeight*scale));
            CGRect frame = CGRectMake(0.0f, 0.0f, fWidth*scale, fHeight*scale);
            
            [image drawInRect:frame];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        float fCompressionRatio = 1.0f;
        NSData* imageData = UIImageJPEGRepresentation(image, fCompressionRatio);
        
        NSInteger nSizeLimit = 100 * 1024;
        while ([imageData length] > nSizeLimit)
        {
            fCompressionRatio = fCompressionRatio*0.6;
            imageData = UIImageJPEGRepresentation(image, fCompressionRatio);
        }
        self.photo = imageData;
        [self changeProfilePhoto:self.photo];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Navigation Method
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [viewController.navigationItem setTitle:@""];
    viewController.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    viewController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"取消", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelBarButtonTapped)];
    viewController.navigationItem.rightBarButtonItem = cancelButton;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

#pragma mark - Helper
- (void)changeProfilePhoto:(NSData *)image
{
    if (!self.photo)return;
    self.photoImageView.image = [UIImage imageWithData:image];
    self.photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    HXLoadingView *load = [[HXLoadingView alloc]initLoadingView];
    [self.view addSubview:load];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[HXUserAccountManager manager].userInfo.userId forKey:@"user_id"];

    AnSocialFile *imageFile = [AnSocialFile createWithFileName:@"photo"
                                                              data:self.photo];
    [params setObject:imageFile forKey:@"photo"];

    
    [[HXAnSocialManager manager]sendRequest:USERS_UPDATE method:AnSocialManagerPOST params:params success:^(NSDictionary* response){
        
        NSLog(@"success log: %@",[response description]);
         NSDictionary *user = [[response objectForKey:@"response"] objectForKey:@"user"];
        [[HXUserAccountManager manager] saveUserIntoDB:user];
        dispatch_async(dispatch_get_main_queue(), ^{
            [load loadCompleted];
            
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
                [load loadCompleted];
                [alert show];
            });
        }
        
    }];
}


- (void)cancelBarButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}




#pragma mark - TableView Delegate Datasource


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"settingCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] init];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else{
        
    }
    long age = [[HXUserAccountManager manager].userInfo.age integerValue];
    if(age == 1)
    {
        switch (indexPath.row ) {
            case 0:
                cell.textLabel.text  = @"申请成为学长";
                break;
            case 1:
                cell.textLabel.text  = @"退出登录";
                break;
            default:
                break;
        }
    }
    else if([[HXUserAccountManager manager].userInfo.age integerValue] >= 100){
        switch (indexPath.row ) {
            case 0:
                cell.textLabel.text  = [NSString stringWithFormat:@"积分: %ld",age - 100];
                break;
            case 1:
                cell.textLabel.text  = @"退出登录";
                break;
            default:
                break;
        }
    }
    else{
        cell.textLabel.text  = @"退出登录";
    }

    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[HXUserAccountManager manager].userInfo.age integerValue] == 1)
    {
        
    if (indexPath.row == 0) {
        ApplyFor *view = [ApplyFor defaultApplyFor];
        view.parentVC = self;
        LewPopupViewAnimationSlide *animation = [[LewPopupViewAnimationSlide alloc]init];
        animation.type = LewPopupViewAnimationSlideTypeBottomBottom;
        [self lew_presentPopupView:view animation:animation dismissed:^{
            NSLog(@"动画结束");
        }];

    }
    else if (indexPath.row == 1){
         [self logoutButtonTapped];
    }
        
    }
    else{
        if (indexPath.row == 1){
            [self logoutButtonTapped];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
 
}


@end
