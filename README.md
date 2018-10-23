##### 前面写的`RAC`都是与获取数据、数据绑定相关的。如果遇到事件的处理，是没法应用的。而`RACCommand`就是一个用于处理事件的类。

首先，还是先查看`.h`文件。

    /// The domain for errors originating within `RACCommand`.
    extern NSString * const RACCommandErrorDomain;
    
定义一个域值，代表由`RACCommand`产生的错误域。

***

    /// -execute: was invoked while the command was disabled.
    extern const NSInteger RACCommandErrorNotEnabled;
    
定义一个数值，代表 当`execute:`方法执行时这个`command`是否可用的状态。

***

    /// A `userInfo` key for an error, associated with the `RACCommand` that the
    /// error originated from.
    ///
    /// This is included only when the error code is `RACCommandErrorNotEnabled`.
    extern NSString * const RACUnderlyingCommandErrorKey;
    
定义一个key值。当`RACCommand`产生的错误信息码为`RACCommandErrorNotEnabled`时，完整错误信息中会有该字段对应的错误信息。

***

    /// A command is a signal triggered in response to some action, typically
    /// UI-related.
    @interface RACCommand : NSObject
    
一个`command`是由`signal`触发来响应一些动作的。尤其是与`UI`相关的事件。

***

接下来，就是`RACCommand`类的属性与方法。

***

    /// A signal of the signals returned by successful invocations of -execute:
    /// (i.e., while the receiver is `enabled`).
    ///
    /// Errors will be automatically caught upon the inner signals, and sent upon
    /// `errors` instead. If you _want_ to receive inner errors, use -execute: or
    /// -[RACSignal materialize].
    /// 
    /// Only executions that begin _after_ subscription will be sent upon this
    /// signal. All inner signals will arrive upon the main thread.
    @property (nonatomic, strong, readonly) RACSignal *executionSignals;

该实例是一个信号，他的值也是信号类型的。这些信号类型的值是通过成功执行`execute:`方法(例如：当接收者是`enabled`状态)获取到的。

错误将会被自动从内部信号中捕获到，然后通过`errors`发送出去。如果你想要接收到内部的错误，使用`execute:`或者`-[RACSignal materialize]`。

仅仅在这个信号被订阅之后，通过执行`execute:`方法获得的信号才会被这个信号发送。所有内部的信号将切换到主线程。

***

    /// A signal of whether this command is currently executing.
    ///
    /// This will send YES whenever -execute: is invoked and the created signal has
    /// not yet terminated. Once all executions have terminated, `executing` will
    /// send NO.
    ///
    /// This signal will send its current value upon subscription, and then all
    /// future values on the main thread.
    @property (nonatomic, strong, readonly) RACSignal *executing;
    
一个信号，代表这个`command`当前是否在执行。

无论何时`execute:`被调用并且创建的信号没有终止，这个信号将会发送`YES`。一旦所有的执行信号终止，这个信号将会发送`NO`。

这个信号将会在订阅线程发送他当前的值，在主线程上发送以后的值。

***

    /// A signal of whether this command is able to execute.
    ///
    /// This will send NO if:
    ///
    ///  - The command was created with an `enabledSignal`, and NO is sent upon that
    ///    signal, or
    ///  - `allowsConcurrentExecution` is NO and the command has started executing.
    ///
    /// Once the above conditions are no longer met, the signal will send YES.
    ///
    /// This signal will send its current value upon subscription, and then all
    /// future values on the main thread.
    @property (nonatomic, strong, readonly) RACSignal *enabled;
    
一个信号代表当前的`command`是否能够执行。

如果遇到下面两种情况中的任意一个，将会发送`NO`。
1. 这个`command`通过`enabledSignal`创建，并且`enabledSignal`发送的值为`NO`。
2. `allowsConcurrentExecution`为`NO`，并且这个`command`已经开始执行了。

一旦上面的条件不再出现，就会发送`YES`。

这个信号将会在订阅线程发送他当前的值，在主线程上发送以后的值。

***

    /// Forwards any errors that occur within signals returned by -execute:.
    ///
    /// When an error occurs on a signal returned from -execute:, this signal will
    /// send the associated NSError value as a `next` event (since an `error` event
    /// would terminate the stream).
    ///
    /// After subscription, this signal will send all future errors on the main
    /// thread.
    @property (nonatomic, strong, readonly) RACSignal *errors;
    
传递执行`execute:`方法返回的所有信号中发生任何的错误。

当执行`execute:`方法返回的一个信号发生了错误，这个信号将会发送相关的错误值作为`next`值（因为一个`error`事件将会终止整个流）。

当这个信号被订阅，将会在主线程发送以后所有的错误。

***

    /// Whether the command allows multiple executions to proceed concurrently.
    ///
    /// The default value for this property is NO.
    @property (atomic, assign) BOOL allowsConcurrentExecution;
    
代表着这个`command`是否允许并行执行。

该属性的默认值为`NO`。

