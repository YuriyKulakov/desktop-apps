/*
 * (c) Copyright Ascensio System SIA 2010-2016
 *
 * This program is a free software product. You can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License (AGPL)
 * version 3 as published by the Free Software Foundation. In accordance with
 * Section 7(a) of the GNU AGPL its Section 15 shall be amended to the effect
 * that Ascensio System SIA expressly excludes the warranty of non-infringement
 * of any third-party rights.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR  PURPOSE. For
 * details, see the GNU AGPL at: http://www.gnu.org/licenses/agpl-3.0.html
 *
 * You can contact Ascensio System SIA at Lubanas st. 125a-25, Riga, Latvia,
 * EU, LV-1021.
 *
 * The  interactive user interfaces in modified source and object code versions
 * of the Program must display Appropriate Legal Notices, as required under
 * Section 5 of the GNU AGPL version 3.
 *
 * Pursuant to Section 7(b) of the License you must retain the original Product
 * logo when distributing the program. Pursuant to Section 7(e) we decline to
 * grant you any rights under trademark law for use of our trademarks.
 *
 * All the Product's GUI elements, including illustrations and icon sets, as
 * well as technical writing content are licensed under the terms of the
 * Creative Commons Attribution-ShareAlike 4.0 International. See the License
 * terms at http://creativecommons.org/licenses/by-sa/4.0/legalcode
 *
*/

//
//  ViewController.m
//  ONLYOFFICE
//
//  Created by Alexander Yuzhin on 9/7/15.
//  Copyright (c) 2015 Ascensio System SIA. All rights reserved.
//

#import "ViewController.h"
#import "mac_application.h"
#import "ASCTabsControl.h"
#import "ASCTabView.h"
#import "ASCTitleWindowController.h"
#import "ASCHelper.h"
#import "ASCConstants.h"
#import "ASCUserInfoViewController.h"
#import "NSView+ASCView.h"
#import "NSString+OnlyOffice.h"
#import "AppDelegate.h"
#import "NSCefView.h"
#import "ASCEventsController.h"
#import "NSString+OnlyOffice.h"
#import "ASCDownloadController.h"
#import "NSTimer+Block.h"

#define rootTabId @"1CEF624D-9FF3-432B-9967-61361B5BFE8B"

@interface ViewController() <ASCTabsControlDelegate, ASCTitleBarControllerDelegate, ASCUserInfoViewControllerDelegate>
@property (weak) ASCTabsControl *tabsControl;
@property (nonatomic) NSCefView * cefStartPageView;
@property (weak) IBOutlet NSTabView *tabView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onWindowLoaded:)
                                                 name:ASCEventNameMainWindowLoaded
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFCreateTab:)
                                                 name:CEFEventNameCreateTab
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFLogout:)
                                                 name:CEFEventNameLogout
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFSave:)
                                                 name:CEFEventNameSave
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFOpenUrl:)
                                                 name:CEFEventNameOpenUrl
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFFullscreen:)
                                                 name:CEFEventNameFullscreen
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFKeyDown:)
                                                 name:CEFEventNameKeyboardDown
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCEFDownload:)
                                                 name:CEFEventNameDownload
                                               object:nil];
    
    
