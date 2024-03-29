//
//  JHSearchSuggestViewController.m
//  JHSearch
//
//  Created by HWA on 2018/7/20.
//  Copyright © 2018年 HWA. All rights reserved.
//

#import "JHSearchSuggestViewController.h"
#import "JHTableViewSctionView.h"

@interface JHSearchSuggestViewController ()

<UISearchBarDelegate,
UITableViewDataSource,
UITableViewDelegate,
JHSuggestTableViewCellDelegate,
JHTableViewSctionViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView    *tableView;
@property (strong, nonatomic) NSMutableArray        *dataArray;
@property (strong, nonatomic) NSMutableArray <NSString *> *historyArray;

@end

@implementation JHSearchSuggestViewController

static NSString *const cellID = @"JHSuggestTableViewCellID";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44.0;
    [self.tableView registerNib:[UINib nibWithNibName:@"JHSuggestTableViewCell" bundle:nil] forCellReuseIdentifier:cellID];
    [self.tableView setTableFooterView:[[UIView alloc] init]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    
//    if ([historyArray count] > 0) {
//        [self.dataArray addObject:historyArray];
//    }
//    [self.tableView reloadData];
}

- (void)dealWithData {
    
    NSArray *historyArr = [NSKeyedUnarchiver unarchiveObjectWithFile:PATH_SEARCH_HISTORY];
    
    self.historyArray = [historyArr mutableCopy];
    
    if ([self.hotSearchs count] > 0 && [self.historyArray count] > 0) {
        [self.dataArray addObject:self.hotSearchs];
        [self.dataArray addObject:self.historyArray];
    }
    
    if ([self.hotSearchs count] == 0 && [self.historyArray count] > 0) {
        
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)reloadHotSearchTags:(NSArray *)tags {
    if ([self.dataArray count] >= 1) {
        [self.dataArray replaceObjectAtIndex:0 withObject:tags];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

//MARK: - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_scrollViewDidScrollHandler) {
        _scrollViewDidScrollHandler(scrollView);
    }
}

//MARK: - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    JHSuggestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    [cell showContentWithTags:self.dataArray[indexPath.section] tableView:tableView indexPath:indexPath];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    JHTableViewSctionView *sectionView = [[JHTableViewSctionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44.0)];

//    if (section == 0) {
//        sectionView.rightButton.hidden = YES;
//        sectionView.titleLabel.text = @"热门搜索";
//    } else {
//        sectionView.titleLabel.text = @"搜索历史";
//    }
    sectionView.delegate = self;
    return sectionView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 10.0;
    } else {
        return CGFLOAT_MIN;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return 44.0;
    } else {
        return CGFLOAT_MIN;
    }
}

//MARK: - JHTableViewSctionViewDelegate

- (void)sectionView:(JHTableViewSctionView *)sectionView didSelectButton:(UIButton *)sender section:(NSInteger)section {
    
    NSArray *historyArray = [NSKeyedUnarchiver unarchiveObjectWithFile:PATH_SEARCH_HISTORY];
    NSMutableOrderedSet *mutableOrderedSet;
    if ([historyArray count] > 0) {
        mutableOrderedSet = [NSMutableOrderedSet orderedSetWithArray:historyArray];
    }
    if ([mutableOrderedSet count] > 0) {
        [mutableOrderedSet removeAllObjects];
    }
    
    [NSKeyedArchiver archiveRootObject:mutableOrderedSet toFile:PATH_SEARCH_HISTORY];
    
    if ([self.dataArray count] > 1) {
        [self.dataArray removeObjectAtIndex:1];
        [self.tableView reloadData];
    }
}

//MARK: - JHSuggestTableViewCellDelegate

- (void)suggestTableViewCell:(JHSuggestTableViewCell *)cell didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *searchText = self.dataArray[indexPath.section][indexPath.row];
    
    NSMutableArray *arrayM = [[NSMutableArray alloc] init];
    if ([self.dataArray count] > 1) {
        NSArray *historyArray = [NSKeyedUnarchiver unarchiveObjectWithFile:PATH_SEARCH_HISTORY];
    
        [arrayM addObjectsFromArray:historyArray];
        [arrayM insertObject:searchText atIndex:0];
    } else {
        [arrayM insertObject:searchText atIndex:0];
    }
    
    NSMutableOrderedSet *mutableOrderedSet = [NSMutableOrderedSet orderedSetWithArray:arrayM];
    
    [NSKeyedArchiver archiveRootObject:[mutableOrderedSet array] toFile:PATH_SEARCH_HISTORY];
    
    if ([self.dataArray count] > 1) {
        [self.dataArray removeObjectAtIndex:1];
    }
    
    [self.dataArray addObject:[mutableOrderedSet array]];
    [self.tableView reloadData];
    
    if ([self.delegate respondsToSelector:@selector(searchSuggestViewController:suggestTableViewCell:searchText:)]) {
        [self.delegate searchSuggestViewController:self suggestTableViewCell:cell searchText:searchText];
    }
}


//MARK: - Setter & Getter

- (NSMutableArray *)dataArray {
    if (_dataArray == nil) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (void)setHotSearchs:(NSArray<NSString *> *)hotSearchs {
    _hotSearchs = hotSearchs;
//    if ([self.dataArray count] > 0) {
//        [self.dataArray replaceObjectAtIndex:0 withObject:_hotSearchs];
//    } else {
//        [self.dataArray addObject:_hotSearchs];
//    }
}

- (NSMutableArray<NSString *> *)historyArray {
    if (_historyArray == nil) {
        _historyArray = [[NSMutableArray alloc] init];
    }
    return _historyArray;
}


@end
