local co = coroutine

function async(f)
    return function(...)
        local params = table.pack(...)
        local thread = co.create(function()
            return f(table.unpack(params, 1, params.n))
        end)

        return function(cb)
            local step = nil
            step = function(...)
                local result = table.pack(co.resume(thread, ...))

                if co.status(thread) == "dead" then
                    (cb or function() end)(table.unpack(result, 2, result.n))
                else
                    local f = result[2]
                    assert(type(f) == "function", "type error :: expected func")
                    f(step)
                end
            end
            step()
        end
    end
end

function wrap(f)
    return function(...)
        local params = table.pack(...)
        return function(cb)
            table.insert(params, params.n + 1, cb)
            f(table.unpack(params, 1, params.n + 1))
        end
    end
end

function await(thunk)
    return co.yield(thunk)
end

function await_all(...)
    return co.yield(join({...}))
end

function join(thunks)
    local total = #thunks

    local finished = 0
    local result = {}

    return function(cb)
        if total == 0 then
            cb()
            return
        end

        for i, thunk in ipairs(thunks) do
            thunk(function(...)
                local args = {...}
                if #args <= 1 then
                    result[i] = args[1]
                else
                    result[i] = args
                end

                finished = finished + 1
                if finished == total then
                    cb(table.unpack(result))
                end
            end)
        end
    end
end

function await_race(...)
    return co.yield(race({...}))
end

function race(thunks)
    local finished = false
    return function(cb)
        if #thunks == 0 then
            cb()
            return
        end

        for i, thunk in ipairs(thunks) do
            thunk(function(...)
                if finished then
                    return
                end
                finished = true

                local result = {}
                local args = {...}
                if #args <= 1 then
                    result[i] = args[1]
                else
                    result[i] = args
                end

                cb(result)
            end)
        end
    end
end

return {
    sync = async,
    wait = await,
    wrap = wrap,

    wait_all = await_all,
    wait_race = await_race,
}
