// AudioShareSDK.h
// Copyright (C)2012 Jonatan Liljedahl

#import "AudioShareSDK.h"
#import <MobileCoreServices/UTCoreTypes.h>

#define BM_CLIPBOARD_CHUNK_SIZE (5 * 1024 * 1024)

@implementation AudioShare

+ (AudioShare*) sharedInstance {
    static AudioShare *a = nil;
    if(!a)
        a = [[AudioShare alloc] init];
    return a;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != alertView.cancelButtonIndex) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/audioshare-audio-document/id543859300?ls=1&mt=8"]];
    }
}

- (BOOL)addSoundFromData:(NSData*)data withName:(NSString*)name {
    NSString *s = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                      NULL,
                                                                      (CFStringRef)name,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                      CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    name = [s autorelease];
    NSURL *asURL = [NSURL URLWithString:[NSString stringWithFormat:@"audiosharecmd://addFromPaste?%@",name]];
    if(![[UIApplication sharedApplication] canOpenURL:asURL]) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"AudioShare"
                                                    message:@"AudioShare - audio document manager, version 2.1 or later is not installed on this device. You can get it on the App Store."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Continue", nil];
        [a show];
        [a release];
        return NO;
    }
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    if (!data) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                    message:@"Something went wrong. Could not export audio!"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
        [a show];
        [a release];
        return NO;
    }
    NSUInteger sz = [data length];
    NSUInteger chunkNumbers = (sz / BM_CLIPBOARD_CHUNK_SIZE) + 1;
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:chunkNumbers];
    NSRange curRange;
    for (NSUInteger i = 0; i < chunkNumbers; i++) {
        curRange.location = i * BM_CLIPBOARD_CHUNK_SIZE;
        curRange.length = MIN(BM_CLIPBOARD_CHUNK_SIZE, sz - curRange.location);
        NSData *subData = [data subdataWithRange:curRange];
        NSDictionary *dict = [NSDictionary dictionaryWithObject:subData forKey:(NSString *)kUTTypeAudio];
        [items addObject:dict];
    }
    board.items = items;
    return [[UIApplication sharedApplication] openURL:asURL];
}

- (BOOL)addSoundFromURL:(NSURL*)url withName:(NSString*)name {
    NSString *srcPath = [url path];
    NSData *dataFile = [NSData dataWithContentsOfMappedFile:srcPath];
    return [self addSoundFromData:dataFile withName:name];
}

@end
