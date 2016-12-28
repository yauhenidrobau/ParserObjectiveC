//
//  NewsTableView.m
//  KinopoiskParserObj
//
//  Created by YAUHENI DROBAU on 01.09.16.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import "NewsTableView.h"

#import <Realm/Realm.h>
#import "DataManager.h"
#import "NewsTableViewCell.h"
#import "DetailsViewController.h"
#import "NewsEntity.h"
#import "SearchManager.h"
#import <UIKit/UIKit.h>
#import <Reachability.h>
#import <UIAlertController+Blocks.h>
#import "UIViewController+LMSideBarController.h"
#import "Constants.h"
#import "Macros.h"

#import "INSSearchBar.h"

#import "Masonry.h"
#import "ZLDropDownMenuUICalc.h"
#import "ZLDropDownMenuCollectionViewCell.h"
#import "ZLDropDownMenu.h"
#import "NSString+ZLStringSize.h"

typedef void(^UpdateDataCallback)(NSError *error);
typedef enum {
    AllCategoryType = 0,
    DevByCategoryType = 1,
    TutByCategoryType  = 2,
    MtsByCategoryType = 3
}CategoryTypes;

#define MAIN_COLOR RGB(25, 120, 137)

@interface NewsTableView () <UIScrollViewDelegate,UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource,DZNEmptyDataSetDelegate,LMSideBarControllerDelegate, ZLDropDownMenuDelegate, ZLDropDownMenuDataSource,INSSearchBarDelegate>

@property (weak, nonatomic) IBOutlet UIButton *scrollButton;
@property (weak, nonatomic) IBOutlet UIView *searchBarView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityInd;
@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, strong) INSSearchBar *searchBar;

@property (nonatomic) CGPoint lastContentOffset;
@property (strong, nonatomic) NSOperationQueue * operationQueue;
@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSString *titlesString;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) RLMRealm *realm;

@property (nonatomic, strong) NSArray<NewsEntity *> *searchResults;
@property (strong, nonatomic) NSArray *newsArray;
@property (nonatomic, strong) NSArray *mainTitleArray;
@property (nonatomic, strong) NSArray *subTitleArray;
@property (strong, nonatomic) NSDictionary *newsURLDict;

@property (nonatomic) BOOL isAlertShown;
@property (nonatomic) BOOL isSearchStart;
@property(nonatomic, getter=isNavigationBarHidden) BOOL navigationBarHidden;

@end

@implementation NewsTableView

#pragma mark - Lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _mainTitleArray = @[@"TUT.BY",@"DEV.BY", @"PRAVO.BY", @"MTS"];
    _subTitleArray = @[
                       @[@"Main", @"Economic", @"Society", @"World",@"Culture",@"Accident",@"Finance",@"Realty",@"Sport",@"Auto",@"Lady",@"Science"],
                       @[@"All News"],
                       @[@"All News"],
                       @[@"All News"]
                       ];
    self.newsURLDict = @{@"DEV.BY": @[DEV_BY_NEWS],
                         @"TUT.BY": [NSDictionary dictionaryWithObjectsAndKeys:
                                     MAIN_NEWS,@"Main",
                                     ECONOMIC_NEWS,@"Economic",
                                     SOCIETY_NEWS,@"Society",
                                     WORLD_NEWS,@"World",
                                     CULTURE_NEWS,@"Culture",
                                     ACCIDENT_NEWS,@"Accident",
                                     FINANCE_NEWS,@"Finance",
                                     REALTY_NEWS,@"Realty",
                                     SPORT_NEWS,@"Sport",
                                     AUTO_NEWS,@"Auto",
                                     LADY_NEWS,@"Lady",
                                     SCIENCE_NEWS,@"Science", nil],
                         @"PRAVO.BY" : @[PRAVO_NEWS],
                         @"YANDEX" : @[YANDEX_NEWS],
                         @"MTS" : @[MTS_BY_NEWS]};

    ZLDropDownMenu *menu = [[ZLDropDownMenu alloc] initWithFrame:CGRectMake(0, 0, deviceWidth(), 43)];
    menu.delegate = self;
    menu.dataSource = self;
    [self.menuView addSubview:menu];

    
