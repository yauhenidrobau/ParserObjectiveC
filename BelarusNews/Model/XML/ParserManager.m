//
//  ParserManager.m
//  BelarusNews
//
//  Created by YAUHENI DROBAU on 01.09.16.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import "ParserManager.h"

#import "XMLParser.h"
#import "Macros.h"

@interface ParserManager () <XMLParserDelegate>

@property (nonatomic, copy) ParseCallback callback;
@property(nonatomic, strong) NSArray *info;

@end

@implementation ParserManager

SINGLETON(ParserManager)

-(void) parseXmlData:(NSData *)data callback:(ParseCallback)completion {
    self.callback = completion;
    XMLParser *parser = [[XMLParser alloc]init];
    parser.xmlParserDelegate = self;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [parser parseData:data];
//    });    
}

-(void) xmlParserDidFinishParsing: (NSArray<NSDictionary*>*)items  error: (NSError *)error{
    __weak typeof (self)wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (wself.callback) {
            wself.info = items;
            if (wself.callback) {
                wself.callback(wself.info, nil);
            }
        }
    });
    
    if ([NSThread isMainThread]) {
        NSLog(@"is main");
    } else {
        NSLog(@"is background");
    }
    
    
}


@end

