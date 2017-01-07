//
//  NMNotificationManager.h
//  Marke Jave
//
//  Created by Marke Jave on 15/10/15.
//  Copyright © 2015年 Marike Jave. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NMNotificationManagerDidReceiveNotification;

@protocol NMNotificationAps <NSObject>

@property(nonatomic, copy  ) NSString *alert;
@property(nonatomic, copy  ) NSString *badge;
@property(nonatomic, copy  ) NSString *sound;

@property(nonatomic, assign) BOOL contentAvailable;

@end

@protocol NMNotificationCustomContent <NSObject>

@property(nonatomic, assign) NSInteger notificationContentType;
@property(nonatomic, strong) id object;

@end

@protocol NMNotification <NSObject>

@property(nonatomic, strong) id<NMNotificationAps> aps;
@property(nonatomic, strong) id<NMNotificationCustomContent> customContent;

- (id)initWithNotificationAps:(id<NMNotificationAps>)notificationAps customContent:(id<NMNotificationCustomContent>)customContent;

+ (id)notificationWithNotificationAps:(id<NMNotificationAps>)notificationAps customContent:(id<NMNotificationCustomContent>)customContent;
@end

@interface NMDefaultNotification : NSObject<NMNotification>

@end

@class NMNotificationManager;

@protocol NMNotificationHandleDelegate <NSObject>

@optional

- (BOOL)notificationManager:(NMNotificationManager *)notificationManager handleNoitification:(id<NMNotificationCustomContent>)notificationContent;

@end

@interface NMNotificationHandle : NSObject

@property(nonatomic, assign, readonly) NSInteger type;

@property(nonatomic, assign, readonly) BOOL always;

@property(nonatomic, copy  , readonly) void (^notificationHandle)(NMNotificationManager *notificationManager, id<NMNotificationCustomContent>notificationContent);

@property(nonatomic, assign, readonly) id<NMNotificationHandleDelegate> delgate;

@end

@interface NMNotificationManager : NSObject

@property(nonatomic, strong, readonly) NSArray<NMNotificationCustomContent> *notificationContents;
@property(nonatomic, strong, readonly) NSArray<NMNotificationHandle *> *notificationHandles;

@property(nonatomic, strong) NSArray<NSNumber *> *allowInactiveNotificationTypes;

+ (id)shareManager;

+ (void)handleNotification:(id<NMNotification>)notification backgroundFetch:(BOOL)backgroundFetch;

+ (NMNotificationHandle *)registerNotificationHandle:(void(^)(NMNotificationManager *notificationManager, id<NMNotificationCustomContent> notificationContent))notificationHandle
                                                type:(NSInteger)type
                                      relationObject:(id)relationObject;

+ (NMNotificationHandle *)registerNotificationHandle:(void(^)(NMNotificationManager *notificationManager, id<NMNotificationCustomContent> notificationContent))notificationHandle
                                                type:(NSInteger)type
                                              always:(BOOL)always
                                      relationObject:(id)relationObject;

+ (NMNotificationHandle *)registerNotificationHandleDelegate:(id<NMNotificationHandleDelegate>)delegate
                                                        type:(NSInteger)type
                                              relationObject:(id)relationObject;

+ (NMNotificationHandle *)registerNotificationHandleDelegate:(id<NMNotificationHandleDelegate>)delegate
                                                        type:(NSInteger)type
                                                      always:(BOOL)always
                                              relationObject:(id)relationObject;

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate type:(NSInteger)type;

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate always:(BOOL)always;

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate type:(NSInteger)type always:(BOOL)always;

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate;

+ (void)removeNotificationHandlesWithType:(NSInteger)type;

+ (void)removeNotificationContentsWithType:(NSInteger)type;

@end