//    // DEBUG
//    for (int i = 0; i < 5; i++) {
//        NSEditorApi::CAscDownloadFileInfo * pDownloadFileInfo = new NSEditorApi::CAscDownloadFileInfo();
//        pDownloadFileInfo->put_Id(1000 + i);
//        pDownloadFileInfo->put_FilePath(L"/Users/ayuzhin/Library/Developer/Xcode/DerivedData/ONLYOFFICE/Contents/Resources/cloud.png");
//        pDownloadFileInfo->put_Url(L"http://onlyoffice.com");
//        pDownloadFileInfo->put_Percent(0);
//        
//        [[ASCDownloadController sharedInstance] addDownload:[NSString stringWithFormat:@"%d", 1000+i] view:nil fileName:@"cloud.png"];
//        [[ASCDownloadController sharedInstance] updateDownload:[NSString stringWithFormat:@"%d", 1000+i] data:[NSValue value:&pDownloadFileInfo withObjCType:@encode(void *)]];
//        
//        delete pDownloadFileInfo;
//    }
//    
//    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^{
//        for (int i = 0; i < [[[ASCDownloadController sharedInstance] downloads] count]; i++) {
//            NSEditorApi::CAscDownloadFileInfo * pDownloadFileInfo = new NSEditorApi::CAscDownloadFileInfo();
//            pDownloadFileInfo->put_FilePath(L"/Users/ayuzhin/Library/Developer/Xcode/DerivedData/ONLYOFFICE/Contents/Resources/cloud.png");
//            pDownloadFileInfo->put_Percent(rand()%100);
//            
//            [[ASCDownloadController sharedInstance] updateDownload:[NSString stringWithFormat:@"%d", 1000+i] data:[NSValue value:&pDownloadFileInfo withObjCType:@encode(void *)]];
//            
//            delete pDownloadFileInfo;
//
//        }
//    }];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}


- (void)onWindowLoaded:(NSNotification *)notification {
    if (notification && notification.object) {
        ASCTitleWindowController *windowController = (ASCTitleWindowController *)notification.object;
        windowController.titlebarController.delegate = self;
        
        self.tabsControl = windowController.titlebarController.tabsControl;
        
        [self setupTabControl];
        [self createStartPage];
        [self loadStartPage];
        
        // Create CEF event listener
        [ASCEventsController sharedInstance];
    }
}

- (void)setupTabControl {
    self.tabsControl.minTabWidth = 48;
    self.tabsControl.maxTabWidth = 135;
    
    [self.tabsControl.multicastDelegate addDelegate:self];
}

- (void)createStartPage {
    NSInteger rootTabIndex = [self.tabView indexOfTabViewItemWithIdentifier:rootTabId];
    
    if (rootTabIndex != NSNotFound) {
        NSTabViewItem * tab = [self.tabView tabViewItemAtIndex:rootTabIndex];
        
        CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
        
        self.cefStartPageView = [[NSCefView alloc] initWithFrame:tab.view.frame];
        [self.cefStartPageView Create:appManager withType:cvwtSimple];
        [tab.view addSubview:self.cefStartPageView];
        [self.cefStartPageView setupFillConstraints];
    }
}

- (void)loadStartPage {
    if (self.cefStartPageView ) {
        NSUserDefaults *preferences     = [NSUserDefaults standardUserDefaults];
        NSURLComponents *loginPage      = [NSURLComponents componentsWithString:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"login"]];
        NSURLQueryItem *countryCode     = [NSURLQueryItem queryItemWithName:@"lang" value:[[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] lowercaseString]];
        NSURLQueryItem *portalAddress   = [NSURLQueryItem queryItemWithName:@"portal" value:[preferences objectForKey:ASCUserSettingsNamePortalUrl]];
        loginPage.queryItems            = @[countryCode, portalAddress];
        loginPage.scheme                = NSURLFileScheme;
        
        [self.cefStartPageView Load:[loginPage string]];
    }
}

#pragma mark -
#pragma mark - CEF events handlers

- (void)onCEFCreateTab:(NSNotification *)notification {
    if (notification && notification.userInfo) {
        NSDictionary * params = (NSDictionary *)notification.userInfo;
        
        ASCTabView *tab = [[ASCTabView alloc] initWithFrame:CGRectZero];
        tab.title       = NSLocalizedString(@"Document", nil);
        tab.type        = ASCTabViewOpeningType;
        tab.url         = params[@"url"];

        [self.tabsControl addTab:tab selected:[params[@"active"] boolValue]];
    }
}

- (void)onCEFLogout:(NSNotification *)notification {
    [[ASCHelper localSettings] removeObjectForKey:ASCUserSettingsNameUserInfo];
    [self.tabsControl removeAllTabs];
    [self.tabView selectTabViewItemWithIdentifier:rootTabId];
    [self loadStartPage];
}