***

    /// Invokes -initWithEnabled:signalBlock: with a nil `enabledSignal`.
    - (id)initWithSignalBlock:(RACSignal * (^)(id input))signalBlock;
    
调用`-initWithEnabled:signalBlock:`方法，参数`enabledSignal`为`nil`。

***

    /// Initializes a command that is conditionally enabled.
    ///
    /// This is the designated initializer for this class.
    ///
    /// enabledSignal - A signal of BOOLs which indicate whether the command should
    ///                 be enabled. `enabled` will be based on the latest value sent
    ///                 from this signal. Before any values are sent, `enabled` will
    ///                 default to YES. This argument may be nil.
    /// signalBlock   - A block which will map each input value (passed to -execute:)
    ///                 to a signal of work. The returned signal will be multicasted
    ///                 to a replay subject, sent on `executionSignals`, then
    ///                 subscribed to synchronously. Neither the block nor the
    ///                 returned signal may be nil.
    - (id)initWithEnabled:(RACSignal *)enabledSignal signalBlock:(RACSignal * (^)(id input))signalBlock;
    
初始化一个`command`对象，并且受条件控制是否可执行。

这个方法是这个类的指定初始化方法。

`enabledSignal` 是一串`BOOL`值的信号，用于指定`command`是否可用。`enabled`依赖于这个信号的最新值。在所有值发送之前，`enabled`默认为`YES`。这个参数可以为`nil`。

`signalBlock` 是一个`block`。这个block会`map`每一个输入值(`execute:`方法的参数值)用于一个信号的工作。返回的信号将会被`multicasted`一个`replay subject`对象，通过`executionSignals`发送出去，然后同步被订阅。不管是这个`block`还是这个`block`返回的信号都不能为`nil`。

***

    /// If the receiver is enabled, this method will:
    ///
    ///  1. Invoke the `signalBlock` given at the time of initialization.
    ///  2. Multicast the returned signal to a RACReplaySubject.
    ///  3. Send the multicasted signal on `executionSignals`.
    ///  4. Subscribe (connect) to the original signal on the main thread.
    ///
    /// input - The input value to pass to the receiver's `signalBlock`. This may be
    ///         nil.
    ///
    /// Returns the multicasted signal, after subscription. If the receiver is not
    /// enabled, returns a signal that will send an error with code
    /// RACCommandErrorNotEnabled.
    - (RACSignal *)execute:(id)input;
    
如果这个调用者(也就是`command`对象)是`enabled`，这个方法将会做4件事：
1. 获取初始化方法中的`signalBlock`.
2. 通过`signalBlock`获取信号，并将信号`Multicast`到一个`RACReplaySubject`对象。
3. 通过`executionSignals`发送已经`multicasted`的信号。
4. 在主线程订阅`connect`源信号。

`input` 作为参数值供`signalBlock`调用时使用。可以为`nil`。

调用之后，返回`multicasted`的信号。如果调用者(`command`)不可用，返回一个会发送错误并且错误码为`RACCommandErrorNotEnabled`的信号。

***

上面把`.h`文件中的内容翻译完了，接着看`.m`中的内容。

    NSString * const RACCommandErrorDomain = @"RACCommandErrorDomain";
    NSString * const RACUnderlyingCommandErrorKey = @"RACUnderlyingCommandErrorKey";
    
    const NSInteger RACCommandErrorNotEnabled = 1;
    
首先，将`.h`中定义的一些常量赋值。

***

	// The mutable array backing `activeExecutionSignals`.
	//
	// This should only be used while synchronized on `self`.
	NSMutableArray *_activeExecutionSignals;
    
定义一个可变数组，用于存储执行的信号。这个值应该同步执行。

***

    // Atomic backing variable for `allowsConcurrentExecution`.
    volatile uint32_t _allowsConcurrentExecution;

定义`allowsConcurrentExecution`变量，该变量的操作是原子性的。

***

    // An array of signals representing in-flight executions, in the order they
    // began.
    //
    // This property is KVO-compliant.
    @property (atomic, copy, readonly) NSArray *activeExecutionSignals;
    
一个信号数组，这些信号按照他们开始的顺序存放到数组中。

这个属性值支持`KVO`。

***

    // `enabled`, but without a hop to the main thread.
    //
    // Values from this signal may arrive on any thread.
    @property (nonatomic, strong, readonly) RACSignal *immediateEnabled;
    
代表可用状态，不会切换到主线程中。

这个信号的值可以运行在任何线程上。

***

    // The signal block that the receiver was initialized with.
    @property (nonatomic, copy, readonly) RACSignal * (^signalBlock)(id input);
    
初始化方法中的参数信号块。

***

    // Adds a signal to `activeExecutionSignals` and generates a KVO notification.
    - (void)addActiveExecutionSignal:(RACSignal *)signal;
    
将一个信号添加到`activeExecutionSignals`数组中，并且产生一个`KVO`的通知。

***

    // Removes a signal from `activeExecutionSignals` and generates a KVO
    // notification.
    - (void)removeActiveExecutionSignal:(RACSignal *)signal;
    
