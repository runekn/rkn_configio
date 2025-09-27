RKN_Configio_Utils = {}

function RKN_Configio_Utils.EscapeGmatch(s)
    return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

function RKN_Configio_Utils.ArrayRemove(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

function RKN_Configio_Utils.ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function RKN_Configio_Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[RKN_Configio_Utils.DeepCopy(orig_key)] = RKN_Configio_Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, RKN_Configio_Utils.DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function RKN_Configio_Utils.AddFixedEmptyRow(table, height)
    local row = table:addRow(nil, { fixed = true })
	row[1]:createText(" ", { fontsize = 1, minRowHeight = height })
end


function RKN_Configio_Utils.ArrayIndexOf(arr, v)
	if not arr then
		return nil
	end
	for i, m in ipairs(arr) do
		if m == v then
			return i
		end
	end
	return nil
end

-- For debugging --
function RKN_Configio_Utils.SerializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. RKN_Configio_Utils.SerializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

function RKN_Configio_Utils.DebugSplit(s)
	if s:len() > 8192 then
		local a = s:sub(1, 8192)
		local b = s:sub(8192)
		DebugError(a)
		RKN_Configio_Utils.DebugSplit(b)
	else
		DebugError(s)
	end
end

function RKN_Configio_Utils.Any(table, f)
	return RKN_Configio_Utils.First(table, f) ~= nil
end

function RKN_Configio_Utils.First(tbl, f)
	for k,v in pairs(tbl) do
		if f(v, k) then
			return {k, v}
		end
	end
	return nil
end

function RKN_Configio_Utils.KeyArray(table)
    local keyset = {}
    local n = 0
    for k,_ in pairs(table) do
        n = n + 1
        keyset[n] = k
    end
    return keyset
end

function RKN_Configio_Utils.FilterArray(table, f)
    local result = {}
    local n = 0
    for _,v in ipairs(table) do
        if f(v) then
            n = n + 1
            result[n] = v
        end
    end
    return result
end