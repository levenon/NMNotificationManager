//
//  NMNotificationManager.m
//  Marike Jave
//
//  Created by Marike Jave on 15/10/15.
//  Copyright © 2015年 Marike Jave. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <objc/runtime.h>

#import "NMNotificationManager.h"

NSString * const NMNotificationManagerDidReceiveNotification = @"NMNotificationManagerDidReceiveNotification";

@implementation NMNotification

- (id)initWithNotificationAps:(id<NMNotificationAps>)notificationAps customContent:(id<NMNotificationCustomContent>)customContent;{
    self = [super init];
    if (self) {
        self.aps = notificationAps;
        self.customContent = customContent;
    }
    return self;
}

+ (id)notificationWithNotificationAps:(id<NMNotificationAps>)notificationAps customContent:(id<NMNotificationCustomContent>)customContent;{
    return [[[self class] alloc] initWithNotificationAps:notificationAps customContent:customContent];
}

@end

@interface NMNotificationManager (Private)

- (void)_removeHandle:(NMNotificationHandle *)handle;

@end

@interface NMNotificationHandle (Private)

@property(nonatomic, assign) id relationObject;

- (void)_removeFromContainer;

@end

@interface NMNotificationRelationObjectSetter : NSObject

@property(nonatomic, strong) NSMutableSet<NMNotificationHandle *> *handles;

@end

@implementation NMNotificationRelationObjectSetter

- (void)_addHandle:(NMNotificationHandle *)handle{
    if (handle) {
        [[self handles] addObject:handle];
    }
}

- (void)_removeHandle:(NMNotificationHandle *)handle{
    [[self handles] removeObject:handle];
}

- (NSMutableSet<NMNotificationHandle *> *)handles{
    if (!_handles) {
        _handles = [NSMutableSet<NMNotificationHandle *> set];
    }
    return _handles;
}

- (void)dealloc{
    for (NMNotificationHandle *handle in [self handles]) {
        [handle setRelationObject:nil];
        [handle _removeFromContainer];
    }
    [[self handles] removeAllObjects];
    
    self.handles = nil;
}

@end

@implementation NSObject (NMNotificationRelationObjectSetter)

- (NMNotificationRelationObjectSetter *)notificationRelationObjectSetter;{
    NMNotificationRelationObjectSetter *setter = objc_getAssociatedObject(self, @selector(notificationRelationObjectSetter));
    if (!setter) {
        setter = [NMNotificationRelationObjectSetter new];
        objc_setAssociatedObject(self, @selector(notificationRelationObjectSetter), setter, OBJC_ASSOCIATION_RETAIN);
    }
    return setter;
}

@end

@interface NMNotificationHandle ()

@property(nonatomic, assign) NSInteger type;

@property(nonatomic, copy  ) void (^notificationHandle)(id<NMNotificationCustomContent> notificationContent);

@property(nonatomic, assign) id<NMNotificationHandleDelegate> delgate;

@property(nonatomic, assign) BOOL always;

@property(nonatomic, assign) NMNotificationManager *container;

@property(nonatomic, assign) id relationObject;

@end

@implementation NMNotificationHandle

- (id)initWithDelegate:(id<NMNotificationHandleDelegate>)delegate
                  type:(NSInteger)type
                always:(BOOL)always
             container:(NMNotificationManager *)container
        relationObject:(id)relationObject;{
    self = [super init];
    if (self) {
        self.type = type;
        self.delgate = delegate;
        self.always = always;
        self.container = container;
        self.relationObject = relationObject;
    }
    return self;
}

- (id)initWithHandleBlock:(void(^)(id<NMNotificationCustomContent> notificationContent))notificationHandle
                     type:(NSInteger)type
                   always:(BOOL)always
                container:(NMNotificationManager *)container
           relationObject:(id)relationObject;{
    self = [super init];
    if (self) {
        self.type = type;
        self.notificationHandle = notificationHandle;
        self.always = always;
        self.container = container;
        self.relationObject = relationObject;
    }
    return self;
}

- (void)setRelationObject:(id)relationObject{
    _relationObject = relationObject;
    if (relationObject) {
        [[relationObject notificationRelationObjectSetter] _addHandle:self];
    }
}