从`activeExecutionSignals`数组中移除一个信号并且产生一个`KVO`通知。

***

    - (BOOL)allowsConcurrentExecution {
    	return _allowsConcurrentExecution != 0;
    }

这里通过判断`_allowsConcurrentExecution`的值是否为`0`来决定是否允许并行执行。

***

    - (void)setAllowsConcurrentExecution:(BOOL)allowed {
    	[self willChangeValueForKey:@keypath(self.allowsConcurrentExecution)];
    
    	if (allowed) {
    		OSAtomicOr32Barrier(1, &_allowsConcurrentExecution);
    	} else {
    		OSAtomicAnd32Barrier(0, &_allowsConcurrentExecution);
    	}
    
    	[self didChangeValueForKey:@keypath(self.allowsConcurrentExecution)];
    }
    
通过`willChangeValueForKey` `didChangeValueForKey` 方法实现`KVO`通知。通过`OSAtomicOr32Barrier` `OSAtomicAnd32Barrier`保证`_allowsConcurrentExecution`变量的改变线程安全。

***

    - (NSArray *)activeExecutionSignals {
    	@synchronized (self) {
    		return [_activeExecutionSignals copy];
    	}
    }

重写`getter`方法，同步返回`_activeExecutionSignals`。

***

    - (void)addActiveExecutionSignal:(RACSignal *)signal {
    	NSCParameterAssert([signal isKindOfClass:RACSignal.class]);
    
    	@synchronized (self) {
    		// The KVO notification has to be generated while synchronized, because
    		// it depends on the index remaining consistent.
    		NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:_activeExecutionSignals.count];
    		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@keypath(self.activeExecutionSignals)];
    		[_activeExecutionSignals addObject:signal];
    		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@keypath(self.activeExecutionSignals)];
    	}
    }
    
参数必须是信号类型，并且同步执行操作，因为他依赖于`_activeExecutionSignals`索引保持不变。

首先，获取到数组的容量，用于发送`KVO`通知。然后将信号添加到数组中。

***

    - (void)removeActiveExecutionSignal:(RACSignal *)signal {
    	NSCParameterAssert([signal isKindOfClass:RACSignal.class]);
    
    	@synchronized (self) {
    		// The indexes have to be calculated and the notification generated
    		// while synchronized, because they depend on the indexes remaining
    		// consistent.
    		NSIndexSet *indexes = [_activeExecutionSignals indexesOfObjectsPassingTest:^ BOOL (RACSignal *obj, NSUInteger index, BOOL *stop) {
    			return obj == signal;
    		}];
    
    		if (indexes.count == 0) return;
    
    		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@keypath(self.activeExecutionSignals)];
    		[_activeExecutionSignals removeObjectsAtIndexes:indexes];
    		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@keypath(self.activeExecutionSignals)];
    	}
    }
    
参数必须是信号类型，并且同步执行操作，因为他依赖于`_activeExecutionSignals`索引保持不变。

首先，通过遍历数组获取到参数`signal`对应的索引值。如果数组中存在对应的信号，就将其移除并发送`KVO`通知。

***

    - (id)init {
    	NSCAssert(NO, @"Use -initWithSignalBlock: instead");
    	return nil;
    }
    
添加断言并返回`nil`，保证外部无法通过`init`方法完成初始化。

