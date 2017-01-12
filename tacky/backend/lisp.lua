local _libs = {}
local _temp = (function()
	-- base is an internal version of core methods without any extensions or assertions.
	-- You should not use this unless you are building core libraries.

	-- Native methods in base should do the bare minimum: you should try to move as much
	-- as possible to Urn

	local pprint = require "tacky.pprint"

	local randCtr = 0
	return {
		['=='] = function(x, y) return x == y end,
		['~='] = function(x, y) return x ~= y end,
		['<'] = function(x, y) return x < y end,
		['<='] = function(x, y) return x <= y end,
		['>'] = function(x, y) return x > y end,
		['>='] = function(x, y) return x >= y end,

		['+'] = function(x, y) return x + y end,
		['-'] = function(x, y) return x - y end,
		['*'] = function(x, y) return x * y end,
		['/'] = function(x, y) return x / y end,
		['%'] = function(x, y) return x % y end,
		['^'] = function(x, y) return x ^ y end,
		['..'] = function(x, y) return x .. y end,

		['get-idx'] = rawget,
		['set-idx!'] = rawset,
		['slice'] = function(xs, start, finish)
			if not finish then finish = xs.n end
			return { tag = "list", n = finish - start + 1, table.unpack(xs, start, finish) }
		end,

		['print!'] = print,
		['pretty'] = function (x) return pprint.tostring(x, pprint.nodeConfig) end,
		['error!'] = error,
		['type#'] = type,
		['empty-struct'] = function() return {} end,
		['format'] = string.format,
		['xpcall'] = xpcall,
		['traceback'] = debug.traceback,
		['require'] = require,
		['string->number'] = tonumber,
		['number->string'] = tostring,

		['gensym'] = function(name)
			if name then
				name = "_" .. tostring(name)
			else
				name = ""
			end

			randCtr = randCtr + 1
			return { tag = "symbol", contents = ("r_%d%s"):format(randCtr, name) }
		end,
	}

end)() 
for k, v in pairs(_temp) do _libs[k] = v end
local _temp = (function()
	return {
		byte    = string.byte,
		char    = string.char,
		concat  = table.concat,
		find    = function(text, pattern, offset, plaintext)
			local start, finish = string.find(text, pattern, offset, plaintext)
			if start then
				return { tag = "list", n = 2, start, finish }
			else
				return nil
			end
		end,
		format  = string.format,
		lower   = string.lower,
		reverse = string.reverse,
		rep     = string.rep,
		replace = string.gsub,
		sub     = string.sub,
		upper   = string.upper,

		['#s']   = string.len,
	}

end)() 
for k, v in pairs(_temp) do _libs[k] = v end

