/**
 * Beijing Sankuai Online Technology Co.,Ltd (Meituan)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
 
#import "ERAction.h"
#import "ERMacrosPrivate.h"

const NSErrorDomain ERErrorDomain = @"ERErrorDomain";
const NSInteger ERErrorCodeExecutingDisabledAction = 1001;

NSString *const ERActionException = @"ERActionException";
NSString *const ERExceptionReason_UnexpectedResultAssignment = @"Unexpected result assignment after assigning the first result/error";
NSString *const ERExceptionReason_UnexpectedErrorAssignment = @"Unexpected error assignment after assigning the first result/error";

static NSString *const kCurrentResult = @"currentResult";
static NSString *const kCurrentError = @"currentError";
static NSString *const kAssigningValue = @"assigningValue";
static NSString *const kCurrentParam = @"currentParam";

@implementation ERActionResult

- (instancetype)initWithValue:(id)value {
    if (self = [super init]) {
        _value = value;
        _status = ERActionResultStatusSuccess;
    }
    return self;
}

- (instancetype)initWithError:(NSError *)error {
    NSParameterAssert(error);
    if (self = [super init]) {
        _error = error;
        _status = ERActionResultStatusFailure;
    }
    return self;
}

@end

@implementation EZRNode (ForERAction)

- (EZRNode *)actionResult {
    return [[self filter:^BOOL(ERActionResult * _Nullable next) {
        return next.status == ERActionResultStatusSuccess;
    }] map:^id _Nullable(ERActionResult * _Nullable next) {
        return next.value;
    }];
}

- (EZRNode<NSError *> *)actionError {
    return [[self filter:^BOOL(ERActionResult * _Nullable next) {
        return next.status == ERActionResultStatusFailure;
    }] map:^id _Nullable(ERActionResult * _Nullable next) {
        return next.error;
    }];
}

@end

@interface ERAction ()

@property (nonatomic, copy, readonly) void(^block)(id param, EZRMutableNode *result, EZRMutableNode<NSError *> *error);
@property (nonatomic, strong, readonly) EZRMutableNode<NSNumber *> *innerExecuting;
@property (nonatomic, strong, readonly) EZRMutableNode<NSNumber *> *innerEnable;

@end

@implementation ERAction {
    @private
    ER_LOCK_DEF(_enableStateLock);
}

- (instancetype)initWithBlock:(void (^)(id _Nullable, EZRMutableNode<id> * _Nonnull, EZRMutableNode<NSError *> * _Nonnull))block{
    NSParameterAssert(block);
    if (self = [super init]) {
        ER_LOCK_INIT(_enableStateLock);
        _result = [EZRMutableNode new];
        _error = [EZRMutableNode new];
        _innerExecuting = [EZRMutableNode value:@NO];
        _innerEnable = [EZRMutableNode value:@YES];
        _enable = [_innerEnable fork];
        _executing = [_innerExecuting fork];
        _block = [block copy];
    }
    return self;
}

+ (instancetype)actionWithBlock:(void (^)(id, EZRMutableNode<id> *, EZRMutableNode<NSError *> *))block {
    NSParameterAssert(block);
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithSyncBlock:(id (^)(id, NSError *__autoreleasing *))block {
    NSParameterAssert(block);
    return [self initWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
        NSError *returnedError = nil;
        id returnedValue = block(param, &returnedError);
        if (returnedError) {
            error.value = returnedError;
        } else {
            result.value = returnedValue;
        }
    }];
}

+ (instancetype)actionWithSyncBlock:(id (^)(id, NSError *__autoreleasing *))block {
    NSParameterAssert(block);
    return [[self alloc] initWithSyncBlock:block];
}

- (EZRNode<ERActionResult *> *)execute:(id)param {
    ER_LOCK(_enableStateLock);
    if (!self.innerEnable.value.boolValue) {
        ER_UNLOCK(_enableStateLock);
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Executing a disabled action",
                                   NSLocalizedRecoverySuggestionErrorKey: @"Call execute: after the last execution is finished",
                                   NSLocalizedFailureReasonErrorKey: @"The action is currently not enabled",
                                   kCurrentParam: param ?: NSNull.null};
        NSError *error = [[NSError alloc] initWithDomain:ERErrorDomain code:ERErrorCodeExecutingDisabledAction userInfo:userInfo];
        ERActionResult *result = [[ERActionResult alloc] initWithError:error];
        self.error.mutablify.value = error;
        return [EZRNode value:result];
    }
    self.innerEnable.value = @NO;
    ER_UNLOCK(_enableStateLock);
    self.innerExecuting.value = @YES;

    EZRMutableNode *result = [EZRMutableNode new];
    EZRMutableNode *error = [EZRMutableNode new];

    EZRNode<ERActionResult *> *actionResult = [result map:^id(id next) {
        return [[ERActionResult alloc] initWithValue:next];
    }];

    EZRNode<ERActionResult *> *actionError = [error map:^id(id next) {
        return [[ERActionResult alloc] initWithError:next];
    }];

    EZRNode<ERActionResult *> *mergedResult = [EZRNode merge:@[actionResult, actionError]];

    EZRNode<ERActionResult *> *takenResult = [mergedResult take:1];
    EZRNode<ERActionResult *> *skippedResult = [mergedResult skip:1];

    @ezr_weakify(self);
    [[[skippedResult filter:^BOOL(ERActionResult * _Nullable next) {
        return next.status == ERActionResultStatusFailure;
    }] listenedBy:self] withBlock:^(ERActionResult * _Nullable next) {
        @ezr_strongify(self);
        NSDictionary *userInfo = @{kCurrentResult: self.result.value ?: NSNull.null,
                                   kCurrentError: self.error.value ?: NSNull.null,
                                   kAssigningValue: next.error ?: NSNull.null};
        EZR_THROW(ERActionException, ERExceptionReason_UnexpectedErrorAssignment, userInfo);
    }];

    [[[skippedResult filter:^BOOL(ERActionResult * _Nullable next) {
        return next.status == ERActionResultStatusSuccess;
    }] listenedBy:self] withBlock:^(ERActionResult * _Nullable next) {
        @ezr_strongify(self);
                NSDictionary *userInfo = @{kCurrentResult: self.result.value ?: NSNull.null,
                                           kCurrentError: self.error.value ?: NSNull.null,
                                           kAssigningValue: next.value ?: NSNull.null};
                EZR_THROW(ERActionException, ERExceptionReason_UnexpectedResultAssignment, userInfo);
    }];

    [self.innerEnable linkTo:[takenResult mapReplace:@YES]];
    [self.innerExecuting linkTo:[takenResult mapReplace:@NO]];

    [self.result linkTo:[takenResult actionResult]];

    [self.error linkTo:[takenResult actionError]];

    EZRNode<ERActionResult *> *returnedResult = EZRNode.new;
    [returnedResult linkTo:takenResult];

    NSAssert(self.block, @"self.block MUST NOT be nil");
    self.block(param, result, error);
    return returnedResult;
}

@end
