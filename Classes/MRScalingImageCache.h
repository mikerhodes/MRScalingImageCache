//
//  MRScalingImageCache.h
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