_e_61__61_1 = _libs["=="]
_e_126__61_1 = _libs["~="]
_e_60_1 = _libs["<"]
_e_60__61_1 = _libs["<="]
_e_62_1 = _libs[">"]
_e_62__61_1 = _libs[">="]
_e_43_1 = _libs["+"]
_e_45_1 = _libs["-"]
_e_37_1 = _libs["%"]
_e_46__46_1 = _libs[".."]
_eget_45_idx1 = _libs["get-idx"]
_eset_45_idx_33_1 = _libs["set-idx!"]
format1 = _libs["format"]
_eerror_33_1 = _libs["error!"]
_etype_35_1 = _libs["type#"]
_eempty_45_struct1 = _libs["empty-struct"]
_enumber_45__62_string1 = _libs["number->string"]
_e_35_1 = (function(xs2)
	return _eget_45_idx1(xs2, "n")
end);
_e_33_1 = (function(expr1)
	if expr1 then
		return false
	else
		return true
	end
end);
_ekey_63_1 = (function(x9)
	return _e_61__61_1(type1(x9), "key")
end);
type1 = (function(val1)
	local ty2
	ty2 = _etype_35_1(val1)
	if _e_61__61_1(ty2, "table") then
		local tag1
		tag1 = _eget_45_idx1(val1, "tag")
		if tag1 then
			return tag1
		else
			return "table"
		end
	else
		return ty2
	end
end);
nth1 = (function(li4, idx1)
	local r_51
	r_51 = type1(li4)
	if _e_126__61_1(r_51, "list") then
		_eerror_33_1(format1("bad argment %s (expected %s, got %s)", "li", "list", r_51), 2)
	else
	end
	local r_191
	r_191 = type1(idx1)
	if _e_126__61_1(r_191, "number") then
		_eerror_33_1(format1("bad argment %s (expected %s, got %s)", "idx", "number", r_191), 2)
	else
	end
	return _eget_45_idx1(li4, idx1)
end);
_e_35_2 = (function(li8)
	local r_71
	r_71 = type1(li8)
	if _e_126__61_1(r_71, "list") then
		_eerror_33_1(format1("bad argment %s (expected %s, got %s)", "li", "list", r_71), 2)
	else
	end
	return _e_35_1(li8)
end);
car2 = (function(li3)
	return nth1(li3, 1)
end);
_epush_45_cdr_33_1 = (function(li9, val2)
	local r_101
	r_101 = type1(li9)
	if _e_126__61_1(r_101, "list") then
		_eerror_33_1(format1("bad argment %s (expected %s, got %s)", "li", "list", r_101), 2)
	else
	end
	local len1
	len1 = _e_43_1(_e_35_1(li9), 1)
	_eset_45_idx_33_1(li9, "n", len1)
	_eset_45_idx_33_1(li9, len1, val2)
	return li9
end);
_enil_63_1 = (function(li7)
	return _e_61__61_1(_e_35_2(li7), 0)
end);
rep1 = _libs["rep"]
sub1 = _libs["sub"]
_e_35_s1 = _libs["#s"]
struct1 = (function(...)
	local keys3 = table.pack(...) keys3.tag = "list"
	if _e_61__61_1(_e_37_1(_e_35_2(keys3), 1), 1) then
		_eerror_33_1("Expected an even number of arguments to struct", 2)
	else
	end
	local contents1, out2
	contents1 = (function(key3)
		return sub1(_eget_45_idx1(key3, "contents"), 2)
	end);
	out2 = _eempty_45_struct1()
	local r_711
	r_711 = _e_35_1(keys3)
	local r_721
	r_721 = 2
	local r_691
	r_691 = nil
	r_691 = (function(r_701)
		local _temp
		if _e_60_1(0, 2) then
			_temp = _e_60__61_1(r_701, r_711)
		else
			_temp = _e_62__61_1(r_701, r_711)
		end
		if _temp then
			local i3
			i3 = r_701
			local key4, val3
			key4 = _eget_45_idx1(keys3, i3)
			val3 = _eget_45_idx1(keys3, _e_43_1(1, i3))
			_eset_45_idx_33_1(out2, (function()
				if _ekey_63_1(key4) then
					return contents1(key4)
				else
					return key4
				end
			end)(), val3)
			return r_691(_e_43_1(r_701, r_721))
		else
		end
	end);
	r_691(1)
	return out2
end);
fail1 = (function(msg1)
	return _eerror_33_1(msg1, 0)
end);
_e_61_1 = (function(x10, y1)
	return _e_61__61_1(x10, y1)
end);
succ1 = (function(x11)
	return _e_43_1(1, x11)
end);
pred1 = (function(x12)
	return _e_45_1(x12, 1)
end);
_eappend_33_1 = (function(writer1, text1)
	local r_951
	r_951 = type1(text1)
	if _e_126__61_1(r_951, "string") then
		_eerror_33_1(format1("bad argment %s (expected %s, got %s)", "text", "string", r_951), 2)
	else
	end
	if _eget_45_idx1(writer1, "tabs-pending") then
		_eset_45_idx_33_1(writer1, "tabs-pending", false)
		_epush_45_cdr_33_1(_eget_45_idx1(writer1, "out"), rep1("\t", _eget_45_idx1(writer1, "indent")))
	else
	end
	return _epush_45_cdr_33_1(_eget_45_idx1(writer1, "out"), text1)
end);
_eline_33_1 = (function(writer2, text2)
	if text2 then
		_eappend_33_1(writer2, text2)
	else
	end
	if _eget_45_idx1(writer2, "tabs-pending") then
	else
		_eset_45_idx_33_1(writer2, "tabs-pending", true)
		return _epush_45_cdr_33_1(_eget_45_idx1(writer2, "out"), "\n")
	end
end);
_eindent_33_1 = (function(writer3)
	return _eset_45_idx_33_1(writer3, "indent", succ1(_eget_45_idx1(writer3, "indent")))
end);
_eunindent_33_1 = (function(writer4)
	return _eset_45_idx_33_1(writer4, "indent", pred1(_eget_45_idx1(writer4, "indent")))
end);
_eestimate_45_length1 = (function(node1, max1)
	local tag2
	tag2 = _eget_45_idx1(node1, "tag")
	if (function(r_831)
		if r_831 then
			return r_831
		else
			local r_841
			r_841 = _e_61_1(tag2, "number")
			if r_841 then
				return r_841
			else
				local r_851
				r_851 = _e_61_1(tag2, "symbol")
				if r_851 then
					return r_851
				else
					return _e_61_1(tag2, "key")
				end
			end
		end
	end)(_e_61_1(tag2, "string")) then
		return _e_35_s1(_enumber_45__62_string1(_eget_45_idx1(node1, "contents")))
	elseif _e_61_1(tag2, "list") then
		local sum1
		sum1 = 2
		local i4
		i4 = 1
		local r_991
		r_991 = nil
		r_991 = (function()
			if (function(r_1001)
				if r_1001 then
					return _e_60__61_1(i4, _e_35_2(node1))
				else
					return r_1001
				end
			end)(_e_60__61_1(sum1, max1)) then
				sum1 = _e_43_1(sum1, _eestimate_45_length1(nth1(node1, i4), _e_45_1(max1, sum1)))
				if _e_62_1(i4, 1) then
					sum1 = _e_43_1(sum1, 1)
				else
				end
				i4 = _e_43_1(i4, 1)
				return r_991()
			else
			end
		end);
		r_991()
		return sum1
	else
		return fail1(_e_46__46_1("Unknown tag ", tag2))
	end
end);
expression1 = (function(node2, writer5)
	local tag3
	tag3 = _eget_45_idx1(node2, "tag")
	if (function(r_861)
		if r_861 then
			return r_861
		else
			local r_871
			r_871 = _e_61_1(tag3, "number")
			if r_871 then
				return r_871
			else
				local r_881
				r_881 = _e_61_1(tag3, "symbol")
				if r_881 then
					return r_881
				else
					return _e_61_1(tag3, "key")
				end
			end
		end
	end)(_e_61_1(tag3, "string")) then
		return _eappend_33_1(writer5, _enumber_45__62_string1(_eget_45_idx1(node2, "contents")))
	elseif _e_61_1(tag3, "list") then
		_eappend_33_1(writer5, "(")
		if _enil_63_1(node2) then
			return _eappend_33_1(writer5, ")")
		else
			local newline1, max2
			newline1 = false
			max2 = _e_45_1(60, _eestimate_45_length1(car2(node2), 60))
			expression1(car2(node2), writer5)
			if _e_60__61_1(max2, 0) then
				newline1 = true
				_eindent_33_1(writer5)
			else
			end
			local r_1031
			r_1031 = _e_35_2(node2)
			local r_1041
			r_1041 = 1
			local r_1011
			r_1011 = nil
			r_1011 = (function(r_1021)
				local _temp
				if _e_60_1(0, 1) then
					_temp = _e_60__61_1(r_1021, r_1031)
				else
					_temp = _e_62__61_1(r_1021, r_1031)
				end
				if _temp then
					local i5
					i5 = r_1021
					local entry1
					entry1 = nth1(node2, i5)
					if (function(r_1051)
						if r_1051 then
							return _e_62_1(max2, 0)
						else
							return r_1051
						end
					end)(_e_33_1(newline1)) then
						max2 = _e_45_1(max2, _eestimate_45_length1(entry1, max2))
						if _e_60__61_1(max2, 0) then
							newline1 = true
							_eindent_33_1(writer5)
						else
						end
					else
					end
					if newline1 then
						_eline_33_1(writer5)
					else
						_eappend_33_1(writer5, " ")
					end
					expression1(entry1, writer5)
					return r_1011(_e_43_1(r_1021, r_1041))
				else
				end
			end);
			r_1011(2)
			if newline1 then
				_eunindent_33_1(writer5)
			else
			end
			return _eappend_33_1(writer5, ")")
		end
	else
		return fail1(_e_46__46_1("Unknown tag ", tag3))
	end
end);
block1 = (function(list1, writer6)
	local r_901
	r_901 = list1
	local r_931
	r_931 = _e_35_2(r_901)
	local r_941
	r_941 = 1
	local r_911
	r_911 = nil
	r_911 = (function(r_921)
		local _temp
		if _e_60_1(0, 1) then
			_temp = _e_60__61_1(r_921, r_931)
		else
			_temp = _e_62__61_1(r_921, r_931)
		end
		if _temp then
			local r_891
			r_891 = r_921
			local node3
			node3 = _eget_45_idx1(r_901, r_891)
			expression1(node3, writer6)
			_eline_33_1(writer6)
			return r_911(_e_43_1(r_921, r_941))
		else
		end
	end);
	return r_911(1)
end);
return struct1("expression", expression1, "block", block1)