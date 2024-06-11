return function(request)
    local ok, value = pcall(function()
        if request.hint == "image" or request.hint == "imagedata" then
            return love.image.newImageData(request.filepath)
            
        elseif request.hint == "source" then
            return love.audio.newSource(request.filepath, request.args[1])
        end

        error("Unknown type hint: "..request.hint)
    end)

    return {success = ok, value = value}
end