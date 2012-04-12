//
//  MRScalingImageCache.m
//
//  Created by Michael Rhodes on 10/03/2012.
//
//  Copyright (c) 2012, Michael Rhodes
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//   * Redistributions of source code must retain the above copyright notice, 
//    this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright 
//    notice, this list of conditions and the following disclaimer in 
//    the documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
//  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#include <CommonCrypto/CommonDigest.h>

#import "MRScalingImageCache.h"

#import "UIImage+Resize.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"

@implementation ScaleInfo

@synthesize width;
@synthesize height;
@synthesize quality;
@synthesize mode;

@end

@interface MRScalingImageCache (Private)

-(UIImage *)_processImage:(UIImage *)original
                    width:(float)width
                   height:(float)height
                  quality:(CGInterpolationQuality)quality
                     mode:(UIViewContentMode)mode;

@end

@implementation MRScalingImageCache

@synthesize scales = _scales;

@synthesize storePath = _storePath;

-(id)initWithStorePath:(NSString *)path
{
    self = [super init];
    if (self != nil) {
        _storePath = [path copy];
    }
    return self;
}

-(NSMutableDictionary *)scales
{
    if (_scales == nil) {
        _scales = [[NSMutableDictionary alloc] init];
    }
    return _scales;
}

-(void)addScale:(ScaleInfo *)scaleInfo forName:(NSString *)name
{
    [self.scales setObject:scaleInfo forKey:name];
}

-(NSString*)sha1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

-(void)downloadImageToCacheForURL:(NSString *)url
{
    [self _downloadImageToCacheForURL:url];
}

-(NSString *)_downloadPathForURL:(NSString *)url
{
    NSString *storePath = self.storePath;    
    // Hash the URL to get our filename
    NSString *hashed_url = [self sha1:url];
    NSString *hashed_filename = [NSString stringWithFormat:@"%@.png", hashed_url];
    
    // Check for the filename in the cache
    NSString *cached_file_path = [storePath stringByAppendingPathComponent:hashed_filename];
    
    return cached_file_path;
}

-(NSString *)_downloadPathForURL:(NSString *)url forScale:(NSString *)name
{
    NSString *storePath = self.storePath;
    
    // Hash the URL to get our filename
    NSString *hashed_url = [self sha1:url];
    NSString *hashed_filename = [NSString stringWithFormat:@"%@_%@.png", hashed_url, name];
    
    // Check for the filename in the cache
    NSString *cached_file_path = [storePath stringByAppendingPathComponent:hashed_filename];
    
    return cached_file_path;
}


-(NSString *)_downloadImageToCacheForURL:(NSString *)url
{
    // Will download a file to the cache if not present
    // and return the path to the downloaded image.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *storePath = self.storePath;
    
    NSError *error;
    
    // Create the storage folder if it doesn't exist
    if (![fileManager fileExistsAtPath:storePath]) {
        [fileManager createDirectoryAtPath:storePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
    }
    
    NSString *cached_file_path = [self _downloadPathForURL:url];
    BOOL available = [fileManager fileExistsAtPath:cached_file_path];
    
    // If not in cache, download
    if (!available) {
        //NSLog(@"Image not in cache; downloading...");
        // Get an image from the URL below
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        [request setDownloadCache:[ASIDownloadCache sharedCache]];
        [request setCacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
        [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        [request setSecondsToCache:60 * 5]; // Cache for 5 minutes
        [request startSynchronous];
        
        NSData *responseData = [request responseData];
        
        UIImage *image = [[UIImage alloc] initWithData:responseData];
        
        //NSLog(@"%f,%f",image.size.width,image.size.height);
        NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
        [data1 writeToFile:cached_file_path atomically:YES];
    }
    else {
        //NSLog(@"Image found in cache");
    }
    
    return cached_file_path;
}

-(UIImage *)imageForURL:(NSString *)url
{
    NSString *cached_file_path = [self _downloadImageToCacheForURL:url];
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:cached_file_path]];
}

-(UIImage *)imageFromCacheForURL:(NSString *)url
{
    NSString *cached_file_path = [self _downloadPathForURL:url];
    
    return [self _imageFromCacheForPath:cached_file_path];
}

-(UIImage *)_imageFromCacheForPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL available = [fileManager fileExistsAtPath:path];
    
    if (available) {
        return [UIImage imageWithData:[NSData dataWithContentsOfFile:path]];
    } else {
        return nil;
    }
}


