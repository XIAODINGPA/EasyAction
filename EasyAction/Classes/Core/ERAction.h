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
 
#import <EasyReact/EasyReact.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSErrorDomain ERErrorDomain;
extern const NSInteger ERErrorCodeExecutingDisabledAction;
extern NSString *const ERActionException;
extern NSString *const ERExceptionReason_UnexpectedResultAssignment;
extern NSString *const ERExceptionReason_UnexpectedErrorAssignment;

typedef NS_ENUM(NSUInteger, ERActionResultStatus) {
    ERActionResultStatusFailure,
    ERActionResultStatusSuccess
};

@interface ERActionResult<T: id> : NSObject

@property (nonatomic, assign, readonly) ERActionResultStatus status;
@property (nonatomic, strong, readonly, nullable) T value;
@property (nonatomic, strong, readonly, nullable) NSError *error;

- (instancetype)initWithValue:(nullable T)value;
- (instancetype)initWithError:(NSError *)error;

@end

@interface EZRNode (ForERAction)

- (EZRNode *)actionResult;

- (EZRNode<NSError *> *)actionError;

@end

typedef id ERActionNil;

@interface ERAction<__covariant T: id, __contravariant P: id> : NSObject

@property (nonatomic, strong, readonly) EZRNode<NSNumber *> *executing;
@property (nonatomic, strong, readonly) EZRNode<NSNumber *> *enable;
@property (nonatomic, strong, readonly) EZRNode<T> *result;
@property (nonatomic, strong, readonly) EZRNode<NSError *> *error;

- (instancetype)initWithBlock:(void (^)(P _Nullable param, EZRMutableNode<T> *result, EZRMutableNode<NSError *> *error))block NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithSyncBlock:(T _Nullable (^)(P _Nullable param, NSError *_Nullable *returnError))block;
+ (instancetype)actionWithBlock:(void (^)(P _Nullable param, EZRMutableNode<T> *result, EZRMutableNode<NSError *> *error))block;
+ (instancetype)actionWithSyncBlock:(T _Nullable (^)(P _Nullable param, NSError *_Nullable *returnError))block;

/**
 Execute the action with the given param. Note: executing concurrently is NOT supported.

 @param param The parameter for the action
 @return The result for this invoke. If the action is called multiple times and you want to know every result, use the 'result' property of ERAcion.
 */
- (EZRNode<ERActionResult<T> *> *)execute:(nullable P)param;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
