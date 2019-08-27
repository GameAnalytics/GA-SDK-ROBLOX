local function readonlytable(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(t, k, v)
                    error("Attempt to modify read-only table: " .. tostring(t) .. ", key=" .. tostring(k) .. ", value=" .. tostring(v))
                  end,
     __metatable = false
   });
end

return readonlytable({
    Start = "Start";
    Complete = "Complete";
    Fail = "Fail";
})