-(UIImage *)imageForURL:(NSString *)url
                  scale:(NSString *)name
{
    ScaleInfo *si = [self.scales objectForKey:name];
    
    if (si == nil) {
        NSString *reason = [NSString stringWithFormat:@"Could not find ScaleInfo for %@", name];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil]; 
    }
    
    NSString *scaledPath = [self _downloadPathForURL:url forScale:name];
    UIImage *cached_scaled = [self _imageFromCacheForPath:scaledPath];
    
    if (cached_scaled != nil) {
        //NSLog(@"Read scale %@ from %@", name, scaledPath);
        return cached_scaled;
    }
    
    UIImage *original = [self imageForURL:url];
    
    if (original == nil) return nil;
    
    UIImage *processed =  [self _processImage:original
                                        width:si.width
                                       height:si.height
                                      quality:si.quality 
                                         mode:si.mode];
    
    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(processed)];
    [data1 writeToFile:scaledPath atomically:YES];
    
    //NSLog(@"Wrote scale %@ to path %@", name, scaledPath);
    
    return processed;
}

-(UIImage *)imageFromCacheForURL:(NSString *)url
                           scale:(NSString *)name
{
    ScaleInfo *si = [self.scales objectForKey:name];
    
    if (si == nil) {
        NSString *reason = [NSString stringWithFormat:@"Could not find ScaleInfo for %@", name];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil]; 
    }
    
    NSString *scaledPath = [self _downloadPathForURL:url forScale:name];
    UIImage *cached_scaled = [self _imageFromCacheForPath:scaledPath];
    
    if (cached_scaled != nil) {
        //NSLog(@"Read scale %@ from %@", name, scaledPath);
        return cached_scaled;
    }
    
    UIImage *original = [self imageFromCacheForURL:url];
    
    if (original == nil) return nil;
    
    UIImage *processed =  [self _processImage:original
                                        width:si.width
                                       height:si.height
                                      quality:si.quality 
                                         mode:si.mode];
    
    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(processed)];
    [data1 writeToFile:scaledPath atomically:YES];
    
    //NSLog(@"Wrote scale %@ to path %@", name, scaledPath);
    
    return processed;
}

-(UIImage *)_processImage:(UIImage *)original
                    width:(float)width
                   height:(float)height
                  quality:(CGInterpolationQuality)quality
                     mode:(UIViewContentMode)mode
{
    float oh = original.size.height;
    float ow = original.size.width;
    
    height = height * [[UIScreen mainScreen] scale];
    width = width * [[UIScreen mainScreen] scale];
    
    float nh,nw;
    
    if (oh < ow) {
        float sf = height / oh;
        nh = height;
        nw = ow * sf;
    } else {
        float sf = height / ow;
        nh = oh * sf;
        nw = width;
    }
    
    //NSLog(@"%f, %f, %f, %f", nw,nh,crop_left,crop_top);
    
    CGSize size = CGSizeMake(nw, nh);
    UIImage *resized = [original resizedImage:size
                         interpolationQuality:quality];
    
    CGRect bounds = CGRectMake((nw - width) / 2, 
                               (nh - height) / 2, 
                               width, 
                               height);
    UIImage *cropped = [resized croppedImage:bounds];
    
    return cropped;
}

-(void)cleanUpWithKeepList:(NSSet *)keep_urls
{
    //NSLog(@"ThumbnailCache cleanup");
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *storePath = self.storePath;
    
    NSMutableSet *keep_hashes = [[NSMutableSet alloc] init];
    for (NSString *url in keep_urls) {
        [keep_hashes addObject:[self sha1:url]];
    }
    
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:storePath error:nil];
    NSMutableArray *to_delete = [NSMutableArray array];
    for (NSString *name in fileList){
        //NSLog(@"File:   %@", name);
        NSString *hash_prefix = [name substringToIndex:CC_SHA1_DIGEST_LENGTH*2];
        //NSLog(@"Prefix: %@", hash_prefix);
        
        if (![keep_hashes containsObject:hash_prefix]) {
            [to_delete addObject:name];
        }
    }
    
    for (NSString *name in to_delete) {
        NSLog(@"MRScalingImageCache clean up: deleting %@", name);
        [fileManager removeItemAtPath:[storePath stringByAppendingPathComponent:name] error:nil];
    }
}

@end
