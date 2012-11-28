/*==============================================================================================
	Expression Advanced: Lemon Gate Core.
	Purpose: Creates the E_A framework.
	Creditors: Rusketh
================================================================================================	
		Lemon Gate Framework:
			+ Tokenizer
			+ Parser
			+ Compiler
		Based on work by Syranide! (E2)
==============================================================================================*/
local E_A = {
	-- Core:
	TokenTable = {},
	OpTable = {},
	OpTableIdx = {},
	TypeTable = {},
	TypeShorts = {},
	FunctionTable = {},
	FunctionVATable = {},
	OperatorTable = {},
	ValidEvents = {},
	
	-- Api / Misc:
	API = {},
	
	-- Base:
	Tokenizer = {},
	Parser = {},
	Compiler = {}
}

LemonGate = E_A

local SubString = string.sub
local UpperStr = string.upper -- Speed
local FormatStr = string.format -- Speed
local LowerStr = string.lower -- Speed
local ConcatTbl = table.concat -- Speed

local pcall = pcall
local tonumber = tonumber
local setmetatable = setmetatable

-- Thses are default op costs.
EA_COST_CHEAP = 0.5
EA_COST_NORMAL = 1
EA_COST_ABNORMAL = 2.5
EA_COST_EXSPENSIVE = 5

/*==============================================================================================
	Section: Util Funcs
	Purpose: Useful Functions that don't have a better place to be.
	Creditors: Rusketh
==============================================================================================*/
local _type = type
local function type(Value)
	-- Purpose: Basicaly this replaces type but lowercased.
	
	return LowerStr( _type(Value) )
end

/***********************************************************************************************/

function E_A.CheckType(Value, Type, I, AllowNil)
	-- Purpose: Checks the type of a function peramater. This prevents bad code from breaking E_As core!
	
	if (AllowNil and Value == nil) then
		return -- Note: Yep!
	elseif type(Value) ~= Type then
		error( FormatStr("Invalid argument #%i (%s) expected got (%s)", I, Type, type(Value)),3)
	end
end; local CheckType = E_A.CheckType -- Speed

/***********************************************************************************************/

function E_A.LimitString(String, Max)
	-- Purpose: Limit the size of a string and append '...' if the string is to big.
	
	Max = Max or 10
	if #String > Max then
		String = String:sub(1,Max) .. "..."
	end
	
	return String
end; local LimitString = E_A.LimitString -- Speed

/***********************************************************************************************/

E_A.Lua_Func_Cahce = {} -- Store functions
local LFC = E_A.Lua_Func_Cahce

local TableToLua -- Below the following function.
function E_A.ValueToLua(Value,NoTables)
	if !Value then return "NULL" end
	
	local Type = type(Value)
	
	if Type == "number" then
		return Value
	elseif Type == "string" then
		return FormatStr("%q", Value)
	elseif Type == "boolean" then
		return Value and "true" or "false"
	elseif Type == "table" and !NoTables then
		return E_A.TableToLua(Value)
	elseif Type == "function" and !NoTables then
		local Index = #LFC + 1; LFC[ Index ] = Value
		return "E_A.Lua_Func_Cahce[" .. Index .. "]"
	end
end; local ValueToLua = ValueToLua -- Speed

function E_A.TableToLua(Table)
	-- Purpose: Turns a table into a string of lua to rebuild that table.
	-- Todo: String escaping, if required.
	 
	local Lua = "{"
	
	for Key, Value in pairs(Table) do
		local kLua = ValueToLua(Key, true)
		local vLua = ValueToLua(Value)
		
		if !kLua then
			error("TableToLua invalid Key of type " .. type(Key))
		elseif !vLua then
			error("TableToLua invalid Value of type " .. type(Value))
		end
		
		Lua = Lua .. "[" .. kLua .. "] = " .. vLua .. ", "
	end
	
	return Lua .. "}"
end; TableToLua = E_A.TableToLua

/***********************************************************************************************/

if SERVER then

	function E_A.IsFreind(Player, Owner)
		if CPPI and Owner.CPPIGetFriends then
			local Friends = Owner:CPPIGetFriends()
			
			if type( Friends ) == "table" then

				for _,Friend in pairs(friends) do
					if Player == Friend then return true end
				end
			end
		else
			return Player == Owner
		end
	end
	
