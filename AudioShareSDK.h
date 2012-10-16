// AudioShareSDK.h
// Copyright (C)2012 Jonatan Liljedahl

#import <Foundation/Foundation.h>

@interface AudioShare : NSObject <UIAlertViewDelegate>

+ (AudioShare*) sharedInstance;

- (BOOL) addSoundFromURL:(NSURL*)url withName:(NSString*)name;
- (BOOL) addSoundFromData:(NSData*)data withName:(NSString*)name;

@end