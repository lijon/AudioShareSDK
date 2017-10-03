// AudioShareSDK.h
// Copyright (C)2012 Jonatan Liljedahl

#import "AudioShareSDK.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AudioToolbox/AudioToolbox.h>

#define BM_CLIPBOARD_CHUNK_SIZE (5 * 1024 * 1024)

@implementation AudioShare

+ (AudioShare*) sharedInstance {
    static AudioShare *a = nil;
    if(!a)
        a = [[AudioShare alloc] init];
    return a;
}

+ (void)showAlertController:(UIAlertController*)alertController {
    UIViewController *presentingViewController = [[[UIApplication sharedApplication] delegate] window].rootViewController;

    while(presentingViewController.presentedViewController != nil) {
        presentingViewController = presentingViewController.presentedViewController;
    }

    [presentingViewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)openURL:(NSURL *)URL {
    UIApplication *application = [UIApplication sharedApplication];

    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:URL options:@{}
           completionHandler:nil];
    } else {
        [application openURL:URL];
    }
}

- (NSString*)escapeString:(NSString*)string {
    NSString *s = [string stringByAddingPercentEncodingWithAllowedCharacters:
                   [NSCharacterSet URLQueryAllowedCharacterSet]];
    return s;
}

- (BOOL)addSoundFromData:(NSData*)data withName:(NSString*)name {
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    if (!data) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry"
                                                                                 message:@"Something went wrong. Could not export audio!"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){}];
        [alertController addAction:okAction];
        [AudioShare showAlertController:alertController];
        
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
    
    name = [self escapeString:name];
    NSURL *asURL = [NSURL URLWithString:[NSString stringWithFormat:@"audiosharecmd://addFromPaste?%@",name]];
    if(![[UIApplication sharedApplication] canOpenURL:asURL]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AudioShare"
                                                                                 message:@"Audio was copied to pasteboard and can now be pasted in other apps.\n\nInstall AudioShare for easy storage and management of all your soundfiles, and more copy/paste functionality. You can get it on the App Store."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action){}];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
                                   {
                                       [AudioShare openURL:[NSURL URLWithString:@"http://kymatica.com/audioshare/download.php"]];
                                   }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [AudioShare showAlertController:alertController];
        
        return NO;
    }
    [AudioShare openURL:asURL];
    return YES;
}

- (BOOL)addSoundFromURL:(NSURL*)url withName:(NSString*)name {
    NSString *srcPath = [url path];
    return [self addSoundFromPath:srcPath withName:name];
}

- (BOOL)addSoundFromPath:(NSString*)path withName:(NSString*)name {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry"
                                                                                 message:@"The file does not exist!"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){}];
        
        [alertController addAction:okAction];
        
        [AudioShare showAlertController:alertController];

        return NO;
    }
    NSData *dataFile = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path] options:NSDataReadingMappedIfSafe error:NULL];
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
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing callback URL"
                                                                                 message:@"Hello developer. This app does not expose the needed appname.audioshare:// callback URL!"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){}];
        
        [alertController addAction:okAction];
        
        [AudioShare showAlertController:alertController];

        return NO;
    }
    NSURL *asURL = [NSURL URLWithString:[NSString stringWithFormat:@"audioshare.import://%@",callback]];
    if(![[UIApplication sharedApplication] canOpenURL:asURL]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        NSArray *typeArray = @[(NSString *) kUTTypeAudio];
        NSIndexSet *set = [board itemSetWithPasteboardTypes:typeArray];
        BOOL hasAudio = [board containsPasteboardTypes:typeArray inItemSet:set];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AudioShare"
                                                                                 message:[hasAudio?@"Audio was pasted from pasteboard.":@"No audio in pasteboard." stringByAppendingString:@"\n\nInstall AudioShare for easy storage and management of all your soundfiles, and more copy/paste functionality. You can get it on the App Store."]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action){}];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
                                   {
                                       [AudioShare openURL:[NSURL URLWithString:@"http://kymatica.com/audioshare/download.php"]];
                                   }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];

        [AudioShare showAlertController:alertController];
        
        if(hasAudio)
            asURL = [NSURL URLWithString:[callback stringByAppendingString:@"://PastedAudio"]];
        else
            return NO;
    }
    [AudioShare openURL:asURL];
    return YES;
}

