arithmetic float primitives
primitiveSmallFloatEqual
	<option: #Spur64BitMemoryManager>
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory smallFloatValueOf: (self stackValue: 1).
	arg := self loadFloatOrIntFrom: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: rcvr = arg]