***

    - (id)initWithSignalBlock:(RACSignal * (^)(id input))signalBlock {
    	return [self initWithEnabled:nil signalBlock:signalBlock];
    }
    
    - (id)initWithEnabled:(RACSignal *)enabledSignal signalBlock:(RACSignal * (^)(id input))signalBlock {
    	NSCParameterAssert(signalBlock != nil);
    
    	self = [super init];
    	if (self == nil) return nil;
    
    	_activeExecutionSignals = [[NSMutableArray alloc] init];
    	_signalBlock = [signalBlock copy];
    
    	// A signal of additions to `activeExecutionSignals`.
    	RACSignal *newActiveExecutionSignals = [[[[[self
    		rac_valuesAndChangesForKeyPath:@keypath(self.activeExecutionSignals) options:NSKeyValueObservingOptionNew observer:nil]
    		reduceEach:^(id _, NSDictionary *change) {
    			NSArray *signals = change[NSKeyValueChangeNewKey];
    			if (signals == nil) return [RACSignal empty];
    
    			return [signals.rac_sequence signalWithScheduler:RACScheduler.immediateScheduler];
    		}]
    		concat]
    		publish]
    		autoconnect];
    
    	_executionSignals = [[[newActiveExecutionSignals
    		map:^(RACSignal *signal) {
    			return [signal catchTo:[RACSignal empty]];
    		}]
    		deliverOn:RACScheduler.mainThreadScheduler]
    		setNameWithFormat:@"%@ -executionSignals", self];
    	
    	// `errors` needs to be multicasted so that it picks up all
    	// `activeExecutionSignals` that are added.
    	//
    	// In other words, if someone subscribes to `errors` _after_ an execution
    	// has started, it should still receive any error from that execution.
    	RACMulticastConnection *errorsConnection = [[[newActiveExecutionSignals
    		flattenMap:^(RACSignal *signal) {
    			return [[signal
    				ignoreValues]
    				catch:^(NSError *error) {
    					return [RACSignal return:error];
    				}];
    		}]
    		deliverOn:RACScheduler.mainThreadScheduler]
    		publish];
    	
    	_errors = [errorsConnection.signal setNameWithFormat:@"%@ -errors", self];
    	[errorsConnection connect];
    
    	RACSignal *immediateExecuting = [RACObserve(self, activeExecutionSignals) map:^(NSArray *activeSignals) {
    		return @(activeSignals.count > 0);
    	}];
    
    	_executing = [[[[[immediateExecuting
    		deliverOn:RACScheduler.mainThreadScheduler]
    		// This is useful before the first value arrives on the main thread.
    		startWith:@NO]
    		distinctUntilChanged]
    		replayLast]
    		setNameWithFormat:@"%@ -executing", self];
    
    	RACSignal *moreExecutionsAllowed = [RACSignal
    		if:RACObserve(self, allowsConcurrentExecution)
    		then:[RACSignal return:@YES]
    		else:[immediateExecuting not]];
    	
    	if (enabledSignal == nil) {
    		enabledSignal = [RACSignal return:@YES];
    	} else {
    		enabledSignal = [[[enabledSignal
    			startWith:@YES]
    			takeUntil:self.rac_willDeallocSignal]
    			replayLast];
    	}
    	
    	_immediateEnabled = [[RACSignal
    		combineLatest:@[ enabledSignal, moreExecutionsAllowed ]]
    		and];
    	
    	_enabled = [[[[[self.immediateEnabled
    		take:1]
    		concat:[[self.immediateEnabled skip:1] deliverOn:RACScheduler.mainThreadScheduler]]
    		distinctUntilChanged]
    		replayLast]
    		setNameWithFormat:@"%@ -enabled", self];
    
    	return self;
    }
    
指定初始化方法。也是这个类的最重要部分，下面分步骤分析：

1. 初始化实例变量`_activeExecutionSignals`，通过实例变量`_signalBlock`保存参数。
2. 创建一个信号`newActiveExecutionSignals`。

    * 通过`rac_valuesAndChangesForKeyPath:options:observer:`方法获取一个观察`activeExecutionSignals`值的改变的信号。
    * 通过`reduceEach:`方法将上一步中获取的信号值(数组)转换为一个序列。
    * 通过`concat`方法对上一步获取的信号的值(也是信号)进行订阅。
    * 使用`publish`方法将信号转成`RACMulticastConnection`信号。
    * 使用`autoconnect`方法返回一个可以对源信号进行订阅的信号。
    
    其实这里就是将`_activeExecutionSignals`数组中的信号作为`newActiveExecutionSignals`的值，用于订阅使用。
    
3. 实例化`_executionSignals`变量。

    * 通过对第2步创建的`newActiveExecutionSignals`进行`map:`操作，对信号值进行操作(发生错误时，返回一个`RACEmptySignal`信号)
    。
    * 调用`deliverOn:`方法切换到主线程。
    * 给信号设置个名字。
    
4. 为了使`errors`能够被接收到，所以这里获取`activeExecutionSignals`中所有的信号。

   也就是说，如果在一个执行之后订阅`errors`，他会接收到这个执行的所有错误信息。
   
   * 先对第2步中的`newActiveExecutionSignals`调用`flattenMap:`方法，将错误信息转换成信号。
   * 转换到主线程中。
   * 调用`publish`转换成`RACMulticastConnection`信号。
   
5. 实例化`_errors`变量，保存第4步中`errorsConnection`的`signal`。
6. `errorsConnection`调用`connect`开始信号的订阅。
7. 通过`RACObserve`获取到关于`activeExecutionSignals`的信号，然后使用`map:`将信号值转成`BOOL`(其实是`NSNumber`)类型，最终得到信号`immediateExecuting`。
8. 实例化`_executing`变量。
    
    * 将`immediateExecuting`切换到主线程。
    * 调用`startWith:`方法，将开始值设置为`NO`。
    * 调用`distinctUntilChanged`方法，保证信号值每次变化才发送。
    * 调用`replayLast`方法，对信号订阅并且只保留信号的一个值。
    * 给信号设置名字。
    
9. 实例化`moreExecutionsAllowed`变量。通过`if:then:else:`方法，如果`allowsConcurrentExecution`为`YES`，返回信号值为`YES`的信号；否则返回`immediateExecuting`的值取反的信号。

   也就是说，`moreExecutionsAllowed`表示当前是否允许更多的执行。如果`allowsConcurrentExecution`为`YES`，就表示允许并行操作，所以`moreExecutionsAllowed`的值应该为`YES`；如果`allowsConcurrentExecution`为`NO`，使用`immediateExecuting`作为判断条件，如果`immediateExecuting`为`YES`表明此时有任务执行，所以取反表示当前不再允许新增执行任务；如果`immediateExecuting`为`NO`表明此时没有任务执行，所以取反表示当前允许新增任务执行。
   
