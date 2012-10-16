AudioShare SDK
==============

This SDK will let you export audio to the AudioShare app for iPhone, iPad and iPod touch.
It can transfer soundfiles from memory or from file.

AudioShare - audio document manager, is a simple tool to manage all your sounds in a single
place on your device, with easy transferring of sounds between AudioShare and other apps or
your computer. Read more about it here: http://kymatica.com/audioshare

Usage
-----

First, copy the files `AudioShareSDK.h` and `AudioShareSDK.m` into your project.

The typical usage is to have a button or menu item labelled "Export to AudioShare" that
transfers a soundfile from your own app into AudioShare. Just put the following line in
the code that gets called when the user taps the button:

    [[AudioShare sharedInstance] addSoundFromURL:theUrlToYourFile withName:@"My Sound"];

In case you have your sound in memory, you can send an NSData instead:

    [[AudioShare sharedInstance] addSoundFromData:yourSoundData withName:@"My Sound"];

These methods will check that a recent enough version of AudioShare is installed, and otherwise
present the user with the option to view the app on the App Store. If AudioShare was installed,
it will open AudioShare and import the audio, and return YES if successfull.

Don't forget to import the header:

    #import "AudioShareSDK.h"

Supported formats
-----------------

AudioShare supports all soundfile formats, bit depths and rates, that has built-in support in iOS: AIFF, AIFC, WAVE, SoundDesigner2, Next, MP3, MP2, MP1, AC3, AAC_ADTS, MPEG4, M4A, CAF, 3GP, 3GP2, AMR.

License
-------

You are free to incorporate this code in your own application, for the purpose of launching
and/or transferring sounds to the AudioShare app.

If you do, I would appreciate if you drop me a message at lijon@kymatica.com

Copyright (C)2012 Jonatan Liljedahl
http://kymatica.com
