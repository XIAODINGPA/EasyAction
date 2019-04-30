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
 
#import <EasyAction/ERAction.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ERExceptionReason_InvalidParamCountForConcurrentAction;

@interface ERAction<__covariant T: id, __contravariant P: id> (Operation)

- (ERAction<id, P> *)actionWithSerialAction:(ERAction<id, T> *)action;

/**
 Make a new action with actions. Those actions will concurrent excute. The returned action will get result after all concurrent actions finish.
 todo nil.

 @param actions the action need to concurrent excute.
 @return todo
 */
+ (ERAction<NSArray<T> *, NSArray<P> *> *)actionWithConcurrentActions:(NSArray<ERAction<T, P> *> *)actions;

@end

NS_ASSUME_NONNULL_END