- (NSString*)writeSoundImport:(NSString*)filename {
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    NSArray *typeArray = [NSArray arrayWithObject:(NSString *) kUTTypeAudio];
    NSIndexSet *set = [board itemSetWithPasteboardTypes:typeArray];
    if (!set)
        return nil;
    NSArray *items = [board dataForPasteboardType:(NSString *) kUTTypeAudio inItemSet:set];
    if (items) {
        NSUInteger cnt = [items count];
        if (!cnt)
            return nil;
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil])
            return nil;
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!handle)
            return nil;
        for (NSUInteger i = 0; i < cnt; i++)
            [handle writeData:[items objectAtIndex:i]];
        [handle closeFile];
        
        if(![[filename pathExtension] length]) {
            NSString *ext = [AudioShare findFileType:path];
            if(ext) {
                NSString *newPath = [path stringByAppendingPathExtension:ext];
                if([[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:nil])
                    path = newPath;
            }
        }
        
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
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry"
                                                                                     message:@"There was a problem trying to import a sound from AudioShare!"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action){}];
            
            [alertController addAction:okAction];
            
            [AudioShare showAlertController:alertController];

            return NO;
        }
        block(path);
        return YES;
    } else {
        return NO;
    }
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidLaunch) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)appDidLaunch {
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = bundle.infoDictionary;
    NSArray *list = info[@"LSApplicationQueriesSchemes"];
    if(!([list containsObject:@"audioshare.import"] && [list containsObject:@"audiosharecmd"])) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing URL schemes in whitelist!"
                                                                                 message:@"Hello developer. This app does not whitelist the AudioShare URL schemes, needed for iOS 9. See instructions at http://github.com/lijon/AudioShareSDK"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){}];
        
        [alertController addAction:okAction];
        
        [AudioShare showAlertController:alertController];
    }
}

+ (BOOL)fileIsMIDI:(NSString*)path {
    const char *cpath = [path fileSystemRepresentation];
    FILE *fp = fopen(cpath,"r");
    if(fp) {
        char buf[5];
        fread(buf,1,4,fp);
        fclose(fp);
        buf[4]='\0';
        if(strcmp(buf, "MThd")==0)
            return YES;
    }
    return NO;
}

+ (NSString*)findFileType:(NSString*)path {
    if([self fileIsMIDI:path])
        return @"mid";
    NSURL *audioFileURL = [NSURL fileURLWithPath:path];
    AudioFileID af = NULL;
    AudioFileOpenURL((__bridge CFURLRef)audioFileURL, kAudioFileReadPermission, 0, &af);
    if(!af) return nil;
    AudioFileTypeID typeID;
    UInt32 size = sizeof(typeID);
    AudioFileGetProperty(af, kAudioFilePropertyFileFormat, &size, &typeID);
    AudioFileClose(af);
    switch(typeID) {
        case kAudioFileAIFFType: return @"aiff";
        case kAudioFileAIFCType: return @"aifc";
        case kAudioFileWAVEType: return @"wav";
        case kAudioFileSoundDesigner2Type: return @"sd2";
        case kAudioFileNextType: return @"nxt";
        case kAudioFileMP3Type: return @"mp3";
        case kAudioFileMP2Type: return @"mp2";
        case kAudioFileMP1Type: return @"mp1";
        case kAudioFileAC3Type: return @"ac3";
        case kAudioFileAAC_ADTSType: return @"adts";
        case kAudioFileMPEG4Type: return @"mp4";
        case kAudioFileM4AType: return @"m4a";
        case kAudioFileCAFType: return @"caf";
        case kAudioFile3GPType: return @"3gp";
        case kAudioFile3GP2Type: return @"3gp2";
        case kAudioFileAMRType: return @"amr";
        default:
            return nil;
    }
}

@end
