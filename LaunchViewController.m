//
//  LaunchViewController.m
//  QuanQuanNursing
//
//  Created by huanghaipo on 16/1/8.
//  Copyright © 2016年 伯仲. All rights reserved.
//

#import "LaunchViewController.h"
#import "loginViewController.h"
#import "Header.h"
#import "LoginHttps.h"
#import "LaunchModel.h"
#import "UIImageView+WebCache.h"
#import "QQRequest.h"
#import "PCRequest.h"
#import "HFDeviceInfo.h"
#import "WebViewController.h"
#import "GlobInfo.h"
#import "versionUpdateViewController.h"
#import "CreditWebViewController.h"
#import "PCHttpTools.h"
#import "HuPublicWebViewViewController.h"


@interface LaunchViewController ()<UIAlertViewDelegate>
{
    int _coutDownInterval; //广告倒计时时间
    NSTimer *_timer;
    BOOL _needUpdate;
}
@property (nonatomic, strong) UIButton *timeBtn;

@property(nonatomic, copy)NSString *appUrl;
@property (nonatomic, assign) LoginAccountType accountType;

@end
@implementation LaunchViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [self getAdImageProcedure];
    
    [kNotificationCenter addObserver:self selector:@selector(startCountDown) name:@"startThreeSecond" object:nil];
}

- (void)getAdImageProcedure
{
    if (YGYFlag) {
        [self gotonextlandingscreen];
        return;
    }
    
    [HuConfigration addDefaultImageWithVC:self];
    _coutDownInterval = 3;//倒计时
    WS(weakSelf);
    
    //获取图片链接URL
    [PCRequest getQNImageUrl:^(NSString *urlAddress) {
        [LoginHttps openingTheAdvertising:weakSelf.navigationController.view success:^(NSArray *data) {
            weakSelf.data = data;
            for (int i = 0; i < weakSelf.data.count; i++) {
                
                UIImageView * imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, HHBWIDTH, HHBHEIGHT)];
                LaunchModel *model=weakSelf.data[i];
                NSURL *imagePath=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", imageSiteUrl, model.imageId]];
                
                [imageView1 sd_setImageWithURL:imagePath completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    if (!error) {
                        imageView1.image = image;
                        [weakSelf.view addSubview:imageView1];
                        [weakSelf setCountDownBtn];
                        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(advertisingDidClick)];
                        [weakSelf.view addGestureRecognizer:tap];
                        _timeBtn.userInteractionEnabled = YES;
                        if (!_needUpdate) {
                            
                            [weakSelf startCountDown];
                        }
                    }
                    else
                    {
                        [weakSelf gotonextlandingscreen];
                    }
                    
                }];
                
            }
        } failure:^{
            _timer=[NSTimer scheduledTimerWithTimeInterval:1 target:weakSelf selector:@selector(theTimer) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSRunLoopCommonModes];
        }];
        
    }];
}

- (void)setCountDownBtn{
    _timeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _timeBtn.frame = CGRectMake(HHBWIDTH-60, 30, 40, 22);
    _timeBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _timeBtn.layer.borderWidth = 0.5;
    _timeBtn.layer.masksToBounds = YES;
    _timeBtn.layer.cornerRadius = 6;
    [_timeBtn addTarget:self action:@selector(gotonextlandingscreen) forControlEvents:UIControlEventTouchUpInside];
    [_timeBtn setTitle:@"3S" forState:UIControlStateNormal];
    _timeBtn.titleLabel.font = [UIFont systemFontOfSize:15 * kFontScale];
    _timeBtn.backgroundColor = [UIColor blackColor];
    _timeBtn.alpha = 0.5;
    [self.view addSubview:_timeBtn];
    [self.view bringSubviewToFront:_timeBtn];
}