end
/*==============================================================================================
	Section: Colours
	Purpose: The syntax colours for tokens.
	Creditors: Rusketh, Syranide[E2 Tokeniser]
==============================================================================================*/
E_A_Colour = Color(255, 255, 255)
E_A_Colour_KEYWORD = Color(0, 100, 200)
E_A_Colour_OP = Color(255, 100, 0)
E_A_Colour_STRING = Color(150, 150, 150)
E_A_Colour_NUM = Color(0, 255, 0)
-- Todo: Add more syntax colours!

/*==============================================================================================
	Section: Tokens
	Purpose: List of token names as regs.
	Creditors: Rusketh, Syranide[E2 Tokeniser]
==============================================================================================*/
local Tokens = E_A.TokenTable
local Token = {} -- Base Token

Tokens["token"] = Token
Token.__index = Token

function E_A:CreateToken(Patern, Tag,  Name, Colour)
	-- Purpose: Create a new token.
	
	CheckType(Patern, "string", 1); CheckType(Tag, "string", 2); CheckType(Name, "string", 3)
	
	if Patern == "" then Patern = nil end
	local NewToken = {Patern, Tag, Name or "Unknown Token", Colour or E_A_Colour}
	Tokens[Name] = NewToken
	return setmetatable(NewToken, Token)
end

-- Number Tokens
E_A:CreateToken("^0x[%x]+", "num", "hex", E_A_Colour_NUM)

E_A:CreateToken("^0b[01]+", "num", "bin", E_A_Colour_NUM)

E_A:CreateToken("^%d+%.?%d*", "num", "real", E_A_Colour_NUM)

-- Function and variabels
E_A:CreateToken("^%u[%a%d_]*", "var", "variable", E_A_Colour_KEYWORD)

E_A:CreateToken("^%l[%a%d_]*", "fun", "function", E_A_Colour_KEYWORD)

E_A:CreateToken("", "str", "string", E_A_Colour_STRING)

-- Keyword Tokens
E_A:CreateToken("if", "if", "if", E_A_Colour_KEYWORD)

E_A:CreateToken("elseif", "eif", "else if", E_A_Colour_KEYWORD)

E_A:CreateToken("else", "els", "else", E_A_Colour_KEYWORD)

E_A:CreateToken("while", "whl", "while", E_A_Colour_KEYWORD)

E_A:CreateToken("for", "for", "for", E_A_Colour_KEYWORD)

E_A:CreateToken("function", "func", "function constructor", E_A_Colour_KEYWORD)

E_A:CreateToken("switch", "swh", "switch", E_A_Colour_KEYWORD)

E_A:CreateToken("event", "evt", "event constructor", E_A_Colour_KEYWORD)

-- E_A:CreateToken("catch", "cth", "catch", E_A_Colour_KEYWORD) -- Unused!

-- Sub KeyWords
E_A:CreateToken("break", "brk", "break", E_A_Colour_KEYWORD)

E_A:CreateToken("continue", "cnt", "continue", E_A_Colour_KEYWORD)

E_A:CreateToken("return", "ret", "return", E_A_Colour_KEYWORD)

E_A:CreateToken("error", "err", "error", E_A_Colour_KEYWORD)

-- Decleration KeyWords
E_A:CreateToken("global", "glob", "global", E_A_Colour_KEYWORD)

E_A:CreateToken("input", "in", "input", E_A_Colour_KEYWORD)

E_A:CreateToken("output", "out", "output", E_A_Colour_KEYWORD)

E_A:CreateToken("persist", "per", "persist", E_A_Colour_KEYWORD)