//    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.realm = [RLMRealm defaultRealm];
    self.titlesString = self.subTitleArray[0][0];
    self.urlString = MAIN_NEWS;
    [self setAppierance];
    [self addPullToRefresh];
    self.isAlertShown = NO;
    self.operationQueue = [NSOperationQueue new];
//    self.urlIdentificator = self.urlIdentificator.length? self.urlIdentificator : @"DEV.BY";
    [self setupData];

}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:@""];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(timerActionRefresh) userInfo:nil repeats:YES];
    [self update];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - IBActions

-(void)onRefreshBtnTouch {
    [self update];
}

-(void)onFavoriteBtnTouch:(UIButton *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    NewsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NewsEntity *entity = [self setNewsEntityForIndexPath:indexPath];
    [self.realm beginWriteTransaction];
    
    [cell.favoriteButton setImage:[cell.favoriteButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    if (entity.favorite) {
        [cell.favoriteButton setTintColor:[UIColor grayColor]];
    } else {
        [cell.favoriteButton setTintColor:[UIColor yellowColor]];
    }
    entity.favorite = !entity.favorite;
    [self.realm addOrUpdateObject:entity];
    [self.realm commitWriteTransaction];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

}

-(void)pullToRefresh {
    [self updateDataWithIndicator:NO];
}
- (IBAction)leftBarItemTouchUpInside:(id)sender {
    [self.sideBarController showMenuViewControllerInDirection:LMSideBarControllerDirectionLeft];
}

-(IBAction)scrollButtonTouchUpInside:(id)sender {
    __weak __typeof(self) wself = self;
    [UIView animateWithDuration:0.9 animations:^{
        [wself.tableView setContentOffset:CGPointZero animated:YES];
    }];
    self.scrollButton.hidden = YES;
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearchStart) {
        return self.searchResults.count? self.searchResults.count : 0;
    }
    return self.newsArray.count? self.newsArray.count : 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    NewsTableViewCell *cell = [tableView  dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NewsEntity *newsEntity = nil;
    cell.backgroundColor = MAIN_COLOR;
    cell.favoriteButton.tag = indexPath.row;
    [cell.favoriteButton addTarget:self action:@selector(onFavoriteBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    newsEntity = [self setNewsEntityForIndexPath:indexPath];
    [cell cellForNews:newsEntity];
    [self setFavoriteButtonForCell:cell WithEntity:newsEntity];
    
    return cell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return self.scrollButton.frame.size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc]initWithFrame:self.scrollButton.frame];
    view.alpha = 0;
    view.backgroundColor = [UIColor clearColor];
    return view;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DetailsVCID"]) {
        UITableViewCell *cell = (UITableViewCell*)sender;
        DetailsViewController *vc = segue.destinationViewController;
        NewsEntity *newsEntity = self.searchResults[[self.tableView indexPathForCell:cell].row]? self.searchResults[[self.tableView indexPathForCell:cell].row] : self.newsArray[[self.tableView indexPathForCell:cell].row];
        vc.newsUrl =[NSURL URLWithString:newsEntity.linkFeed];
        [vc.navigationItem setTitle:self.mainTitleArray[[self.tableView indexPathForCell:cell].row]];
    }
}


#pragma mark - DZNEmptyDataSetSource

-(NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = NSLocalizedString(@"No News", nil);
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0],
                                 NSForegroundColorAttributeName: [UIColor colorWithRed:170/255.0 green:171/255.0 blue:179/255.0 alpha:1.0],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    
    return [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
}

-(NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if (self.isSearchStart || self.menuTitle.length) {
        text = @"";
    } else {
    text = NSLocalizedString(@"No Network", nil);
    }
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:15.0],
                                 NSForegroundColorAttributeName: [UIColor colorWithRed:170/255.0 green:171/255.0 blue:179/255.0 alpha:1.0],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    
    return [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
}

-(UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"no_data"];
}