- (BOOL)_performAction:(id<NMNotificationCustomContent>)notificationContent{
    if ([self delgate] && [[self delgate] respondsToSelector:@selector(epDidHandleNoitification:)]) {
        [[self delgate] epDidHandleNoitification:notificationContent];
        return YES;
    } else if ([self notificationHandle]){
        self.notificationHandle(notificationContent);
        return YES;
    }
    return NO;
}

- (void)_removeFromContainer{
    if ([self container]) {
        [[self container] _removeHandle:self];
        self.container = nil;
    }
    if ([self relationObject]) {
        [[[self relationObject] notificationRelationObjectSetter] _removeHandle:self];
    }
}

- (void)dealloc{
    self.notificationHandle = nil;
    self.delgate = nil;
}

@end

@interface NMNotificationManager ()

@property(nonatomic, strong) NSMutableArray<NMNotificationCustomContent> *mutableNotificationContents;

@property(nonatomic, strong) NSMutableArray<NMNotificationHandle *> *mutableNotificationHandles;

@end

@implementation NMNotificationManager

#pragma mark - initial

+ (id)shareManager;{
    static NMNotificationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}

#pragma mark - accessory

- (NSArray *)notificationContents{
    return [[self mutableNotificationContents] copy];
}

- (NSMutableArray *)mutableNotificationContents{
    if (!_mutableNotificationContents) {
        _mutableNotificationContents = [NSMutableArray<NMNotificationCustomContent> array];
    }
    return _mutableNotificationContents;
}

- (NSArray *)notificationHandles{
    return [[self mutableNotificationHandles] copy];
}

- (NSMutableArray *)mutableNotificationHandles{
    if (!_mutableNotificationHandles) {
        _mutableNotificationHandles = [NSMutableArray array];
    }
    return _mutableNotificationHandles;
}

- (NSArray *)allowInactiveNotificationTypes{
    if (!_allowInactiveNotificationTypes) {
        _allowInactiveNotificationTypes = @[];
    }
    return _allowInactiveNotificationTypes;
}

- (NMNotificationHandle *)_findHandleByType:(NSInteger)type{
    for (NMNotificationHandle *handle in [self mutableNotificationHandles]) {
        if ([handle type] & type) {
            return handle;
        }
    }
    return nil;
}

- (NSArray *)_findHandlesByType:(NSInteger)type{
    NSMutableArray *handles = [NSMutableArray array];
    for (NMNotificationHandle *handle in [self mutableNotificationHandles]) {
        if ([handle type] & type) {
            [handles addObject:handle];
        }
    }
    return handles;
}

- (NSArray *)_notificationContentsByType:(NSInteger)type;{
    NSMutableArray *notificationContents = [NSMutableArray array];
    for (id<NMNotificationCustomContent> notificationContent in [self mutableNotificationContents]) {
        if ([notificationContent notificationContentType] & type) {
            [notificationContents addObject:notificationContent];
        }
    }
    return notificationContents;
}

- (BOOL)_handleExsitsDelegate:(id<NMNotificationHandleDelegate>)delegate
                         type:(NSInteger)type;{
    for (NMNotificationHandle *handle in [self mutableNotificationHandles]) {
        if ([handle delgate] == delegate && ([handle type] & type)) {
            return YES;
        }
    }
    return NO;
}

- (NMNotificationHandle *)_handleWithDelegate:(id<NMNotificationHandleDelegate>)delegate
                                         type:(NSInteger)type;{
    for (NMNotificationHandle *handle in [self mutableNotificationHandles]) {
        if ([handle delgate] == delegate && ([handle type] & type)) {
            return handle;
        }
    }
    return nil;
}

- (NMNotificationHandle *)_handleWithDelegate:(id<NMNotificationHandleDelegate>)delegate{
    for (NMNotificationHandle *handle in [self mutableNotificationHandles]) {
        if ([handle delgate] == delegate) {
            return handle;
        }
    }
    return nil;
}

- (void)_handleExsitNotificationWithHandle:(NMNotificationHandle *)handle{
    NSMutableArray *handledNotificationContents = [NSMutableArray array];
    for (id<NMNotificationCustomContent> notificationContent in [self notificationContents]) {
        if ([notificationContent notificationContentType] & [handle type]) {
            [handle _performAction:notificationContent];
            if ([handle always]) {
                [handledNotificationContents addObject:notificationContent];
            }
        }
    }
    [[self mutableNotificationContents] removeObjectsInArray:handledNotificationContents];
}