- (void)onCEFSave:(NSNotification *)notification {
    if (notification && notification.userInfo) {
        NSDictionary * params = (NSDictionary *)notification.userInfo;
        NSString * viewId = params[@"viewId"];
        
        ASCTabView * tab = [self.tabsControl tabWithUUID:viewId];
        
        if (tab) {
            [self.tabsControl removeTab:tab];
        }
    }
}

- (void)onCEFOpenUrl:(NSNotification *)notification {
    if (notification && notification.userInfo) {
        NSDictionary * params = (NSDictionary *)notification.userInfo;
        NSString * linkUrl = params[@"url"];
        
        if (linkUrl && linkUrl.length > 0) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:linkUrl]];
        }
    }
}

- (void)onCEFFullscreen:(NSNotification *)notification {
    if (notification && notification.userInfo) {
        NSDictionary * params = (NSDictionary *)notification.userInfo;
        
        BOOL isFullscreen = [params[@"fullscreen"] boolValue];
        NSTabViewItem * item = [self.tabView selectedTabViewItem];
        
        if (isFullscreen) {
            [item.view enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
        } else {
            [item.view exitFullScreenModeWithOptions:nil];
        }
    }
}

- (void)onCEFKeyDown:(NSNotification *)notification {
    if (notification && notification.userInfo) {
        NSDictionary * params = (NSDictionary *)notification.userInfo;
        
        NSValue * eventData = params[@"data"];
        
        if (eventData) {
            NSEditorApi::CAscKeyboardDown * pData = (NSEditorApi::CAscKeyboardDown *)[eventData pointerValue];
            
//            int     keyCode = pData->get_KeyCode();
//            bool    isCtrl  = pData->get_IsCtrl();
            
            RELEASEINTERFACE(pData);
            
//            NSF30FunctionKey
//            NSKeyUp
//            int code = NSCommandKeyMask;
//            
//            switch (keyCode) {
//                case NSF4FunctionKey:
//                    if (isCtrl) {
//                        m_pTabs->closeEditorByIndex(m_pTabs->currentIndex());
//                    }
//                    break;
//            }
        }
    }
}

- (void)onCEFDownload:(NSNotification *)notification {
    if (notification && notification.userInfo) {
        NSDictionary * params = (NSDictionary *)notification.userInfo;
        CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
        NSValue * eventData = params[@"data"];
        BOOL isStart        = [params[@"start"] boolValue];
        
        if (nil == appManager || nil == eventData)
            return;
        
        NSEditorApi::CAscDownloadFileInfo * pDownloadFileInfo = (NSEditorApi::CAscDownloadFileInfo *)[eventData pointerValue];
        
        NSString * idx = [NSString stringWithFormat:@"%d", pDownloadFileInfo->get_Id()];
        
        if (pDownloadFileInfo->get_IsComplete()) {
            [[ASCDownloadController sharedInstance] removeDownload:idx];
        } else if (pDownloadFileInfo->get_IsCanceled()) {
            [[ASCDownloadController sharedInstance] removeDownload:idx];
        } else {
            id download = [[ASCDownloadController sharedInstance] downloadWithId:idx];
            
            if (nil == download) {
                NSString * path = [NSString stringWithstdwstring:pDownloadFileInfo->get_FilePath()];
                NSString * fileName = NSLocalizedString(@"Unconfirmed", nil);
                
                if (path && [path length] > 0) {
                    fileName = [path lastPathComponent];
                }
                
                NSCefView * pView = nil;
                
                if (isStart) {
                    pView = [[NSCefView alloc] initWithFrame:CGRectZero];
                    [pView Create:appManager withType:cvwtEditor];
                    [pView setParentCef:pDownloadFileInfo->get_Id()];
                    [pView Load:[NSString stringWithstdwstring:pDownloadFileInfo->get_Url()]];
                    
                    idx = [NSString stringWithFormat:@"%ld", (long)[pView uuid]];
                }
                
                [[ASCDownloadController sharedInstance] addDownload:idx view:pView fileName:fileName];
            }
            
            [[ASCDownloadController sharedInstance] updateDownload:idx data:eventData];
        }
    }
}

#pragma mark -
#pragma mark - ASCTabsControl Delegate

- (void)tabs:(ASCTabsControl *)control didSelectTab:(ASCTabView *)tab {
    if (tab) {
        [self.tabView selectTabViewItemWithIdentifier:tab.uuid];
    }
}

- (void)tabs:(ASCTabsControl *)control didAddTab:(ASCTabView *)tab {
    CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
    NSCefView * cefView = [[NSCefView alloc] initWithFrame:CGRectZero];
    [cefView Create:appManager withType:cvwtEditor];
    [cefView Load:tab.url];
    
    tab.uuid = [NSString stringWithFormat:@"%ld", (long)cefView.uuid];
    
    NSTabViewItem * item = [[NSTabViewItem alloc] initWithIdentifier:tab.uuid];
    item.label = tab.title;
    [self.tabView addTabViewItem:item];
    [item.view addSubview:cefView];
    [cefView setupFillConstraints];
}

- (BOOL)tabs:(ASCTabsControl *)control willRemovedTab:(ASCTabView *)tab {
    if (tab.changed) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to save the changes made to the document \"%@\"?", nil), tab.title]];
        [alert setInformativeText:NSLocalizedString(@"Your changes will be lost if you don’t save them.", nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn) {
                NSTabViewItem * item = [self.tabView tabViewItemAtIndex:[self.tabView indexOfTabViewItemWithIdentifier:tab.uuid]];
                NSCefView * cefView = nil;
                
                if (item) {
                    for (NSView * view in item.view.subviews) {
                        if ([view isKindOfClass:[NSCefView class]]) {
                            cefView = (NSCefView *)view;
                            break;
                        }
                    }
                }
                
                if (cefView) {
                    NSEditorApi::CAscMenuEvent* pEvent = new NSEditorApi::CAscMenuEvent();
                    
                    pEvent->m_nType = ASC_MENU_EVENT_TYPE_CEF_SAVE;
                    [cefView apply:pEvent];
                }
            } else if (returnCode == NSAlertSecondButtonReturn) {
                [control removeTab:tab];
            }
        }];
        
        return NO;
    }

    return YES;
}

