callout support
ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #loadFloatRegs declareC: 'extern void loadFloatRegs(double, double, double, double)'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet loadFloatRegs oop |
	<var: #floatRet type: #double>
	<var: #intRet type: #usqLong>
	<inline: true>
	self cCode: '' inSmalltalk: [loadFloatRegs := #used. loadFloatRegs class].
	self cppIf: COGMTVM ifTrue:
	[(calloutState callFlags anyMask: FFICallFlagThreaded) ifTrue:
		[myThreadIndex := interpreterProxy disownVM: 0]].

	self registerArgsSlop + self cStackAlignment > 0 ifTrue:
		[self setsp: calloutState argVector].

	calloutState floatRegisterSignature > 0 ifTrue:
		[self 
			load: (calloutState floatRegisters at: 0)
			Flo: (calloutState floatRegisters at: 1)
			at: (calloutState floatRegisters at: 2)
			Re: (calloutState floatRegisters at: 3)
			gs: (calloutState floatRegisters at: 4)].

	atomicType := self atomicTypeOf: calloutState ffiRetHeader.
	(atomicType >> 1) = (FFITypeSingleFloat >> 1)
		ifTrue:
			[atomicType = FFITypeSingleFloat
				ifTrue:
					[floatRet := self 
						dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
						with: (calloutState integerRegisters at: 0)
						with: (calloutState integerRegisters at: 1)
						with: (calloutState integerRegisters at: 2)
						with: (calloutState integerRegisters at: 3)]
				ifFalse: "atomicType = FFITypeDoubleFloat"
					[floatRet := self 
						dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
						with: (calloutState integerRegisters at: 0)
						with: (calloutState integerRegisters at: 1)
						with: (calloutState integerRegisters at: 2)
						with: (calloutState integerRegisters at: 3)]]
		ifFalse:
			[intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqIntptr_t (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)].
	"undo any callee argument pops because it may confuse stack management with the alloca."
	(self isCalleePopsConvention: calloutState callFlags) ifTrue:
		[self setsp: calloutState argVector].

	self cppIf: COGMTVM ifTrue:
	[(calloutState callFlags anyMask: FFICallFlagThreaded) ifTrue:
		[interpreterProxy ownVM: myThreadIndex]].

	(calloutState ffiRetHeader anyMask: FFIFlagPointer+FFIFlagStructure) ifTrue:
		["Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent
		 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct."
		 (calloutState ffiRetHeader anyMask: FFIFlagPointer)
			ifTrue:
				[oop := self ffiReturnPointer: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState]
			ifFalse:
				[oop := self ffiReturnStruct: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
		 ^oop].
	
	(atomicType >> 1) = (FFITypeSingleFloat >> 1)
		ifTrue:
			[oop := interpreterProxy floatObjectOf: floatRet]
		ifFalse:
			[oop := self ffiCreateIntegralResultOop: intRet
						ofAtomicType: atomicType
						in: calloutState].
	^interpreterProxy methodReturnValue: oop