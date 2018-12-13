//
//  HCDAudioManager.m
//  PoetryForIphone
//
//  Created by henry on 2018/7/26.
//  Copyright © 2018年 henry. All rights reserved.
//

#import "HCDAudioManager.h"

@implementation HCDAudioManager
{
    
}

static HCDAudioManager *manager = nil;
+ (id)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HCDAudioManager alloc] init];
        manager.recordStatus = RecordStop;
        manager.playStatus = PlayAudioStop;
    });
    return manager;
}

- (BOOL)getMicrophoneAuthorization:(void(^)(BOOL isSucceed))completion {
    //获取麦克风权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    //第一次使用，弹出框选择是否授权时
    __block BOOL isSucceed = YES;
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        //采用信号量确保线程同步
        dispatch_semaphore_t semaPhore = dispatch_semaphore_create(1);
        dispatch_semaphore_wait(semaPhore, DISPATCH_TIME_FOREVER);

        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (completion) {
                completion(granted);
            }
            isSucceed = granted;
            dispatch_semaphore_signal(semaPhore);
            dispatch_semaphore_signal(semaPhore);
        }];
        dispatch_semaphore_wait(semaPhore, DISPATCH_TIME_FOREVER);
        
    } else if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied){
        if (completion) {
            completion(NO);
        }
        isSucceed = NO;
    }
    return isSucceed;
}

- (void)startRecordWithFilePath:(NSString *)recordFilePath {
    
    self.recordFilePath = recordFilePath;
    NSLog(@"录音路径：%@",recordFilePath);
    //设置绘画
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if(session.category != AVAudioSessionCategoryPlayAndRecord){
        NSError *sessionError;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord  error:&sessionError];
        if(sessionError)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else{
            [session setActive:YES error:&sessionError];
            if (sessionError) {
                NSLog(@"设置绘画失败: %@", sessionError);
            }
        }
    }
    
    //相关音频设置
    NSMutableDictionary *setting = [NSMutableDictionary dictionary];
//    // 音频格式
//    setting[AVFormatIDKey] = @(kAudioFormatAppleIMA4);
//    // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
//    setting[AVSampleRateKey] = @(44100);
//    // 音频通道数 1 或 2
//    setting[AVNumberOfChannelsKey] = @(1);
//    // 线性音频的位深度  8、16、24、32
//    setting[AVLinearPCMBitDepthKey] = @(8);
//    //录音的质量
//    setting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityHigh];
    // 音频格式
    setting[AVFormatIDKey] = @(kAudioFormatLinearPCM);
    // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    setting[AVSampleRateKey] = @(11025);
    // 音频通道数 1 或 2
    setting[AVNumberOfChannelsKey] = @(2);
    // 线性音频的位深度  8、16、24、32
    //setting[AVLinearPCMBitDepthKey] = @(8);
    //录音的质量
    setting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityHigh];
    
    NSURL *recordUrl = [NSURL fileURLWithPath:recordFilePath];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:recordUrl settings:setting error:NULL];
    self.recorder.delegate = self;
    //self.recorder.meteringEnabled = YES;
    
    [self.recorder prepareToRecord];
    BOOL bo =  [self.recorder record];
    
    if (!bo) {
        NSLog(@"开始录音失败");
    }
    self.recordStatus = RecordStarting;
    
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateRecordTime:) userInfo:nil repeats:YES];
}

- (void)updateRecordTime:(NSTimer *)timer {
    if (self.recordTimeBlock) {
        self.recordTimeBlock(self.recorder,[self createTimeForm:self.recorder.currentTime]);
    }
}

- (NSString *)createTimeForm:(double)time {
    //时
    int hour = time/3600;
    //分
    int minute = time/60 - hour *60;
    //秒
    int second = ((int)time)%60;
    NSString *timeStr = nil;
    if (hour >0) {
        timeStr = [NSString stringWithFormat:@"%02d:%02d:%02d",hour,minute,second];
    } else {
        timeStr = [NSString stringWithFormat:@"%02d:%02d",minute,second];
    }
    
    return timeStr;
}

- (void)pauseRecord {
    [self.recorder pause];
    self.recordStatus = RecordPause;
    [self.recordTimer  setFireDate:[NSDate distantFuture]];
}

- (void)stopRecord {
    [self.recorder stop];
    self.recordStatus = RecordStop;
    
    [self.recordTimer invalidate];
    self.recorder = nil;
    self.recordTimeBlock = nil;
    
}

- (void)restartRecordFromPause {
    if (self.recordStatus == RecordPause) {
        [self.recorder record];
        self.recordStatus = RecordStarting;
        [self.recordTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)playAudioWithFilePath:(NSString *)playFilePath {
    self.playFilePath = playFilePath;
    
    NSError *playError;
    NSURL *playUrl = [NSURL fileURLWithPath:playFilePath];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:playUrl error:&playError];
    if (playError) {
        NSLog(@"播放音频失败:%@ \n %@",playFilePath,playError);
    }
    self.player.delegate = self;
    
    [self.player play];
    self.playStatus = PlayAudioStarting;
    
    self.playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePlayTime:) userInfo:nil repeats:YES];
}

- (void)updatePlayTime:(NSTimer *)timer {
    if (self.playTimeBlock) {
        self.playTimeBlock(self.player,[self createTimeForm:self.player.currentTime]);
    }
}

- (void)pausePlay {
    [self.player pause];
    self.playStatus = PlayAudioPause;
    
    [self.playTimer setFireDate:[NSDate distantFuture]];
}

- (void)stopPlay {
    [self.player stop];
    self.playStatus = PlayAudioStop;
    
    [self.playTimer invalidate];
    self.playTimer = nil;
    self.playTimeBlock = nil;
}

- (void)restartPlayFromPause {
    if (self.playStatus == PlayAudioPause) {
        [self.player play];
        [self.playTimer setFireDate:[NSDate distantPast]];
        self.playStatus = PlayAudioStarting;
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.playStatus = PlayAudioStop;
    [self.playTimer invalidate];
    self.playTimer = nil;
    self.playTimeBlock = nil;
    if (self.playCompletionBlock) {
        self.playCompletionBlock();
    }
}



@end
