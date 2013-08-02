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

- (NSString*)escapeString:(NSString*)string {
    NSString *s = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                      NULL,
                                                                      (CFStringRef)string,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                      CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return [s autorelease];    
}

- (BOOL)addSoundFromData:(NSData*)data withName:(NSString*)name {
    name = [self escapeString:name];
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

- (BOOL)addSoundFromPath:(NSString*)path withName:(NSString*)name {
    NSData *dataFile = [NSData dataWithContentsOfMappedFile:path];
    return [self addSoundFromData:dataFile withName:name];
}

- (NSString*)findCallbackScheme {
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSArray* cfBundleURLTypes = [mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if ([cfBundleURLTypes isKindOfClass:[NSArray class]] && [cfBundleURLTypes lastObject]) {
        for(NSDictionary* cfBundleURLTypes0 in cfBundleURLTypes) {
            if ([cfBundleURLTypes0 isKindOfClass:[NSDictionary class]]) {
                NSArray* cfBundleURLSchemes = [cfBundleURLTypes0 objectForKey:@"CFBundleURLSchemes"];
                if ([cfBundleURLSchemes isKindOfClass:[NSArray class]]) {
                    for (NSString* scheme in cfBundleURLSchemes) {
                        if ([scheme isKindOfClass:[NSString class]] && [scheme hasSuffix:@".audioshare"]) {
                            return scheme;
                        }
                    }
                }
            }
        }
    }
    return nil;
}

- (BOOL)initiateSoundImport {
    NSString *callback = [self findCallbackScheme];
    if(!callback) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Missing callback URL"
                                                    message:@"Developer: This app does not expose the needed appname.audioshare:// callback URL!"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
        [a show];
        [a release];
        return NO;
    }
    NSURL *asURL = [NSURL URLWithString:[NSString stringWithFormat:@"audioshare.import://%@",callback]];
    if(![[UIApplication sharedApplication] canOpenURL:asURL]) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"AudioShare"
                                                    message:@"AudioShare - audio document manager, version 2.5 or later is not installed on this device. You can get it on the App Store."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Continue", nil];
        [a show];
        [a release];
        return NO;
    }

    return [[UIApplication sharedApplication] openURL:asURL];
}

- (NSString*)writeSoundImport:(NSString*)filename {
	UIPasteboard *board = [UIPasteboard generalPasteboard];
	NSArray *typeArray = [NSArray arrayWithObject:(NSString *) kUTTypeAudio];
	NSIndexSet *set = [board itemSetWithPasteboardTypes:typeArray];
	if (!set)
		return nil;
	NSArray *items = [board dataForPasteboardType:(NSString *) kUTTypeAudio inItemSet:set];
	if (items) {
		UInt32 cnt = [items count];
		if (!cnt)
			return nil;
		NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
		if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil])
            return nil;
		NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
		if (!handle)
			return nil;
		for (UInt32 i = 0; i < cnt; i++)
			[handle writeData:[items objectAtIndex:i]];
		[handle closeFile];
        return path;
	}
    return nil;
}

- (BOOL)checkPendingImport:(NSURL *)url withBlock:(AudioShareImportBlock)block {
    NSString *scheme = [self findCallbackScheme];
    if([[url scheme] isEqualToString:scheme]) {
        NSString *name = [url host];
        NSString *path = [self writeSoundImport:name];
        if(!path) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                        message:@"There was a problem trying to import a sound from AudioShare!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
            [a show];
            [a release];
            return NO;
        }
        block(path);
        return YES;
    } else {
        return NO;
    }
}

@end