10. 对`enabledSignal`做处理。如果`enabledSignal`为`nil`，以@(YES)作为信号值将其初始化。如果`enabledSignal`不为`nil`，使用`startWith:`将其初始值设置为`YES`，然后调用`takeUntil:`将其生命周期控制在当前类的生命周期中；然后使用`replayLast`完成对信号的订阅并保留1个值。
11. 初始化`_immediateEnabled`变量。通过`combineLatest:`方法将`enabledSignal` `moreExecutionsAllowed` 最新值组合起来，然后调用`and`方法将组合值进行与运算。
12. 初始化`_enabled`变量。

    * `_immediateEnabled`对象调用`take:`方法，获取一个信号值。
    * 调用`concat:`将上一步的得到的信号连接另一个信号。而这个信号是`_immediateEnabled`除去第一个值之后组成的信号，并运行在主线程上。
    * 调用`distinctUntilChanged`保证值发生了变化再发送。
    * 调用`replayLast`开始对信号订阅，并保留最新的一个值。
    * 设置一个名字。

13. 返回`self`，完成初始化工作。

***

    - (RACSignal *)execute:(id)input {
    	// `immediateEnabled` is guaranteed to send a value upon subscription, so
    	// -first is acceptable here.
    	BOOL enabled = [[self.immediateEnabled first] boolValue];
    	if (!enabled) {
    		NSError *error = [NSError errorWithDomain:RACCommandErrorDomain code:RACCommandErrorNotEnabled userInfo:@{
    			NSLocalizedDescriptionKey: NSLocalizedString(@"The command is disabled and cannot be executed", nil),
    			RACUnderlyingCommandErrorKey: self
    		}];
    
    		return [RACSignal error:error];
    	}
    
    	RACSignal *signal = self.signalBlock(input);
    	NSCAssert(signal != nil, @"nil signal returned from signal block for value: %@", input);
    
    	// We subscribe to the signal on the main thread so that it occurs _after_
    	// -addActiveExecutionSignal: completes below.
    	//
    	// This means that `executing` and `enabled` will send updated values before
    	// the signal actually starts performing work.
    	RACMulticastConnection *connection = [[signal
    		subscribeOn:RACScheduler.mainThreadScheduler]
    		multicast:[RACReplaySubject subject]];
    	
    	@weakify(self);
    
    	[self addActiveExecutionSignal:connection.signal];
    	[connection.signal subscribeError:^(NSError *error) {
    		@strongify(self);
    		[self removeActiveExecutionSignal:connection.signal];
    	} completed:^{
    		@strongify(self);
    		[self removeActiveExecutionSignal:connection.signal];
    	}];
    
    	[connection connect];
    	return [connection.signal setNameWithFormat:@"%@ -execute: %@", self, [input rac_description]];
    }
    
这个是`command`的执行方法，还是要分步骤分析：

1. 获取`immediateEnabled`第一个值，如果为`NO`，返回一个错误信号；如果为`YES`，继续下面过程。
2. 执行`signalBlock`获取一个信号，并通过断言保证该信号必须存在。
3. 在主线程订阅第二步中获取到的信号，为了保证订阅发生在下一步`addActiveExecutionSignal:`之后。这也就意味着`executing` `enabled` 会在这个正式开始执行前发送更新的值。注意，这里是创建了一个`RACMulticastConnection`对象，此时信号还没有被订阅。
4. 调用`addActiveExecutionSignal:`方法添加信号。
5. 对上一步中的`[RACReplaySubject subject]`进行订阅，在信号结束(完成或者错误)的时候，调用`removeActiveExecutionSignal:`将其移除。
6. 调用第三步创建的`connection`的`connect`方法，开始对源信号的订阅。
7. 给信号设置名称，并返回。

***

    + (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    	// Generate all KVO notifications manually to avoid the performance impact
    	// of unnecessary swizzling.
    	return NO;
    }
    
该方法控制`KVO`通知的产生是系统自动产生，还是手动产生。这里返回`NO`意味着手动产生，目的是为了防止其他类的`swizzling`产生影响。