-- Op's
local Ops = {

	-- Maths
	E_A:CreateToken("+", "add", "addition", E_A_Colour_OP),

	E_A:CreateToken("-", "sub", "subtract", E_A_Colour_OP),

	E_A:CreateToken("*", "mul", "multiplyer", E_A_Colour_OP),

	E_A:CreateToken("/", "div", "division", E_A_Colour_OP),

	E_A:CreateToken("%", "mod", "modulus", E_A_Colour_OP),

	E_A:CreateToken("^", "exp", "power", E_A_Colour_OP),

	E_A:CreateToken("=", "ass", "assign", E_A_Colour_OP),

	E_A:CreateToken("+=", "aadd", "increase", E_A_Colour_OP),

	E_A:CreateToken("-=", "asub", "decrease", E_A_Colour_OP),

	E_A:CreateToken("*=", "amul", "multiplyer", E_A_Colour_OP),

	E_A:CreateToken("/=", "adiv", "division", E_A_Colour_OP),

	E_A:CreateToken("++", "inc", "increment", E_A_Colour_OP),

	E_A:CreateToken("--", "dec", "decrement", E_A_Colour_OP),
	
	-- Comparison
	E_A:CreateToken("==", "eq", "equal", E_A_Colour_OP),

	E_A:CreateToken("!=", "neq", "unequal", E_A_Colour_OP),

	E_A:CreateToken("<", "lth", "less", E_A_Colour_OP),

	E_A:CreateToken("<=", "leq", "less or equal", E_A_Colour_OP),

	E_A:CreateToken(">", "gth", "greater", E_A_Colour_OP),

	E_A:CreateToken(">=", "geq", "greater or equal", E_A_Colour_OP),
	
	-- Bitwise
	E_A:CreateToken("&", "band", "and", E_A_Colour_OP),

	E_A:CreateToken("|", "bor", "or", E_A_Colour_OP),

	E_A:CreateToken("^^", "bxor", "or", E_A_Colour_OP),

	E_A:CreateToken(">>", "bshr", ">>", E_A_Colour_OP),

	E_A:CreateToken("<<", "bshl", "<<", E_A_Colour_OP),

	-- Condition
	E_A:CreateToken("!", "not", "not", E_A_Colour_OP),

	E_A:CreateToken("&&", "and", "and", E_A_Colour_OP),
	
	E_A:CreateToken("||", "or", "or", E_A_Colour_OP),

	-- Symbols
	E_A:CreateToken("?", "qsm", "?", E_A_Colour_OP),
	
	E_A:CreateToken(":", "col", "colon", E_A_Colour_OP),

	-- E_A:CreateToken("?:", "def", "?:", E_A_Colour_OP),

	E_A:CreateToken(",", "com", "comma", E_A_Colour_OP),
	
	-- E_A:CreateToken("$", "dol", "dolla", E_A_Colour_OP),
	
	E_A:CreateToken("~", "dlt", "delta", E_A_Colour_OP),
	
	E_A:CreateToken("#", "len", "length", E_A_Colour_OP),
	
	-- E_A:CreateToken("->", "imp", "->", E_A_Colour_OP),
	
	
	-- Brackets
	E_A:CreateToken("(", "lpa", "left parenthesis", E_A_Colour_OP),
	
	E_A:CreateToken(")", "rpa", "right parenthesis", E_A_Colour_OP),
	
	E_A:CreateToken("{", "lcb", "left curly bracket", E_A_Colour_OP),
	
	E_A:CreateToken("}", "rcb", "right curly bracket", E_A_Colour_OP),
	
	E_A:CreateToken("[", "lsb", "left square bracket", E_A_Colour_OP),
	
	E_A:CreateToken("]", "rsb", "right square bracket", E_A_Colour_OP),
	
	-- Misc
	-- E_A:CreateToken("...", "vargs", "varargs", E_A_Colour_OP) -- Unused!
}

-- Convert Op Tokens to Opt Table
local OpTable = E_A.OpTable

for I = 1, #Ops do
	local Op = Ops[I]
	OpTable[ Op[1] ] = Op
end 

