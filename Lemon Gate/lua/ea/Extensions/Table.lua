/*==============================================================================================
	Expression Advanced: Tables.
	Purpose: Strings and such.
	Note: Rusks genius idea!
	Creditors: Rusketh
==============================================================================================*/
local E_A = LemonGate
local MAX = 512

local TableInsert = table.insert
local TableCopy = table.Copy

local setmetatable = setmetatable

/*==============================================================================================
	Table Builders
==============================================================================================*/
local Table = {}
Table.__index = Table

function E_A.NewTable()
	return setmetatable({ Data = {}, Types = {}, Size = 0, Count = 0 }, Table)
end

local NewTable = E_A.NewTable

function E_A.NewResultTable(Values, Type)
	local Size, Types = #Values, {}
	local Result = setmetatable({ Data = Values, Types = Types, Size = Size, Count = Size }, Table)
	for I = 1, Size do Types[I] = Type end
	return Result
end

/*==============================================================================================
	Table Metacore
==============================================================================================*/

function Table:Set(Index, Type, Value)
	local Data, Types = self.Data, self.Types
	local Size , Count = self.Size, self.Count
	local OldVal, OldTyp = Data[Index], Types[Index]
	
	if OldVal and OldTyp == "t" then
		Size = Size - OldVal:GetSize()
	end -- Allows us to unallocate memory used up by old tables.
	
	if Type == "t" then
		Size = Size + Value.Size
	end
	
	if !OldVal then
		Size = Size + 1 -- Update the meory and index count!
		Count = Count + 1
	end
	
	if Size > MAX then return false end -- Table is too big!
	
	Data[Index] = Value
	Types[Index] = Type
	self.Size = Size
	self.Count = Count
	
	return true
end

function Table:Insert(Index, Type, Value)
	local Data, Types = self.Data, self.Types
	local Size , Count = self.Size, self.Count
	
	Index = Index or #self.Data + 1
	
	Size = Size + 1
	Count = Count + 1
	
	if Type == "t" then Size = Size + Value.Size end
	if Size > MAX then return false end -- Table is too big!
	
	TableInsert(Data, Index, Value)
	TableInsert(Types, Index, Type)
	
	self.Size = Size
	self.Count = Count
	
	return true
end

function Table:Remove(Index)
	local Data, Types, Size = self.Data, self.Types, self.Size
	local OldVal, OldTyp = Data[Index], Types[Index]
	
	if OldVal then
		Size = Size - 1
		self.Count = self.Count - 1
	end
	
	if OldVal and OldTyp == "t" then
		Size = Size - OldVal.Size
	end
	
	Data[Index] = nil
	Types[Index] = nil
	self.Size = Size
	
	return OldVal, OldTyp
end

/*==============================================================================================
	Section: Core Operator
	Purpose: Support for the table syntax!
	Creditors: Rusketh
==============================================================================================*/
E_A:SetCost(EA_COST_NORMAL)

E_A:RegisterOperator("table", "", "t", function(self, Keys, Values)
	-- Purpose: Builds a table.
	
	local Table = NewTable()
	
	for I = 1, #Values do
		self.Perf = self.Perf + EA_COST_NORMAL
		local Value, Type = Values[I](self)
		local Key = Keys[I]
		
		if Key then
			Table:Set(Key(self), Type, Value)
		else
			Table:Insert(nil, Type, Value)
		end
	end
	
	return Table
end)

/*==============================================================================================
	Section: Variable Operators
	Purpose: Storing to memory.
	Creditors: Rusketh
==============================================================================================*/
E_A:SetCost(EA_COST_CHEAP)

E_A:RegisterOperator("assign", "t", "", function(self, ValueOp, Memory)
	-- Purpose: Assigns a string to memory
	
	self.Memory[Memory] = ValueOp(self)
end)

E_A:RegisterOperator("variabel", "t", "t", function(self, Memory)
	-- Purpose: Assigns a string to memory
	
	return self.Memory[Memory]
end)

/*==============================================================================================
	Section: Table Operators
	Purpose: Basic operations.
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterOperator("lengh", "t", "n", function(self, Value)
	-- Purpose: Gets the highest numric index
	
	local Data = Value(self).Data
	if !Data then return 0 else return #Data end
end)

E_A:RegisterOperator("is", "t", "n", function(self, Value)
	-- Purpose: Gets the highest numric index
	
	local Data = Value(self).Data
	if !Data or #Data == 0 then return 0 else return 1 end
end)

E_A:RegisterOperator("not", "t", "n", function(self, Value)
	-- Purpose: Gets the highest numric index
	
	local Data = Value(self).Data
	if !Data or #Data == 0 then return 1 else return 0 end
end)

/*==============================================================================================
	Section: Table Functions
	Purpose: Basic operations.
	Creditors: Rusketh
==============================================================================================*/
E_A:RegisterFunction("size", "t:", "n", function(self, Value)
	return Value(self).Size or 0
end)