完整测试用例在[这里](https://github.com/jianghui1/TestRACCommand)。

    - (void)test_RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey
    {
        RACSignal *enabledSignal = [RACSignal return:@(YES)];
        RACSignal *signal = [RACSignal return:@"hehe"];
        RACCommand *command = [[RACCommand alloc] initWithEnabled:enabledSignal signalBlock:^RACSignal *(id input) {
            return signal;
        }];
        
        [[command execute:nil] subscribeNext:^(id x) {
            NSLog(@"111 -next -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey -- %@", error);
        }];
        
        // 打印日志
        /*
         2018-10-11 17:40:00.934158+0800 TestRACCommand[96786:660968] 111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey -- Error Domain=RACCommandErrorDomain Code=1 "The command is disabled and cannot be executed" UserInfo={RACUnderlyingCommandErrorKey=<RACCommand: 0x600000062620>, NSLocalizedDescription=The command is disabled and cannot be executed}
         */
    }
    
    - (void)test_RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1
    {
        RACSignal *enabledSignal = [RACSignal return:@(YES)];
        RACSignal *signal = [RACSignal error:[NSError errorWithDomain:@"test" code:1 userInfo:@{@"key" : @"value"}]];
        RACCommand *command = [[RACCommand alloc] initWithEnabled:enabledSignal signalBlock:^RACSignal *(id input) {
            return signal;
        }];
        
        [[command execute:nil] subscribeNext:^(id x) {
            NSLog(@"111 -next -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1 -- %@", error);
        }];
        
        // 打印日志
        /*
         2018-10-11 17:47:51.230763+0800 TestRACCommand[96875:664284] 111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1 -- Error Domain=test Code=1 "(null)" UserInfo={key=value}
         */
    }
    
    - (void)test_executionSignals
    {
        RACSignal *signal0 = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACSignal *signal2 = [RACSignal return:@(2)];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal0;
                    break;
                case 1:
                    return signal1;
                    break;
                case 2:
                    return signal2;
                    break;
                    
                default:
                    break;
            }
            return nil;
        }];
        command.allowsConcurrentExecution = YES;
        
        RACSignal *eS0 = [command execute:@(0)];
        [eS0 subscribeNext:^(id x) {
            NSLog(@"executionSignals -- eS0 -- %@", x);
        }];
        
        [command.executionSignals subscribeNext:^(id x) {
            NSLog(@"executionSignals -- executionSignals -- %@", x);
            if ([x isKindOfClass:[RACSignal class]]) { // 注意，这里由于`command`内部的处理，直接比较信号是不相等的，但是通过c输出信号值可以看出信号x等效相等。
                RACSignal *signal = x;
                [signal subscribeNext:^(id y) {
                    NSLog(@"executionSignals -- executionSignals -- signal -- %@", y);
                }];
            }
        }];
        
        RACSignal *eS1 = [command execute:@(1)];
        [eS1 subscribeNext:^(id x) {
            NSLog(@"executionSignals -- eS1 -- %@", x);
        }];
        
        RACSignal *eS2 = [command execute:@(2)];
        [eS2 subscribeNext:^(id x) {
            NSLog(@"executionSignals -- eS2 -- %@", x);
        }];
        
        // 打印日志
        /*
         2018-10-12 21:06:56.734721+0800 TestRACCommand[57934:1089988] executionSignals -- eS0 -- 0
         2018-10-12 21:06:56.735070+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- <RACDynamicSignal: 0x6000038e2900> name:
         2018-10-12 21:06:56.735293+0800 TestRACCommand[57934:1089988] executionSignals -- eS1 -- 1
         2018-10-12 21:06:56.735414+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- signal -- 1
         2018-10-12 21:06:56.735828+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- <RACDynamicSignal: 0x6000038abac0> name:
         2018-10-12 21:06:56.736155+0800 TestRACCommand[57934:1089988] executionSignals -- eS2 -- 2
         2018-10-12 21:06:56.736337+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- signal -- 2
         */
    }
    
    - (void)test_executionSignals1
    {
        RACSignal *signal0 = [RACSignal error:[NSError errorWithDomain:@"executionSignals1" code:0 userInfo:nil]];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return signal0;
        }];
        command.allowsConcurrentExecution = YES;
        
        [command.executionSignals subscribeNext:^(id x) {
            NSLog(@"executionSignals -- executionSignals -- %@ -- %@", x, [NSThread currentThread]);
        }];
        
        RACSignal *eS0 = [command execute:@(0)];
        [eS0 subscribeNext:^(id x) {
            NSLog(@"executionSignals -- eS0 -- %@", x);
        }];
        
        // 打印日志
        /*
         2018-10-12 21:11:04.161131+0800 TestRACCommand[58045:1091953] executionSignals -- executionSignals -- <RACDynamicSignal: 0x600003c34d40> name:  -- <NSThread: 0x600002962840>{number = 1, name = main}
         */
    }
    
    - (void)test_executionSignals2
    {
        RACSignal *signal0 = [RACSignal error:[NSError errorWithDomain:@"executionSignals1" code:0 userInfo:nil]];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return signal0;
        }];
        command.allowsConcurrentExecution = YES;
        
        [command.errors subscribeNext:^(id x) {
            NSLog(@"executionSignals -- errors -- %@", x);
        }];
        
        RACSignal *eS0 = [command execute:@(0)];
        [eS0 subscribeNext:^(id x) {
            NSLog(@"executionSignals -- eS0 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"executionSignals -- eS0 -- error -- %@", error);
        }];
        
        [[eS0 materialize] subscribeNext:^(id x) {
            NSLog(@"executionSignals -- materialize -- %@", x);
        }];
        
        // 打印日志
        /*
         2018-10-12 21:18:06.690660+0800 TestRACCommand[58170:1096115] executionSignals -- eS0 -- error -- Error Domain=executionSignals1 Code=0 "(null)"
         2018-10-12 21:18:06.691228+0800 TestRACCommand[58170:1096115] executionSignals -- materialize -- <RACEvent: 0x6000014d5700>{ error = Error Domain=executionSignals1 Code=0 "(null)" }
         2018-10-12 21:18:06.691695+0800 TestRACCommand[58170:1096115] executionSignals -- errors -- Error Domain=executionSignals1 Code=0 "(null)"
         */
    }
    
    - (void)test_executing
    {
        RACSignal *signal0 = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal0;
                    break;
                    case 1:
                    return signal1;
                    
                default:
                    break;
            }
            return nil;
        }];
        command.allowsConcurrentExecution = YES;
        
        [command.executing subscribeNext:^(id x) {
            NSLog(@"executing -- %@ -- %@", x, [NSThread currentThread]);
        }];
        
        [[command execute:@(1)] subscribeNext:^(id x) {
            NSLog(@"executing -- 1 - %@", x);
        } completed:^{
            NSLog(@"executing -- 1 - completed");
        }];
        
        [[command execute:@(0)] subscribeNext:^(id x) {
            NSLog(@"executing -- 0 - %@", x);
        } completed:^{
            NSLog(@"executing -- 0 - completed");
        }];
    
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-10-15 18:36:30.916392+0800 TestRACCommand[97357:1502488] executing -- 0 -- <NSThread: 0x600002419e00>{number = 1, name = main}
         2018-10-15 18:36:30.921302+0800 TestRACCommand[97357:1502488] executing -- 1 -- <NSThread: 0x600002419e00>{number = 1, name = main}
         2018-10-15 18:36:30.921563+0800 TestRACCommand[97357:1502488] executing -- 1 - 1
         2018-10-15 18:36:30.922202+0800 TestRACCommand[97357:1502488] executing -- 1 - completed
         2018-10-15 18:36:30.922647+0800 TestRACCommand[97357:1502488] executing -- 0 - 0
         2018-10-15 18:36:30.923200+0800 TestRACCommand[97357:1502488] executing -- 0 - completed
         2018-10-15 18:36:30.923489+0800 TestRACCommand[97357:1502488] executing -- 0 -- <NSThread: 0x600002419e00>{number = 1, name = main}
         */
    }
    
    - (void)test_enabled
    {
        RACSignal *signal0 = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal0;
                    break;
                case 1:
                    return signal1;
                    
                default:
                    break;
            }
            return nil;
        }];
        command.allowsConcurrentExecution = YES;
        
        [command.enabled subscribeNext:^(id x) {
            NSLog(@"enabled -- %@ -- %@", x, [NSThread currentThread]);
        }];
        
        [[command execute:@(1)] subscribeNext:^(id x) {
            NSLog(@"enabled -- 1 - %@", x);
        } completed:^{
            NSLog(@"enabled -- 1 - completed");
        }];
        
        [[command execute:@(0)] subscribeNext:^(id x) {
            NSLog(@"enabled -- 0 - %@", x);
        } completed:^{
            NSLog(@"enabled -- 0 - completed");
        }];
        
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-10-15 18:50:55.877550+0800 TestRACCommand[97614:1510198] executing -- 0 -- <NSThread: 0x600003176d00>{number = 1, name = main}
         2018-10-15 18:50:55.881961+0800 TestRACCommand[97614:1510198] executing -- 1 -- <NSThread: 0x600003176d00>{number = 1, name = main}
         2018-10-15 18:50:55.882613+0800 TestRACCommand[97614:1510198] executing -- 1 - 1
         2018-10-15 18:50:55.883467+0800 TestRACCommand[97614:1510198] executing -- 1 - completed
         2018-10-15 18:50:55.883662+0800 TestRACCommand[97614:1510198] executing -- 0 - 0
         2018-10-15 18:50:55.884038+0800 TestRACCommand[97614:1510198] executing -- 0 - completed
         2018-10-15 18:50:55.884260+0800 TestRACCommand[97614:1510198] executing -- 0 -- <NSThread: 0x600003176d00>{number = 1, name = main}
         */
    }
    
    - (void)test_enabled1
    {
        RACSignal *signal0 = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACCommand *command = [[RACCommand alloc] initWithEnabled:[RACSignal return:@(NO)] signalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal0;
                    break;
                case 1:
                    return signal1;
                    
                default:
                    break;
            }
            return nil;
        }];
        command.allowsConcurrentExecution = YES;
        
        [command.enabled subscribeNext:^(id x) {
            NSLog(@"enabled -- %@ -- %@", x, [NSThread currentThread]);
        }];
        
        [[command execute:@(1)] subscribeNext:^(id x) {
            NSLog(@"enabled -- 1 - %@", x);
        } completed:^{
            NSLog(@"enabled -- 1 - completed");
        }];
        
        [[command execute:@(0)] subscribeNext:^(id x) {
            NSLog(@"enabled -- 0 - %@", x);
        } completed:^{
            NSLog(@"enabled -- 0 - completed");
        }];
        
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-10-15 18:56:16.271611+0800 TestRACCommand[97703:1513263] enabled -- 0 -- <NSThread: 0x600001ae1500>{number = 1, name = main}
         */
    }
    
    - (void)test_enabled2
    {
        RACSignal *signal0 = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACCommand *command = [[RACCommand alloc] initWithEnabled:[RACSignal return:@(YES)] signalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal0;
                    break;
                case 1:
                    return signal1;
                    
                default:
                    break;
            }
            return nil;
        }];
        command.allowsConcurrentExecution = NO;
        
        [command.enabled subscribeNext:^(id x) {
            NSLog(@"enabled -- %@ -- %@", x, [NSThread currentThread]);
        }];
        
        [[command execute:@(1)] subscribeNext:^(id x) {
            NSLog(@"enabled -- 1 - %@", x);
        } completed:^{
            NSLog(@"enabled -- 1 - completed");
        }];
        
        [[command execute:@(0)] subscribeNext:^(id x) {
            NSLog(@"enabled -- 0 - %@", x);
        } completed:^{
            NSLog(@"enabled -- 0 - completed");
        }];
        
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-10-15 18:57:15.525766+0800 TestRACCommand[97741:1514378] enabled -- 1 -- <NSThread: 0x600001f7e900>{number = 1, name = main}
         2018-10-15 18:57:15.530452+0800 TestRACCommand[97741:1514378] enabled -- 0 -- <NSThread: 0x600001f7e900>{number = 1, name = main}
         2018-10-15 18:57:15.530711+0800 TestRACCommand[97741:1514378] enabled -- 1 - 1
         2018-10-15 18:57:15.531299+0800 TestRACCommand[97741:1514378] enabled -- 1 - completed
         2018-10-15 18:57:15.531506+0800 TestRACCommand[97741:1514378] enabled -- 1 -- <NSThread: 0x600001f7e900>{number = 1, name = main}
         */
    }
    
    - (void)test_errors
    {
        RACSignal *error = [RACSignal error:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{}]];
        RACSignal *error1 = [RACSignal error:[NSError errorWithDomain:NSURLErrorDomain code:1 userInfo:@{}]];
        RACSignal *signal = [RACSignal return:@(2)];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return error;
                    break;
                    
                    case 1:
                    return error1;
                    break;
                    
                    case 2:
                    return signal;
                    break;
                default:
                    return nil;
                    break;
            }
        }];
        command.allowsConcurrentExecution = YES;
        
        [command.errors subscribeNext:^(id x) {
            NSLog(@"todo -- %@ -- %@", x, [NSThread currentThread]);
        }];
        
        [command execute:@(0)];
        [command execute:@(2)];
        [command execute:@(1)];
        
        // 打印日志：
        /*
         2018-10-22 17:34:30.441865+0800 TestRACCommand[52256:749872] todo -- Error Domain=NSURLErrorDomain Code=0 "(null)" -- <NSThread: 0x6000020428c0>{number = 1, name = main}
         2018-10-22 17:34:30.442127+0800 TestRACCommand[52256:749872] todo -- Error Domain=NSURLErrorDomain Code=1 "(null)" -- <NSThread: 0x6000020428c0>{number = 1, name = main}
         */
    }
    
    - (void)test_allowsConcurrentExecution
    {
        RACSignal *signal = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal;
                    break;
                case 1:
                    return signal1;
                    break;
                default:
                    return nil;
                    break;
            }
        }];
        command.allowsConcurrentExecution = YES;
        
        [[command execute:@(0)] subscribeNext:^(id x) {
            NSLog(@"allowsConcurrentExecution -- %@", x);
        }];
        [[command execute:@(1)] subscribeNext:^(id x) {
            NSLog(@"allowsConcurrentExecution -- %@", x);
        }];
        // 打印日志
        /*
         2018-10-22 17:47:43.134296+0800 TestRACCommand[52411:755212] allowsConcurrentExecution -- 0
         2018-10-22 17:47:43.134610+0800 TestRACCommand[52411:755212] allowsConcurrentExecution -- 1
         */
    }
    
    - (void)test_allowsConcurrentExecution1
    {
        RACSignal *signal = [RACSignal return:@(0)];
        RACSignal *signal1 = [RACSignal return:@(1)];
        RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            switch ([input intValue]) {
                case 0:
                    return signal;
                    break;
                case 1:
                    return signal1;
                    break;
                default:
                    return nil;
                    break;
            }
        }];
        command.allowsConcurrentExecution = NO;
        
        [[command execute:@(0)] subscribeNext:^(id x) {
            NSLog(@"allowsConcurrentExecution1 -- %@", x);
        }];
        [[command execute:@(1)] subscribeNext:^(id x) {
            NSLog(@"allowsConcurrentExecution1 -- %@", x);
        }];
        // 打印日志
        /*
        2018-10-22 17:48:16.669158+0800 TestRACCommand[52427:755785] allowsConcurrentExecution1 -- 0
         */
    }
