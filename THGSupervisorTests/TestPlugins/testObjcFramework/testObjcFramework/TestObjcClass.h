//
//  TestObjcClass.h
//  testObjcFramework
//
//  Created by Brandon Sneed on 6/21/15.
//  Copyright (c) 2015 StereoLab. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <THGSupervisor/THGSupervisor-Swift.h>
@import THGSupervisor;

@interface TestObjcClass : NSObject<Pluggable>

@property(nonatomic, copy, readonly) NSString * _Nonnull identifier;
@property(nonatomic, copy, readonly) NSArray<NSBundle *> * _Nullable dependencies;

- (Route * _Nullable)startup:(Supervisor * _Nonnull)supervisor;

@end