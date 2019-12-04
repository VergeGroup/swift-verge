//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <stdatomic.h>

NS_ASSUME_NONNULL_BEGIN

@interface AtomicBridges: NSObject

+ (long)fetchAndIncrementBarrier:(_Atomic(long) *)value;

+ (long)fetchAndDecrementBarrier:(_Atomic(long) *)value;

+ (bool)compare:(_Atomic(long) *)value withExpected:(long *)expected andSwap:(long)desired;

+ (bool)comparePointer:(void * _Nullable volatile * _Nonnull)value withExpectedPointer:(void *)expected andSwapPointer:(void *)desired;

@end

NS_ASSUME_NONNULL_END