E_A:RegisterFunction("count", "t:", "n", function(self, Value)
	return Value(self).Count or 0
end)

E_A:RegisterFunction("lengh", "t:", "n", function(self, Value)
	local Data = Value(self).Data
	if !Data then return 0 else return #Data end
end)

E_A:RegisterFunction("copy", "t:", "t", function(self, Value)
	local Table = Value(self)
	
	self.Perf = self.Perf - (Table.Size * 0.5)
	
	return setmetatable({
		Data = TableCopy( Table.Data ),
		Types = TableCopy( Table.Types ),
		Size = Table.Size, Count = Table.Count },
	Table) -- We copyed the table!
end)

/*==============================================================================================
	Section: Indexing Operators
	Purpose: Getters and Setters.
	Creditors: Rusketh
==============================================================================================*/
E_A.API.AddHook("PostLoadCustom", "tables", function()
	for Type, tTable in pairs(E_A.TypeShorts) do
		
		MsgN("Adding table support for: " .. E_A.GetLongType(Type))
		
		-- Get Number Index
		E_A:RegisterOperator("get", "tn" .. Type, Type, function(self, ValueA, ValueB)
			local Table, Index = ValueA(self), ValueB(self)
			if !Table.Data then self:Error("Attempt to index feild " .. tostring(Index) .. " on invalid table.") end
			
			local tIndex = Table.Types[Index]
			if !tIndex and Type == "t" then self:Error("Attempt to reach invalid table at index " .. tostring(Index) .. ".")
			elseif !tIndex or tIndex != Type then return tTable[3](self) end -- Default value!
			
			return Table.Data[Index]
		end)
		
		-- Get String Index
		E_A:RegisterOperator("get", "ts" .. Type, Type, function(self, ValueA, ValueB)
			local Table, Index = ValueA(self), ValueB(self)
			if !Table.Data then self:Error("Attempt to index feild " .. tostring(Index) .. " on invalid table.") end
			
			local tIndex = Table.Types[Index]
			if !tIndex and Type == "t" then self:Error("Attempt to reach invalid table at index " .. tostring(Index) .. ".")
			elseif !tIndex or tIndex != Type then return tTbale[3](self) end -- Default value!
			
			return Table.Data[Index]
		end)
		
		-- Get Entity Index
		E_A:RegisterOperator("get", "te" .. Type, Type, function(self, ValueA, ValueB)
			local Table, Index = ValueA(self), ValueB(self)
			if !Table.Data then self:Error("Attempt to index feild " .. tostring(Index) .. " on invalid table.") end
			
			local tIndex = Table.Types[Index]
			if !tIndex and Type == "t" then self:Error("Attempt to reach invalid table at index " .. tostring(Index) .. ".")
			elseif !tIndex or tIndex != Type then return tTable[3](self) end -- Default value!
			
			return Table.Data[Index]
		end)
		
		/*****************************************************************************************************************************/
		
		-- Set Number Index
		E_A:RegisterOperator("set", "tn" .. Type, "", function(self, ValueA, ValueB, ValueC)
			local Table, Index = ValueA(self), ValueB(self)
			MsgN("Table is -> " .. tostring(Table))
			if !Table.Data then self:Error("Attempt to index feild " .. tostring(Index) .. " on invalid table.") end
			
			if !Table:Set(Index, Type, ValueC(self)) then self:Error("Maxamum table size exceeded.") end
		end)
		
		-- Set String Index
		E_A:RegisterOperator("set", "ts" .. Type, "", function(self, ValueA, ValueB, ValueC)
			local Table, Index = ValueA(self), ValueB(self)
			if !Table.Data then self:Error("Attempt to index feild " .. tostring(Index) .. " on invalid table.") end
			
			if !Table:Set(Index, Type, ValueC(self)) then self:Error("Maxamum table size exceeded.") end
		end)
		
		-- Set Entity Index
		E_A:RegisterOperator("set", "te" .. Type, "", function(self, ValueA, ValueB, ValueC)
			local Table, Index = ValueA(self), ValueB(self)
			if !Table.Data then self:Error("Attempt to index feild " .. tostring(Index) .. " on invalid table.") end
			
			if !Table:Set(Index, Type, ValueC(self)) then self:Error("Maxamum table size exceeded.") end
		end)
	end
end)





