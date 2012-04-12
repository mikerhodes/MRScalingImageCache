//
//  MRScalingImageCache.h
//
//  Created by Michael Rhodes on 10/03/2012.
//  Copyright (c) 2012 Michael Rhodes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScaleInfo : NSObject

@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic) CGInterpolationQuality quality;
@property (nonatomic) UIViewContentMode mode;

@end

@interface MRScalingImageCache : NSObject

@property (readonly,strong) NSMutableDictionary *scales;

@property (nonatomic, strong, readonly) NSString *storePath;

-(id)initWithStorePath:(NSString *)storePath;

-(void)addScale:(ScaleInfo *)scaleInfo forName:(NSString *)name;

-(UIImage *)imageForURL:(NSString *)url;
-(UIImage *)imageFromCacheForURL:(NSString *)url;
-(void)downloadImageToCacheForURL:(NSString *)url;
-(void)cleanUpWithKeepList:(NSSet *)keep_urls;

-(UIImage *)imageForURL:(NSString *)url
                  scale:(NSString *)name;

-(UIImage *)imageFromCacheForURL:(NSString *)url
                           scale:(NSString *)name;

@end
