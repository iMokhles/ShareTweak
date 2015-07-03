#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import "UIAlertView+Blocks.h"

static inline NSString *UCLocalizeEx(NSString *key, NSString *value = nil) {
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}

#define UCLocalize(key) UCLocalizeEx(@ key)

@interface Source : NSObject
- (NSString *) name;
- (NSString *) shortDescription;
- (NSString *) label;
@end

@interface MIMEAddress : NSObject
- (NSString *) name; // name 
- (NSString *) address; // email address
@end

@interface Package : NSObject {
	Source *source_;
	// pkgCache::VerIterator version_;
}

// - (pkgCache::PkgIterator) iterator;
- (void) parse;

- (NSString *) section;
- (NSString *) simpleSection;

- (NSString *) longSection;
- (NSString *) shortSection;

- (NSString *) uri;

- (MIMEAddress *) maintainer;
- (size_t) size;
- (NSString *) longDescription;
- (NSString *) shortDescription;
- (BOOL) uninstalled;
- (BOOL) upgradableAndEssential:(BOOL)essential;
- (NSString *) mode;
- (NSString *) id;
- (NSString *) name;
- (UIImage *) icon;
- (NSString *) homepage;
- (NSString *) depiction;
- (MIMEAddress *) author;
- (bool) isCommercial;
@end

@interface CyteViewController : UIViewController
@end

@interface CyteWebViewController : CyteViewController
@end

@interface CydiaWebViewController : CyteWebViewController
@end

@interface CYPackageController : CydiaWebViewController {
	 Package *package_;
	 NSString *name_;
	 bool commercial_;
	 UIBarButtonItem *button_;
}
- (void) _customButtonClicked;
- (void)shareTweakInfo:(NSArray *)inforArray;
- (void)newCustomAction;
@end

%hook CYPackageController

// got it from CyteWebViewController class
- (UIBarButtonItem *) customButton {
	Package *package = MSHookIvar<Package *>(self, "package_");
	BOOL commercial = [package isCommercial];

	if (commercial && [package uninstalled]) 
		return %orig;
		
	UIBarButtonItem *origRightButton; // = MSHookIvar<UIBarButtonItem *>(self, "button_");
	origRightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(customButtonClicked)];
	return origRightButton;
}

// got it from CyteWebViewController class
- (void)customButtonClicked {


	Package *package = MSHookIvar<Package *>(self, "package_");
	Source *source = MSHookIvar<Source *>(package, "source_");
	BOOL commercial = MSHookIvar<BOOL>(self, "commercial_");

	commercial = [package isCommercial];

	if (commercial && [package uninstalled]) 
		return %orig;

	// got it from CYPackageController implementation
	NSString *origButtonTitle;
	if (package != nil) {
		if ([package mode] != nil)
			origButtonTitle = UCLocalize("CLEAR");
		if (source == nil);
		else if ([package upgradableAndEssential:NO])
            origButtonTitle = UCLocalize("UPGRADE");
        else if ([package uninstalled])
            origButtonTitle = UCLocalize("INSTALL");
        else
            origButtonTitle = UCLocalize("REINSTALL");
        if (![package uninstalled])
            origButtonTitle = UCLocalize("REMOVE");
	}

	// Share info
	__block NSString *shareText = [NSString stringWithFormat:@"#Share_Tweak Tweak Name: %@\nShort Description: %@\nAuthor: %@\n Source: %@\n Type: %s", package.name, package.shortDescription, package.author.name, source.name, commercial ? "Paid" : "Free"];
	NSURL *depictionURL = [NSURL URLWithString:@""];
	if (package.depiction != nil)
		depictionURL = [NSURL URLWithString:package.depiction];

	[UIAlertView showWithTitle:@"ShareTweak"
                   message:[NSString stringWithFormat:@"Share %@ info with others", package.name]
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@[@"Share", @"Share URL", origButtonTitle]
                  tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                      if (buttonIndex == [alertView cancelButtonIndex]) {
                          NSLog(@"Cancelled");
                      } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share"]) {
                          [self shareTweakInfo:[NSArray arrayWithObjects:shareText, depictionURL, package.icon, nil]];
                      } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share URL"]) {
                          [self shareTweakInfo:[NSArray arrayWithObjects:depictionURL, nil]];
                      } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:origButtonTitle]) {
                          [self _customButtonClicked];
                      }
                  }];
}
// needs to grab Tweak price
%new
- (void)shareTweakInfo:(NSArray *)inforArray {

	UIActivityViewController *actViewController = [[UIActivityViewController alloc] initWithActivityItems:inforArray  applicationActivities:nil];
	[self presentViewController:actViewController animated:YES completion:NULL];
}
%end
