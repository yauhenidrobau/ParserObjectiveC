//
//  SettingsVC.m
//  KinopoiskParserObj
//
//  Created by YAUHENI DROBAU on 28/12/2016.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import "SettingsVC.h"

#import "SettingsOfflineCell.h"
#import "SettingsNotificationsCell.h"

#define SIGN_OUT_CELL_TYPE @"SignOutCell"
#define OFFLINE_CELL_TYPE @"OfflineCell"
#define NOTIFICATION_CELL_TYPE @"NotificationCell"

#define OFFLINE_MODE @"OfflineMode"
#define NOTIFICATIONS_MODE @"NotificationsMode"

@interface SettingsVC () <SettingsCellDelegate>

@property (nonatomic, strong) NSArray *cellTitleList;
@property (nonatomic, strong) NSArray *cellTitleListID;
@property (nonatomic, strong) NSArray *sectionList;
@property (nonatomic, strong) NSArray *viewControllersList;
@property (nonatomic, strong) NSArray *sectionAboutLinkList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsVC

-(NSArray *)cellTitleListID {
    if (!_cellTitleListID.count) {
        _cellTitleListID = @[@"SignOutCell",
                           @"OfflineCell",
                           @"NotificationCell"
                           ];
    }
    return _cellTitleListID;
}

-(NSArray *)cellTitleList {
    if (!_cellTitleList.count) {
        _cellTitleList = @[@"SVC_SIGN_OUT",
                           @"SVC_OffLine",
                           @"SVC_SOUND"
//                             @"SVC_PUSH_NOTIFICATIONS",
                             ];
    }
    return _cellTitleList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:NSLocalizedString(@"Settings", nil)];
    [self.navigationController.navigationBar setHidden:NO];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cellTitleList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellTitleListID[indexPath.row] forIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:OFFLINE_CELL_TYPE]) {
        SettingsOfflineCell *offlineCell = (SettingsOfflineCell *)cell;
        offlineCell.cellDelegate = self;
    } else if ([cell.reuseIdentifier isEqualToString:NOTIFICATION_CELL_TYPE]) {
        SettingsNotificationsCell *offlineCell = (SettingsNotificationsCell *)cell;
        offlineCell.cellDelegate = self;
    }
    if ([cell.reuseIdentifier isEqualToString:SIGN_OUT_CELL_TYPE]) {
    }
    return cell;
}

#pragma mark UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  50.0;
}

#pragma mark - SettingsCellDelegate
- (void)settingsOfflineCell:(UITableViewCell*)cell didChangeValue:(UISwitch*)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:@"OfflineMode"];
}

- (void)settingsNotificationsCell:(UITableViewCell *)cell didChangeValue:(UISwitch *)sender{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:@"NotificationsMode"];
}
#pragma mark Private



@end