- (void)startCountDown
{
    _timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(theTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)theTimer{
    _coutDownInterval--;
    [_timeBtn setTitle:[NSString stringWithFormat:@"%dS",_coutDownInterval] forState:UIControlStateNormal];
    
    if (_coutDownInterval <= 0) {
        [self gotonextlandingscreen];
    }
}
//跳往广告页
- (void)advertisingDidClick
{
    LaunchModel *model=self.data[0];
    
//    model.contentType = @"3";
//    model.content = @"1,1-4";
    //页面内跳转
    if ([model.contentType isEqualToString:@"3"]){
        NSString *pageId = [model.content componentsSeparatedByString:@","][1];
        NSString *pageIndex = [model.content componentsSeparatedByString:@","][0];
        NSString *flag = @"2";//1正常跳入，2提示登录，3权限不够
        if ([pageIndex isEqualToString:@"1"] || [pageIndex isEqualToString:@"2"]) {
            if(huAccoutType == hospitalAccount){
                flag = @"1";
            }
        }else if ([pageIndex isEqualToString:@"3"]){
            flag = @"1";
        }else if ([pageIndex isEqualToString:@"4"]){
            if (huAccoutType == hospitalAccount) {
                flag = @"1";
            }
        }
        if ([flag isEqualToString:@"1"]) {
            [_timer invalidate];  //跳入广告，默认计时器关掉。
            UIViewController *con = [self updateTabBar:pageIndex];
            [[HuControllerId HuControllerShare] commonPushConIndex:pageIndex pageId:pageId controller:con];
        }else{
            //提示
            [MBProgressHUD showMessage:@"请先登录并关联医院"];
        }
        return;
    }
    
    NSString *urlStr = [model.url absoluteString];
    
    if (urlStr.length <= 0) {
        return;
    }
    
    [_timer invalidate];  //跳入广告，默认计时器关掉。
    
    if (![urlStr containsString:@"?code=duiba"]) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        [dic setObject:model.url.absoluteString forKey:kParamURL];
        [dic setObject:model.imageId forKey:@"image"];
        [dic setObject:model.title ? model.title : model.name forKey:kParamTitle];
        WebViewController * webVC = [[WebViewController alloc] init];
        webVC.webViewType = TypeFromLanuch;
        webVC.param = dic;
        webVC.fatherFlag = @"share";
        UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:webVC];
        [UIApplication sharedApplication].keyWindow.rootViewController = nav;
        long advID = model.ID;
        if (advID > 0) {
            [HuAlilog alilogWithBrowseActionWithPageId:@"601" withParam:@{kAdvertisementIdkey:[NSString stringWithFormat:@"%zd",advID]}];
        }
    }
    else {
        if ([HuConfigration loginStatus]){
            NSDictionary *dis = @{@"redirect":@"https://home.m.duiba.com.cn/#/chome/index",@"accountId":NurseId};
            
            [PCHttpTools getduibaUrl:dis success:^(NSString *data) {
                CreditWebViewController *web=[[CreditWebViewController alloc]initWithUrl:data];//实际中需要改为开发者服务器的地址，开发者服务器再重定向到一个带签名的自动登录地址
                web.webViewType = TypeFromLanuch;
                
                UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:web];
                nav.navigationBar.barTintColor = [UIColor whiteColor];
//                [nav pushViewController:web animated:YES];
                [UIApplication sharedApplication].keyWindow.rootViewController = nav;
                
            } errBlock:^(NSString *errMsg) {
                [MBProgressHUD showMessage:@"连接失败，请联系管理员"];
            }];
        }else {
            
            AppDelegate*delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            UIWindow *window=delegate.window;
            [UIView transitionWithView:window duration:1 options:UIViewAnimationOptionTransitionNone animations:nil completion:nil];
            loginViewController *second=[[loginViewController alloc]init];
            second.isLoginDuiba = @"duiba";
            window.rootViewController=second;
        }
    }
}

- (UIViewController *)updateTabBar:(NSString *)index {
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = nil;
    
    CustomMyViewController *custom = [[CustomMyViewController alloc]init];
    custom.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    delegate.window.rootViewController = custom;
    
    [custom tabMenuBarWithType:index.intValue];
    
    UINavigationController *con = [[custom childViewControllers] objectAtIndex:(index.intValue-1)];
    UIViewController *resVC = con.topViewController;
    return resVC;
}

//进入主页
-(void)gotonextlandingscreen
{
    [_timer invalidate];//进入首页了就把定时器去掉，避免两次进入首页。
    AppDelegate*delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    UIWindow *window=delegate.window;
    [UIView transitionWithView:window duration:1 options:UIViewAnimationOptionTransitionNone animations:nil completion:nil];
    //判断是否登录过
    
    //  三种不同的情况：未登录可以直接进入到发现界面  有账号关联医院管理的 有账号但是没有关联医院的
    // noAccount = 1,   //没有注册账号 hospitalAccount = 2,  //账号关联医院personAccount = 3   //账号未关联医院
    self.accountType = huAccoutType;
    
    if (YGYFlag) {
        //判断是否登录过
        if ([HuConfigration loginStatus]) {
            //如果存在就直接进入主界面
            CustomMyViewController *custom=[[CustomMyViewController alloc]init];
            custom.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            window.rootViewController = custom;
            
        }else{
            loginViewController *second=[[loginViewController alloc]init];
            window.rootViewController=second;
        }
    }
    else{
        if (self.accountType == noAccount) {
            //没有注册账号，直接进入发现页面
            
            CustomMyViewController * customVC = [[CustomMyViewController alloc]init];
            customVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            window.rootViewController = customVC;
            
        }else{
            //进入登录页面进行登录
            loginViewController * loginVC = [[loginViewController alloc]init];
            window.rootViewController = loginVC;
        }
    }
}

#pragma mark - alertView delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==20) {
        if (buttonIndex==0) {
            [self startCountDown];
        }else{
            NSURL *appUrl=[NSURL URLWithString:_appUrl];
            [[UIApplication sharedApplication]openURL:appUrl];
        }
    }else{
        NSURL *appUrl=[NSURL URLWithString:_appUrl];
        [[UIApplication sharedApplication]openURL:appUrl];
    }
}

@end
//隐藏状态栏
//    UIApplication *app = [UIApplication sharedApplication];
//    [app setStatusBarHidden:YES];