table.sort(Ops, function(Token, Token2) return #Token[1] > #Token2[1] end)

E_A.OpTableIdx = Ops

/*==============================================================================================
	Section: Type Creators
	Purpose: This is where the functions to register types is made.
	Creditors: Rusketh
==============================================================================================*/
local Types, Shorts = E_A.TypeTable, E_A.TypeShorts

function E_A:RegisterClass(Name, Short, Default)
	-- Purpose: Create a new class.

	CheckType(Name, "string", 1); CheckType(Short, "string", 2)
	Name = LowerStr(Name); Short = LowerStr(Short) -- These must be lowercased or else we could get confused.
	
	local Type = {Name, Short}
	Types[ Name ] = Type
	Shorts[ Short ] = Type
	
	if type(Default) == "function" then
		Type[3] = Default
	else -- Now we create a function that can return a deafult of this type =D
		RunString("LemonGate.TypeTable['" .. Name .. "'][3] = function() return " .. self.ValueToLua(Default) .. " end")
	end
end

/*==============================================================================================
	Section: E_A Type converter 
	Purpose: Convert longtypes to shorttypes and vice versa 
	Creditors: Oskar 
==============================================================================================*/
function E_A.IsType( Type )
	CheckType( Type, "string", 1 ); Type = LowerStr( Type )

	local out = Types[Type] or Shorts[Type] or nil 
	return out and true or false
end

function E_A.GetShortType( Type )
	CheckType( Type, "string", 1 ); Type = LowerStr( Type )
	
	if !Type or Type == "" or Type == "void" then return "" end
	
	local Out = Types[Type] or Shorts[Type]
	if Out then return Out[2] end
	
	debug.Trace()
	
	error("Can not find Type of " .. Type)
	
end; local GetShortType = E_A.GetShortType

function E_A.GetLongType( Type )
	CheckType( Type, "string", 1 ); Type = LowerStr( Type )
	
	if !Type or Type == "" or Type == "void" then return "void" end
	
	local Out = Types[Type] or Shorts[Type] 
	if Out then return Out[1] end
	
	
	debug.Trace()
	
	error("Can not find Type of " .. Type)
	
end; local GetLongType = E_A.GetLongType

/*==============================================================================================
	Section: E_A Operators
	Purpose: TOOOODOOOOOO.
	Creditors: Rusketh
==============================================================================================*/
local OpCost = 10 -- Aprox

function E_A:SetCost(Value)
	-- Purpose: Sets the Cost of the next operator or function
	
	CheckType(Value, "number", 1)
	OpCost = Value
end

/*==============================================================================================
	Section: E_A Functions
	Purpose: The default and overloadable functions.
	Creditors: Rusketh
==============================================================================================*/
local Functions = E_A.FunctionTable

function E_A:RegisterFunction(Name, Params, Return, Function)
	-- Purpose: Creates a new E_A functions for you to call.
	
	CheckType(Name, "string", 1); CheckType(Return or "", "string", 3); CheckType(Function, "function", 4)
	
	local typeData = Params
	if type(Params) == "table" then 
		typeData = ""
		for i=1,#Params do
			typeData = typeData .. GetShortType( Params[i] )
		end
	end
	
	Functions[ Name .. "(" .. typeData .. ")" ] = {Function, GetShortType(Return), OpCost}
end

/*==============================================================================================
	Section: E_A Operators
	Purpose: Operators allow 4 + 4 to make 8
	Creditors: Rusketh
==============================================================================================*/
local Operators = E_A.OperatorTable

function E_A:RegisterOperator(Name, Params, Return, Function)
	-- Purpose: Creates a new E_A operator for you to use.
	
	CheckType(Name, "string", 1); CheckType(Return or "", "string", 3); CheckType(Function, "function", 4)
	
	local typeData = Params
	if type(Params) == "table" then 
		typeData = ""
		for i=1,#Params do
			typeData = typeData .. GetShortType( Params[i] )
		end
	end
	
	Operators[ Name .. "(" .. typeData .. ")" ] = {Function, GetShortType(Return), OpCost}
end

function E_A:WireModClass(Class, Name, In, Out)
	-- Purpose: Makes a class compatable with wiremod.
	
	CheckType(Class, "string", 1); CheckType(Name, "string", 2); CheckType(In, "function", 3, true); CheckType(Out, "function", 4, true)
	
	local Type = Types[Class] -- Note: Check to see if this type exists.
	if !Type then error("unkown class '" .. Class .. "'", 0) end
	
	Type[4] = UpperStr(Name)
	Type[5] = In
	Type[6] = Out
end

/* These are not used!
function E_A:AddClassFactory(Name, Factory)
	-- Purpose: Makes a class factory for on the fly object creaton.
	
	CheckType(Class, "string", 1); CheckType(Factory, "function", 2)
	
	local Type = Types[Class] -- Note: Check to see if this type exists.
	if !Type then error("unkown class '" .. Class .. "'", 0) end
	
	Type[7] = Factory
end

function E_A:ClassFactory(Type, ...)
	local Type = Types[Class] -- Note: Check to see if this type exists.
	if !Type then error("unkown class '" .. Class .. "'", 0) end
	
	local Factory = Type[7]
	if !Factory then error("class '" .. Class .. "' has no builder factory", 0) end
	
	return Factory(...)
end */

/*==============================================================================================
	Section: Hook Registery.
	Purpose: Valid Hooks.
	Creditors: Rusketh
==============================================================================================*/
local Events = E_A.ValidEvents

function E_A:RegisterEvent(Name, Params, Return)
	-- Purpose: Creates a new valid E_A hook.
	
	CheckType(Name, "string", 1); CheckType(Return or "", "string", 3);
	
	local typeData = Params or ""
	if type(Params) == "table" then 
		typeData = ""
		for i=1,#Params do
			typeData = typeData .. GetShortType( Params[i] )
		end
	end
	
	Events[ Name ] = {typeData, Return}
end

/*==============================================================================================
	Section: Script Context
	Creditors: Rusketh
==============================================================================================*/
local Context = {}
E_A.Context = Context
Context.__index = Context

function Context:Throw(Exeption, ...)
	self.Exception = Exeption
	self.ExceptionInfo = {...}
	error("Exception", 0)
end

function Context:Error(Message, Info, ...)
	if Info then Message = FormatStr(Message, Info, ...) end
	self:Throw("script", Message)
end

/*==============================================================================================
	Section: Instruction Operators
	Purpose: Runable operators.
	Creditors: Rusketh
==============================================================================================*/
local Operator = {}
E_A.Operator = Operator

Operator.__index = Operator

function E_A.CallOp(Op, self, Arg, ...)
	-- Purpose: Makes Operators callable and handels runtime perf.
	
	local Perf = self.Perf - (Op[0] or EA_COST_NORMAL)
	
	self.Perf = Perf
	
	if Perf < 0 then self:Throw("script", "Execution Limit Reached") end
	
	local Trace = self.Trace
	
	self.Trace = Op[4] -- Replace parent trace with child trace.
	
	local Perams, Res, Type = Op[3]
	
	if Arg then Perams = {Arg, ...} end -- Use custom peramaters!
	
	if !Perams or #Perams == 0 then
		Res, Type = Op[1](self) -- No perams!
	elseif #Perams < 20 then
		-- Unpack is slow so lets avoid it!
		local A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T = Perams[1], Perams[2], Perams[3], Perams[4], Perams[5], Perams[6], Perams[7], Perams[8], Perams[9], Perams[10], Perams[11], Perams[12], Perams[13], Perams[14], Perams[15], Perams[16], Perams[17], Perams[18], Perams[19], Perams[20]
		Res, Type = Op[1](self, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T)
	else
		Res, Type = Op[1](self, unpack(Perams)) -- More then 20 perams!
	end
	
	self.Trace = Trace
	
	return Res, (Type or Op[2])
end 

local CallOp = E_A.CallOp
Operator.__call = E_A.CallOp

function Operator:SetCost(Cost)
	-- Purpose: Sets the coast of an operator.
	
	self[0] = Cost or COST_NORMAL
	return self -- Note: We return self (Read code to see why).
end

function Operator:ReturnType(Long)
	-- Purpose: Used to get the static return type.
	
	if Long then return GetLongType(self[2]) end
	return self[2] or ""
end

function E_A.SafeCall(Op, self, ...)
	-- Purpose: Calls the operator safly and handels exceptions.
	
	local Ok, Result, Type = pcall(CallOp, Op, self, ...)
	
	if !Ok and Result == "Exception" then
		return false, self.Exception, unpack(self.ExceptionInfo)
	end
	
	return Ok, Result, Type
end

Operator.SafeCall = E_A.SafeCall

function E_A.ValueToOp(Value, Type)
	-- Purpose: Can instantly convert values to operator values.
	
	return setmetatable({function() return Value, Type end, [2] = Type}, Operator)
end