-(UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - DZNEmptyDataSetSource Methods

-(BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

-(BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView {
    return NO;
}

-(BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return NO;
}

#pragma mark - ZLDropDownMenuDataSource

- (NSInteger)numberOfColumnsInMenu:(ZLDropDownMenu *)menu {
    return self.mainTitleArray.count;
}

- (NSInteger)menu:(ZLDropDownMenu *)menu numberOfRowsInColumns:(NSInteger)column {
    
    return ((NSArray*)self.subTitleArray[column]).count;
}

- (NSString *)menu:(ZLDropDownMenu *)menu titleForColumn:(NSInteger)column {
    return self.mainTitleArray[column];
}

- (NSString *)menu:(ZLDropDownMenu *)menu titleForRowAtIndexPath:(ZLIndexPath *)indexPath {
    NSArray *array = self.subTitleArray[indexPath.column];
    if (array.count) {
       return array[indexPath.row];
    } else
    return @"";
}

#pragma mark - ZLDropDownMenuDelegate
- (void)menu:(ZLDropDownMenu *)menu didSelectRowAtIndexPath:(ZLIndexPath *)indexPath {
    self.menuTitle = @"";
    NSArray *array = self.subTitleArray[indexPath.column];
//    NSLog(@"%@", array[indexPath.row]);
    if (array.count == 1) {
        self.titlesString = self.mainTitleArray[indexPath.column];
        self.urlString = self.newsURLDict[self.titlesString][0];
    } else {
    self.titlesString = array[indexPath.row];
    NSDictionary *dict = self.newsURLDict[self.mainTitleArray[indexPath.column]];
    self.urlString = dict[self.titlesString];
    }
    NSLog(@"%@ : %@", self.titlesString,self.urlString);
    [self updateDataWithIndicator:YES];

}

#pragma mark - INSSearchBarDelegate

- (CGRect)destinationFrameForSearchBar:(INSSearchBar *)searchBar {
    return CGRectMake(10, 67, CGRectGetWidth(self.view.bounds) - 10.0, 38.0);
}

- (void)searchBar:(INSSearchBar *)searchBar willStartTransitioningToState:(INSSearchBarState)destinationState {
    if (destinationState == INSSearchBarStateSearchBarVisible) {
        searchBar.searchField.tintColor = MAIN_COLOR;
    }
}

- (void)searchBar:(INSSearchBar *)searchBar didEndTransitioningFromState:(INSSearchBarState)previousState {
    searchBar.searchField.placeholder = NSLocalizedString(@"Search for news...", nil);
}

- (void)searchBarDidTapReturn:(INSSearchBar *)searchBar {
    // Do whatever you deem necessary.
    // Access the text from the search bar like searchBar.searchField.text
}

- (void)searchBarTextDidChange:(INSSearchBar *)searchBar {
    NSString *searchText = searchBar.searchField.text;
    if (searchText.length > 2) {
        [self showLoadingIndicator:YES];
        self.isSearchStart = YES;
        __weak typeof (self)wself = self;
        [[SearchManager sharedInstance]updateSearchResults:self.searchBar.searchField.text forArray:self.newsArray withCompletion:^(NSArray *searchResults, NSError *error) {
            wself.searchResults = searchResults;
            [wself showLoadingIndicator:NO];
            NSLog(@"Get SEARCH");
            
            [wself.tableView reloadData];
        }];
    } else {
        self.isSearchStart = NO;
        [self setupData];
        NSLog(@"Get from DataBase");
    }
}

#pragma mark UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.scrollButton.hidden = !(scrollView.contentOffset.y > 20);
    UITapGestureRecognizer *gestureRecognizer = [UITapGestureRecognizer new];
    [self.searchBar hideSearchBar:gestureRecognizer];
}

#pragma mark - Private methods

-(void)addPullToRefresh {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:173/255.0 green:31/255.0 blue:45/255.0 alpha:1.0];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

-(void)timerActionRefresh {
    [self update];
}

-(void)setAppierance {
    [self.activityInd setHidden:YES];
    self.scrollButton.hidden = YES;
    
    self.tableView.estimatedRowHeight = 80;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.navigationItem.titleView setTintColor:[UIColor whiteColor]];
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshBtnTouch)];
    self.navigationItem.rightBarButtonItem = refreshBtn;
    
    self.searchBar = [[INSSearchBar alloc] initWithFrame:CGRectMake(10.0, 67.0,44.0, 38.0)];
    self.searchBar.delegate = self;
    self.searchBarView.backgroundColor = MAIN_COLOR;
    [self.view addSubview:self.searchBar];
    
}

