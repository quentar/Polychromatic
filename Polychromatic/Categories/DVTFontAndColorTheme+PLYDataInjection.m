//
//  DVTFontAndColorTheme+PLYDataInjection.m
//  Polychromatic
//
//  Created by Kolin Krewinkel on 4/4/14.
//  Copyright (c) 2014 Kolin Krewinkel. All rights reserved.
//

#import "DVTFontAndColorTheme+PLYDataInjection.h"
#import "PLYSwizzling.h"

static IMP originalDataRepImp;
static IMP originalDataLoadImp;

static char *PLYPolychromaticSupportedKey = "ply_polychromaticSupported";
static char *PLYPolychromaticEnabledKey = "ply_polychromaticEnabled";
static char *PLYSaturationKey = "ply_saturation";
static char *PLYBrightnessKey = "ply_brightness";

@implementation DVTFontAndColorTheme (PLYDataInjection)

#pragma mark - Swizzling

+ (void)load
{
    originalDataRepImp = PLYSwizzleMethod(self, @selector(dataRepresentationWithError:), self, @selector(ply_dataRepresentationWithError:), YES);
    originalDataLoadImp = PLYSwizzleMethod(self, @selector(_loadFontsAndColors), self, @selector(ply_loadFontsAndColors), YES);
}

#pragma mark - Polychromatic Data Injection

- (BOOL)ply_loadFontsAndColors
{
    BOOL result = (BOOL)originalDataLoadImp(self, @selector(_loadFontsAndColors));

    // Unfortunately, this has to be loaded twice.
    NSData *data = nil;

    if (self.isBuiltIn)
    {
        data = [NSData dataWithContentsOfFile:[[self valueForKey:@"_dataURL"] absoluteString]];
    }
    else
    {
        data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Developer/Xcode/UserData/FontAndColorThemes/%@", NSHomeDirectory(), self.name]];
    }

    if (data)
    {
        NSPropertyListFormat format = 0;
        NSError *error = nil;
        NSMutableDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];

        [self ply_setPolychromaticEnabled:[dict[@"PLYEnabled"] boolValue]];
        [self ply_setBrightness:[dict[@"PLYVarBrightness"] floatValue]];
        [self ply_setSaturation:[dict[@"PLYVarSaturation"] floatValue]];
    }

    return result;
}

- (id)ply_dataRepresentationWithError:(NSError **)arg1
{
    NSData *data = originalDataRepImp(self, @selector(dataRepresentationWithError:), arg1);

    if (data)
    {
        NSPropertyListFormat format = 0;
        NSString *error = nil;

        NSMutableDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:arg1];

        BOOL enabled = [self ply_polychromaticEnabled];
        CGFloat saturation = [self ply_saturation];
        CGFloat brightness = [self ply_brightness];

        if (saturation == 0.f)
        {
            saturation = 0.5f;
        }

        if (brightness == 0.f)
        {
            brightness = 0.5f;
        }

        dict[@"PLYEnabled"] = @(enabled);
        dict[@"PLYVarSaturation"] = @(saturation);
        dict[@"PLYVarBrightness"] = @(brightness);
        dict[@"PLYSupported"] = @([self ply_polychromaticSupported]);

        data = [NSPropertyListSerialization dataFromPropertyList:dict format:format errorDescription:&error];
    }

    return data;
}

#pragma mark - Getters

- (BOOL)ply_polychromaticSupported
{
    return [objc_getAssociatedObject(self, PLYPolychromaticSupportedKey) boolValue];
}

- (BOOL)ply_polychromaticEnabled
{
    return [objc_getAssociatedObject(self, PLYPolychromaticEnabledKey) boolValue];
}

- (CGFloat)ply_saturation
{
    return [objc_getAssociatedObject(self, PLYSaturationKey) floatValue];
}

- (CGFloat)ply_brightness
{
    return [objc_getAssociatedObject(self, PLYBrightnessKey) floatValue];
}

#pragma mark - Setters

- (void)ply_setPolychromaticSupported:(BOOL)supported
{
    objc_setAssociatedObject(self, PLYPolychromaticSupportedKey, @(supported), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ply_setPolychromaticEnabled:(BOOL)enabled;
{
    objc_setAssociatedObject(self, PLYPolychromaticEnabledKey, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ply_setSaturation:(CGFloat)saturation
{
    objc_setAssociatedObject(self, PLYSaturationKey, @(saturation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ply_setBrightness:(CGFloat)brightness
{
    objc_setAssociatedObject(self, PLYBrightnessKey, @(brightness), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
