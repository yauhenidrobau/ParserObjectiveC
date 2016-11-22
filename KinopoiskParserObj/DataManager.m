//
//  DataManager.m
//  KinopoiskParserObj
//
//  Created by YAUHENI DROBAU on 01.09.16.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//


#import "DataManager.h"

#import "RemoteFacade.h"
#import "ParserManager.h"
#import "Constants.h"
#import "RealmDataManager.h"
#import "Macros.h"

@interface DataManager ()
@property(nonatomic, strong) NSMutableDictionary<NSString *,NSString *> *infoDict;
@end
@implementation DataManager

SINGLETON(DataManager)

-(void)updateDataWithURLString:(NSString *)urlString AndTitleString:(NSString *)titleString WithCallBack:(UpdateDataCallback)completionHandler {
    [[RemoteFacade sharedInstance] loadData:urlString callback:^(NSData *info, NSError *error) {
        if (error || !info) {
            //TODO: handle error
        } else {
            [[ParserManager sharedInstance] parseXmlData:info callback:^(NSData * dict, NSError *error) {
                [[RealmDataManager sharedInstance]saveNews:dict withServiceString:titleString];
                if (completionHandler) {
                    completionHandler(error);
                }
            }];
        }
    }];
}
@end