-(void)setupData{
    [self showLoadingIndicator:YES];
    if (!self.menuTitle.length) {
        RLMResults *results = [NewsEntity objectsWhere:@"feedIdString == %@",self.titlesString];
        NSArray *allResultsArray = [self RLMResultsToArray:results];
        
        self.newsArray = [self sortNewsArray:allResultsArray];
        NSLog(@"Get ELEMENTS  %lu",(unsigned long)self.newsArray.count);
        
    } else {
        RLMResults *results = [NewsEntity allObjects];
        NSArray *allResultsArray = [self RLMResultsToArray:results];
        NSMutableArray *favoritesArray = [NSMutableArray array];
        for (NewsEntity *entity in allResultsArray) {
            if (entity.favorite) {
                [favoritesArray addObject:entity];
            }
        }
        self.newsArray = [self sortNewsArray:[NSArray arrayWithArray:favoritesArray]];
        NSLog(@"Get favorites Elements  %lu",(unsigned long)self.newsArray.count);
    }
    [self.tableView reloadData];
    [self showLoadingIndicator:NO];

    if (!self.newsArray.count) {
        [self.tableView setScrollEnabled:NO];
        [self.activityInd stopAnimating];
        [self.refreshControl endRefreshing];
    }
}


-(NSArray *)sortNewsArray:(NSArray*)newsArray {
    NSSortDescriptor * newSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pubDateFeed" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:newSortDescriptor];
    self.newsArray = [newsArray sortedArrayUsingDescriptors:sortDescriptors];
    return self.newsArray;
}

-(NSArray*)RLMResultsToArray:(RLMResults *)results{
    NSMutableArray *array = [NSMutableArray array];
    for (RLMObject *object in results) {
        [array addObject:object];
    }
    return array;
}
-(void)showLoadingIndicator:(BOOL)show {
    self.activityInd.hidden = !show;
    if (show) {
        [self.activityInd startAnimating];
    }else {
        [self.activityInd stopAnimating];
    }
}

-(void)showAlertController {
    if (!self.isAlertShown) {
//        [self showLoadingIndicator:YES];
        __weak typeof(self) wself = self;
        [UIAlertController  showAlertInViewController:self
                                            withTitle:NSLocalizedString(@"We have problems", nil)
                                              message:NSLocalizedString(@"No Network",nil)
                                    cancelButtonTitle:NSLocalizedString(@"OK",nil)
                               destructiveButtonTitle:nil
                                    otherButtonTitles:nil
                                             tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                                                 [wself setupData];
                                                 [wself showLoadingIndicator:NO];
                                             }];
        self.isAlertShown = YES;
    }
}

-(void)update {
    [self updateDataWithIndicator:YES];
}

-(void)updateDataWithIndicator:(BOOL)showIndicator {
    [self showLoadingIndicator:showIndicator];

    dispatch_async(dispatch_get_main_queue(), ^{

        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        if (networkStatus == NotReachable) {
            [self showAlertController];
//            [self setupData];
        }else {
            [networkReachability startNotifier];
            if(networkStatus == NotReachable) {
                [self showAlertController];
//                [self setupData];
            } else {
                self.isAlertShown = NO;
                
//                NSString *urlString = [self.newsURLDict[_urlIdentificator] isKindOfClass:[NSArray class]]? s
                
                __weak typeof(self) wself = self;
                [[DataManager sharedInstance ] updateDataWithURLArray:wself.urlString AndTitle:wself.titlesString WithCallBack:^(NSError *error) {

                    [networkReachability stopNotifier];
                    if (!error) {
                        [wself setupData];
                        if(showIndicator) {
                        [wself showLoadingIndicator:!showIndicator];
                        }
                        [wself.refreshControl endRefreshing];
                        [wself.tableView reloadData];
                    }
                }];
            }
        }
    });
}

