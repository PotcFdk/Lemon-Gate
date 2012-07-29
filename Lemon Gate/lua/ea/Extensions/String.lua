/*==============================================================================================
	Expression Advanced: Strings.
	Purpose: Numbers do maths and stuffs.
	Creditors: Rusketh
==============================================================================================*/
local E_A = LemonGate

local LenStr = string.len -- Speed
local SubStr = string.sub -- Speed

local tostring = tostring

/*==============================================================================================
	Section: String Class
	Purpose: Its a string.
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterClass("string", "s", "")

E_A:RegisterOperator("assign", "s", "", function(self, ValueOp, Memory)
	-- Purpose: Assigns a string to memory
	
	local Value, Type = ValueOp(self)
	if E_A.GetShortType(Type) != "s" then self:Error("Attempt to assign %s to string variabel", Type) end
	
	self.Memory[Memory] = Value
end)

E_A:RegisterOperator("variabel", "s", "s", function(self, Memory)
	-- Purpose: Assigns a string to memory
	
	return self.Memory[Memory]
end)

/*==============================================================================================
	Section: String Operators
	Purpose: Operators that work on strings.
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterOperator("lengh", "s", "n", function(self, Value)
	-- Purpose: Gets the lengh of a string
	
	return LenStr( Value(self) )
end)

E_A:RegisterOperator("get", "sn", "s", function(self, Value, Index)
	-- Purpose: Gets the lengh of a string
	
	local I = Index(self)

	return SubStr(Value(self), I, I)
end)

E_A:RegisterOperator("addition", "ss", "s", function(self, ValueA, ValueB)
	-- Purpose: Adds two strings together.
	
	return ValueA(self) .. ValueB(self)
end)

/*==============================================================================================
	Section: Casting Operators
	Purpose: Converts stuff to strings?
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterOperator("cast", "s?", "s", function(self, Value, ConvertType)
	-- Purpose: Wild type casting.
	
	return tostring(Value(self))
end)
/*==============================================================================================
	Section: Comparason Operators
	Purpose: If statments and stuff?
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterOperator("is", "s", "n", function(self, Value)
	-- Purpose: Is Valid
	
	if Value(self) != "" then return 1 else return 0 end
end)

/*==============================================================================================
	Section: String Functions
	Purpose: Common stuffs?
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterFunction("print", "s", "", function(self, Value)
	MsgN("E-A: " .. Value(self)) -- Temp
end)
