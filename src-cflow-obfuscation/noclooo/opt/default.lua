for i = 1, 10 do
  if i > 5 then
    print "I am ass."
  end
end

if true or 'IfExprCondition2' and 'IfExprCondition3' then
	print 'IfExprClause1'
else
	print 'IfExprClause2'
end

local tableWithAMemeyVariableName = {
	tableFunction = function(argument)
	end
}

local function localSyntacticSugaryFunction()
end

function tableWithAMemeyVariableName:selfFunction()
end

local basicFunctionExpressionOneArg = function(anArgument)
	do end
end

function variadicFunctionExpressionWithSyntacticSugar(...)
end

local basicFunctionWithNoArguments = function()
end

local emptyVariableToTestConstantFolding = 'Food'

basicFunctionWithNoArguments()
basicFunctionExpressionOneArg('a')
