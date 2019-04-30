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
 
#import "EZRNode+Action.h"

@implementation EZRNode (Action)

- (id<EZRCancelable>)apply:(ERAction *)action {
    @ezr_weakify(action)
    return [[self listenedBy:action] withBlock:^(id  _Nullable next) {
        @ezr_strongify(action)
        [action execute:next];
    }];
    
}

@end
