//
//  SearchManager.m
//  KinopoiskParserObj
//
//  Created by YAUHENI DROBAU on 05/12/2016.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import "SearchManager.h"

#import "Macros.h"

@interface SearchManager ()
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end
@implementation SearchManager
SINGLETON(SearchManager)

-(NSArray*)updateSearchResults:(NSString *)searchText forArray:(NSArray*)newsArray {
    if (!searchText) {
        self.searchResults = [newsArray mutableCopy];
    } else {
        NSArray *searchResults = [NSMutableArray new];
        for (NSInteger i = 0;i < newsArray.count;i++) {
            NewsEntity *entity = newsArray[i];
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"titleFeed contains[c] %@", searchText];
            searchResults = [newsArray filteredArrayUsingPredicate:resultPredicate];
//            if ([entity.titleFeed containsString:searchText]) {
//                [searchResults addObject:entity];
//            }
        }
        self.searchResults = searchResults;
    }
    return self.searchResults;
}

@end