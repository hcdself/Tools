//
//  HCDAudioManager.h
//  PoetryForIphone
//
//  Created by henry on 2018/7/26.
//  Copyright © 2018年 henry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/** 录音状态 */
typedef enum : NSUInteger {
    RecordStarting,
    RecordPause,
    RecordStop,
} RecordStatus;

/** 播放状态 */
typedef enum : NSUInteger {
    PlayAudioStarting,
    PlayAudioPause,
    PlayAudioStop,
} PlayAudioStatus;

typedef void(^RecordTimeCallBlock)(AVAudioRecorder *recorder,NSString *recordTimeStr);
typedef void(^PlayTimeCallBlock)(AVAudioPlayer *player,NSString *playTimeStr);
typedef void(^PlayCompletionCallBlock)(void);

@interface HCDAudioManager : NSObject<AVAudioRecorderDelegate,AVAudioPlayerDelegate>


@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSString *recordFilePath;
@property (nonatomic, assign) RecordStatus recordStatus;
@property (nonatomic, strong) NSTimer *recordTimer;
@property (nonatomic, strong) RecordTimeCallBlock recordTimeBlock;

@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSString *playFilePath;
@property (nonatomic, assign) PlayAudioStatus playStatus;
@property (nonatomic, strong) NSTimer *playTimer;
@property (nonatomic, strong) PlayTimeCallBlock playTimeBlock;
@property (nonatomic, strong) PlayCompletionCallBlock playCompletionBlock;


+ (id)sharedManager;
//录音相关
- (BOOL)getMicrophoneAuthorization:(void(^)(BOOL isSucceed))completion;
- (void)startRecordWithFilePath:(NSString *)recordFilePath;
- (void)pauseRecord;
- (void)stopRecord;
- (void)restartRecordFromPause;

//播放相关
- (void)playAudioWithFilePath:(NSString *)playFilePath;
- (void)pausePlay;
- (void)stopPlay;
- (void)restartPlayFromPause;

@end