-(NewsEntity *)setNewsEntityForIndexPath:(NSIndexPath*)indexPath {
    NewsEntity *newsEntity = nil;
    if (self.isSearchStart) {
        newsEntity = self.searchResults.count? self.searchResults[indexPath.row] : self.newsArray[indexPath.row];
    } else {
        newsEntity = self.newsArray.count? self.newsArray[indexPath.row] : self.newsArray[indexPath.row];
    }
    return newsEntity;
}

-(void)setFavoriteButtonForCell:(NewsTableViewCell *)cell WithEntity:(NewsEntity *)entity {
    [cell.favoriteButton setImage:[cell.favoriteButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    if (entity.favorite) {
        cell.favoriteButton.tintColor = [UIColor yellowColor];
    } else {
        cell.favoriteButton.tintColor = [UIColor lightGrayColor];
    }
}
//-(void)setupAppearanceNewsSegmentedControl {
//    [self.NewsSegmentedControl layoutIfNeeded];
//    UIColor *mainColor = [UIColor colorWithRed:253. / 255. green:253. /255. blue:253. / 255. alpha:1.0];
//    self.NewsSegmentedControl.borderWidth = 0.5f;
//    self.NewsSegmentedControl.borderColor = [UIColor colorWithWhite:227./255. alpha:1.0f];
//    self.NewsSegmentedControl.backgroundColor = [UIColor colorWithRed:235./255. green:236./255. blue:239./255. alpha:1.0f];
////    self.NewsSegmentedControl.layer.cornerRadius = self.NewsSegmentedControl.frame.size.height / 2;
//    self.NewsSegmentedControl.cornerRadius = self.NewsSegmentedControl.frame.size.height / 2;
//    self.NewsSegmentedControl.drawsGradientBackground = NO;
//    self.NewsSegmentedControl.drawsSegmentIndicatorGradientBackground = YES;
//    self.NewsSegmentedControl.segmentIndicatorGradientTopColor = mainColor;
//    self.NewsSegmentedControl.segmentIndicatorGradientBottomColor = mainColor;
//    self.NewsSegmentedControl.segmentIndicatorAnimationDuration = 0.3f;
//    self.NewsSegmentedControl.segmentIndicatorBorderWidth = 0.0f;
//    self.NewsSegmentedControl.selectedTitleTextColor = [UIColor colorWithRed:9. / 255. green:171. /255. blue:225. / 255. alpha:1.0];
//    self.NewsSegmentedControl.titleTextColor = [UIColor colorWithRed:98. / 255. green:128. /255. blue:142. / 255. alpha:1.0];
//    self.NewsSegmentedControl.dataSource = self;
//    [self.NewsSegmentedControl addTarget:self action:@selector(changeValueSC) forControlEvents:UIControlEventValueChanged];
//}

//-(NSString *)getTitleFromNewsClass:(id)news{
//    NSDictionary *dict = self.newsURLDict[self.urlIdentificator];
//
//    if ([news isKindOfClass:[NSArray class]]) {
////        NSArray *temp = self.newsURLDict[self.urlIdentificator];
//        return self.urlIdentificator;
//    } else
//       return dict.allKeys[self.NewsSegmentedControl.selectedSegmentIndex];
//}
//
//-(NSString *)getUrlFromDictionary {
//    NSDictionary *dict = self.newsURLDict[self.urlIdentificator];
//    
//    if ([dict isKindOfClass:[NSArray class]]) {
//        NSArray *temp = self.newsURLDict[self.urlIdentificator];
//        return temp[0];
//    } else
//        return dict.allValues[self.NewsSegmentedControl.selectedSegmentIndex];
//}
@end