- (BOOL)_shouldHandleNotification:(id<NMNotificationCustomContent>)notificationContent{
    return ([[self allowInactiveNotificationTypes] containsObject:@([notificationContent notificationContentType])] &&
            [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) ||
    [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
}

- (void)_handleNotification:(NMNotification *)notification backgroundFetch:(BOOL)backgroundFetch;{
    NSLog(@"LOG: Receive remote notificatons : %@", notification);
    id<NMNotificationCustomContent> customContent = [notification customContent];
    if (customContent && [customContent notificationContentType]) {
        if ([self _shouldHandleNotification:customContent]) {
            NSArray *handles = [self _findHandlesByType:[customContent notificationContentType]];
            NSMutableArray *onceHandles = [NSMutableArray array];
            NSInteger hasPerformCount = 0;
            for (NMNotificationHandle *handle in handles) {
                BOOL hasPerform = [handle _performAction:customContent];
                if (hasPerform){
                    if(![handle always]) {
                        NSInteger type = [handle type] & ~[customContent notificationContentType];
                        if (!type) {
                            [onceHandles addObject:handle];
                        } else {
                            [handle setType:type];
                        }
                    }
                    hasPerformCount++;
                }
            }
            if (!hasPerformCount) {
                [[self mutableNotificationContents] addObject:customContent];
                if ([customContent object]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:NMNotificationManagerDidReceiveNotification object:[customContent object]];
                }
            } else {
                [self _removeHandles:onceHandles];
            }
        }
    } else if ([customContent notificationContentType]){
        
    }
}

- (NMNotificationHandle *)registerNotificationHandle:(void(^)(id<NMNotificationCustomContent> notificationContent))notificationHandle
                                                type:(NSInteger)type
                                              always:(BOOL)always
                                      relationObject:(id)relationObject;{
    NMNotificationHandle *handle = [[NMNotificationHandle alloc] initWithHandleBlock:notificationHandle
                                                                                type:type
                                                                              always:always
                                                                           container:self
                                                                      relationObject:relationObject];
    [[self mutableNotificationHandles] addObject:handle];
    [self _handleExsitNotificationWithHandle:handle];
    return handle;
}

- (NMNotificationHandle *)registerNotificationHandleDelegate:(id<NMNotificationHandleDelegate>)delegate
                                                        type:(NSInteger)type
                                                      always:(BOOL)always
                                              relationObject:(id)relationObject;{
    NMNotificationHandle *handle = [self _handleWithDelegate:delegate];
    if (!handle) {
        NMNotificationHandle *handle = [[NMNotificationHandle alloc] initWithDelegate:delegate
                                                                                 type:type
                                                                               always:always
                                                                            container:self
                                                                       relationObject:relationObject];
        [[self mutableNotificationHandles] addObject:handle];
        return handle;
    } else if (handle && [handle type] & ~type){
        handle.type |= type;
    } else{
        NSLog(@"WARN: handle Delegate : %@, type:%ld", delegate, (long)type);
    }
    return handle;
}

- (void)_removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate
                                      type:(NSInteger)type;{
    NSMutableArray *willRemoveHandles = [NSMutableArray array];
    NSMutableArray *mutableNotificationHandles = [self mutableNotificationHandles];
    for (NMNotificationHandle *handle in mutableNotificationHandles) {
        if ([handle delgate] == delegate && ([handle type] & type) && ![handle always]) {
            [handle setType:[handle type] & ~type];
            if (![handle type]) {
                [willRemoveHandles addObject:handle];
            }
        }
    }
    [self _removeHandles:willRemoveHandles];
}

- (void)_removeNotificationHandlesWithType:(NSInteger)type;{
    NSMutableArray *willRemoveHandles = [NSMutableArray array];
    NSMutableArray *mutableNotificationHandles = [self mutableNotificationHandles];
    for (NMNotificationHandle  *handle in mutableNotificationHandles) {
        if (([handle type] & type) && ![handle always]) {
            [handle setType:[handle type] & ~type];
            if (![handle type]) {
                [willRemoveHandles addObject:handle];
            }
        }
    };
    [self _removeHandles:willRemoveHandles];
}

- (void)_removeNotificationContentsWithType:(NSInteger)type;{
    NSArray *notificationContents = [self _notificationContentsByType:type];
    [[self mutableNotificationContents] removeObjectsInArray:notificationContents];
}

- (void)_removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate{
    NSMutableArray *willRemoveHandles = [NSMutableArray array];
    NSMutableArray *mutableNotificationHandles = [self mutableNotificationHandles];
    for (NMNotificationHandle *handle in mutableNotificationHandles) {
        if ([handle delgate] == delegate && ![handle always]) {
            [willRemoveHandles addObject:handle];
        }
    }
    [self _removeHandles:willRemoveHandles];
}

- (void)_removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate
                                      type:(NSInteger)type
                                    always:(BOOL)always;{
    NSMutableArray *willRemoveHandles = [NSMutableArray array];
    NSMutableArray *mutableNotificationHandles = [self mutableNotificationHandles];
    for (NMNotificationHandle *handle in mutableNotificationHandles) {
        if ([handle delgate] == delegate && ([handle type] & type) && (always || ![handle always])) {
            [handle setType:[handle type] & ~type];
            if (![handle type]) {
                [willRemoveHandles addObject:handle];
            }
        }
    }
    [self _removeHandles:willRemoveHandles];
}

- (void)_removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate always:(BOOL)always{
    NSMutableArray *willRemoveHandles = [NSMutableArray array];
    NSMutableArray *mutableNotificationHandles = [self mutableNotificationHandles];
    for (NMNotificationHandle *handle in mutableNotificationHandles) {
        if ([handle delgate] == delegate && (always || ![handle always])) {
            [willRemoveHandles addObject:handle];
        }
    }
    [self _removeHandles:willRemoveHandles];
}

- (void)_removeHandles:(NSArray *)handles{
    for (NMNotificationHandle *handle in handles) {
        [handle _removeFromContainer];
    }
}

- (void)_removeHandle:(NMNotificationHandle *)handle;{
    if (handle) {
        [[self mutableNotificationHandles] removeObject:handle];
    }
}

#pragma mark - public

+ (void)handleNotification:(NMNotification *)notification backgroundFetch:(BOOL)backgroundFetch;{
    [[self shareManager] _handleNotification:notification backgroundFetch:backgroundFetch];
}

+ (NMNotificationHandle *)registerNotificationHandle:(void(^)(id<NMNotificationCustomContent> notificationContent))notificationHandle
                                                type:(NSInteger)type
                                      relationObject:(id)relationObject;{
    return [self registerNotificationHandle:notificationHandle
                                       type:type
                                     always:NO
                             relationObject:relationObject];
}

+ (NMNotificationHandle *)registerNotificationHandle:(void(^)(id<NMNotificationCustomContent> notificationContent))notificationHandle
                                                type:(NSInteger)type
                                              always:(BOOL)always
                                      relationObject:(id)relationObject;{
    return [[self shareManager] registerNotificationHandle:notificationHandle
                                                      type:type
                                                    always:always
                                            relationObject:relationObject];
}

+ (NMNotificationHandle *)registerNotificationHandleDelegate:(id<NMNotificationHandleDelegate>)delegate
                                                        type:(NSInteger)type
                                              relationObject:(id)relationObject;{
    return [self registerNotificationHandleDelegate:delegate
                                               type:type
                                             always:NO
                                     relationObject:relationObject];
}

+ (NMNotificationHandle *)registerNotificationHandleDelegate:(id<NMNotificationHandleDelegate>)delegate
                                                        type:(NSInteger)type
                                                      always:(BOOL)always
                                              relationObject:relationObject;{
    return [[self shareManager] registerNotificationHandleDelegate:delegate
                                                              type:type
                                                            always:always
                                                    relationObject:(id)relationObject];
}

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate;{
    [[self shareManager] _removeNotificationHandlesDelegate:delegate];
}

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate
                                     type:(NSInteger)type;{
    [[self shareManager] _removeNotificationHandlesDelegate:delegate
                                                       type:type];
}

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate
                                     type:(NSInteger)type
                                   always:(BOOL)always{
    [[self shareManager] _removeNotificationHandlesDelegate:delegate type:type always:always];
}

+ (void)removeNotificationHandlesDelegate:(id<NMNotificationHandleDelegate>)delegate
                                   always:(BOOL)always;{
    [[self shareManager] _removeNotificationHandlesDelegate:delegate
                                                     always:always];
}

+ (void)removeNotificationHandlesWithType:(NSInteger)type;{
    [[self shareManager] _removeNotificationHandlesWithType:type];
}

+ (void)removeNotificationContentsWithType:(NSInteger)type;{
    [[self shareManager] _removeNotificationContentsWithType:type];
}

@end