- (void)tabs:(ASCTabsControl *)control didRemovedTab:(ASCTabView *)tab {
    CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
    appManager->DestroyCefView([tab.uuid intValue]);
    
    [self.tabView removeTabViewItem:[self.tabView tabViewItemAtIndex:[self.tabView indexOfTabViewItemWithIdentifier:tab.uuid]]];
}

- (void)tabs:(ASCTabsControl *)control didReorderTab:(ASCTabView *)tab {
    //
}

#pragma mark -
#pragma mark - ASCTitleBarController Delegate

- (void)onOnlyofficeButton:(id)sender {
    [self.tabView selectTabViewItemWithIdentifier:rootTabId];
    [self.tabsControl selectTab:nil];
}

- (void)onShowUserInfoController:(NSViewController *)controller {
    ASCUserInfoViewController *userInfoController = (ASCUserInfoViewController *)controller;
    userInfoController.delegate = self;
}

#pragma mark -
#pragma mark - ASCUserInfoViewController Delegate

- (void)onLogoutButton:(ASCUserInfoViewController *)controller {
    CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
    NSDictionary * userInfo = [[ASCHelper localSettings] valueForKey:ASCUserSettingsNameUserInfo];
    
    if (userInfo) {
        NSString * portal = userInfo[@"portal"];
        
        if (portal) {
            appManager->Logout([portal stdwstring]);
        }
    }
}

#pragma mark -
#pragma mark - Debug

//- (IBAction)onAddTab:(id)sender {
//    ASCTabView *tab = [[ASCTabView alloc] initWithFrame:CGRectZero];
//    tab.title = [NSString stringWithFormat:@"Tab %lu", (unsigned long)rand() % 10000];
//    [self.tabsControl addTab:tab];
//}
//
//- (IBAction)onRemoveTab:(id)sender {
//    [self.tabsControl removeTab:[[self.tabsControl tabs] firstObject]];
//}
@end