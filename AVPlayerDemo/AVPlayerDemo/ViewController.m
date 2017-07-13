//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by 韩东 on 17/7/10.
//  Copyright © 2017年 HD. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()

@property (strong, nonatomic) UIView *backView;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
// 底部BottmView
@property (nonatomic,strong) UIView *bottomView;
@property (nonatomic,strong) UIButton *playButton;
@property (nonatomic,strong) UIButton *fullScreenButton;
@property (nonatomic,strong) UIProgressView *progressView;
@property (nonatomic,strong) UISlider *slider;
@property (nonatomic,strong) UILabel *nowLabel;
@property (nonatomic,strong) UILabel *remainLabel;
// 是否全屏
@property (nonatomic,assign) BOOL isFullScreen;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI{
    
    self.backView = [[UIView alloc] initWithFrame:CGRectMake(0, 80, kScreenWidth, kScreenHeight / 2.5)];
    self.backView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backView];
    
    // 初始化播放器item
    self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:@"http://flv2.bn.netease.com/videolib3/1608/30/zPuaL7429/SD/zPuaL7429-mobile.mp4"]];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    // 初始化播放器的Layer
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    _playerLayer.frame = self.backView.bounds;
    [self.backView.layer insertSublayer:self.playerLayer atIndex:0];
    
    //添加手势动作,隐藏下面的进度条
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    [self.backView addGestureRecognizer:tap];
    
    // 布局底部功能栏
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.backView addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.backView).with.offset(0);
        make.right.equalTo(self.backView).with.offset(0);
        make.bottom.equalTo(self.backView).with.offset(0);
        make.height.mas_equalTo(30);
    }];
    
    // 播放或暂停
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    self.playButton.showsTouchWhenHighlighted = YES;
    [self.bottomView addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(5);
        make.centerY.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    //播放
    [self.playButton addTarget:self action:@selector(pauseOrPlay:) forControlEvents:UIControlEventTouchUpInside];
    
    // 底部全屏按钮
    self.fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    self.fullScreenButton.showsTouchWhenHighlighted = YES;
    [self.bottomView addSubview:self.fullScreenButton];
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).with.offset(-5);
        make.centerY.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    //点击全屏1
    [self.fullScreenButton addTarget:self action:@selector(clickFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    
    // 底部进度条
    self.slider = [[UISlider alloc] init];
    self.slider.minimumValue = 0.0;
    self.slider.minimumTrackTintColor = [UIColor greenColor];
    self.slider.maximumTrackTintColor = [UIColor clearColor];
    self.slider.value = 0.0;
    [self.slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    [self.bottomView addSubview:self.slider];
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.centerY.equalTo(self.bottomView);
        
    }];
    
    // 底部缓存进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [UIColor blueColor];
    self.progressView.trackTintColor = [UIColor lightGrayColor];
    [self.bottomView addSubview:self.progressView];
    [self.progressView setProgress:0.0 animated:NO];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.slider).with.offset(0);
        make.right.equalTo(self.slider);
        make.height.mas_equalTo(2);
        make.centerY.equalTo(self.slider).with.offset(1);
    }];
    [self.bottomView sendSubviewToBack:self.progressView];
    
    // 底部左侧时间轴
    self.nowLabel = [[UILabel alloc] init];
    self.nowLabel.textColor = [UIColor whiteColor];
    self.nowLabel.font = [UIFont systemFontOfSize:13];
    self.nowLabel.textAlignment = NSTextAlignmentLeft;
    [self.bottomView addSubview:self.nowLabel];
    [self.nowLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.slider.mas_left).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    // 底部右侧时间轴
    self.remainLabel = [[UILabel alloc] init];
    self.remainLabel.textColor = [UIColor whiteColor];
    self.remainLabel.font = [UIFont systemFontOfSize:13];
    self.remainLabel.textAlignment = NSTextAlignmentRight;
    [self.bottomView addSubview:self.remainLabel];
    [self.remainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.slider.mas_right).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    
}

#pragma mark - 暂停或者播放
- (void)pauseOrPlay:(UIButton *)sender{
    
    if (self.player.rate != 1.0f)
    {
        [sender setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        
        [self.player play];
    }
    else
    {
        [sender setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [self.player pause];
    }
}
#pragma mark - 点击全屏按钮
- (void)clickFullScreen:(UIButton *)button{
    
    if (!self.isFullScreen)
    {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"nonfullscreen@3x"] forState:UIControlStateNormal];
    }
    else
    {
        [self toSmallScreen];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen@3x"] forState:UIControlStateNormal];
    }
    self.isFullScreen = !self.isFullScreen;
    
}
#pragma mark - 显示全屏
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    // 先移除之前的
    [self.backView removeFromSuperview];
    // 初始化
    self.backView.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        self.backView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        self.backView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    // BackView的frame能全屏
    self.backView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    // layer的方向宽和高对调
    self.playerLayer.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
    
    // remark 约束
    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(50);
        make.top.mas_equalTo(kScreenWidth-50);
        make.left.equalTo(self.backView).with.offset(0);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    
    [self.nowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.slider.mas_left).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    [self.remainLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.slider.mas_right).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    // 加到window上面
    [[UIApplication sharedApplication].keyWindow addSubview:self.backView];
    
}
#pragma mark - 缩小全屏
-(void)toSmallScreen{
    // 先移除
    [self.backView removeFromSuperview];
    
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f animations:^{
        weakSelf.backView.transform = CGAffineTransformIdentity;
        weakSelf.backView.frame = CGRectMake(0, 80, kScreenWidth, kScreenHeight / 2.5);
        weakSelf.playerLayer.frame =  weakSelf.backView.bounds;
        // 再添加到View上
        [weakSelf.view addSubview:weakSelf.backView];
        
        // remark约束
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.backView).with.offset(0);
            make.right.equalTo(weakSelf.backView).with.offset(0);
            make.height.mas_equalTo(50);
            make.bottom.equalTo(weakSelf.backView).with.offset(0);
        }];
    }completion:^(BOOL finished) {
        
    }];
    
}

#pragma mark - 单击手势
- (void)singleTap:(UITapGestureRecognizer *)tap{

    [UIView animateWithDuration:1.0 animations:^{
        if (self.bottomView.alpha == 1)
        {
            self.bottomView.alpha = 0;
        }
        else if (self.bottomView.alpha == 0)
        {
            self.bottomView.alpha = 1;
        }
    }];
}

@end
