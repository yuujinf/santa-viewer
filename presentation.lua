local Presentation = {}

function Presentation:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function Presentation:initialize()
    assert(self.projectName, "Must provide project name")
    self:loadPresentation(self.projectName)
end

function Presentation:loadPresentation(pn)
    local path = "projects/" .. pn

    self.submissions = {}
    self.participants = {}
    -- Maps senders to their corresponding submission
    self.sendMap = {}
    self.recvMap = {}

    local directories = love.filesystem.getDirectoryItems(path)
    table.sort(directories)
    for i, f in ipairs(directories) do
        local sub = {}
        sub.recipient = string.gsub(f, "%d+-", "")
        local subDirs = { "" }
        sub.items = {}
        while #subDirs > 0 do
            local d = table.remove(subDirs, 1)
            local entries = love.filesystem.getDirectoryItems(path .. "/" .. f .. d)
            table.sort(entries)

            for j, e in ipairs(entries) do
                local info = love.filesystem.getInfo(path .. "/" .. f .. d .. "/" .. e)
                if info.type == "directory" then
                    -- table.insert(subDirs, d .. "/" .. e)
                else
                    if d == "" then
                        local sender = string.match(e, "(%w+)-")
                        if sub.sender ~= nil and sub.sender ~= sender then
                            error("Submission with multiple senders")
                        end
                        sub.sender = sender
                    end
                    table.insert(sub.items, {
                        path = path .. "/" .. f .. d .. "/" .. e
                    })
                end
            end
        end

        print(string.format("%s > %s", sub.sender or "NIL", sub.recipient))
        table.insert(self.submissions, sub)
        table.insert(self.participants, sub.recipient)
        self.sendMap[sub.sender] = sub
        self.recvMap[sub.recipient] = sub
    end
end

function Presentation.load(projectName)
    return Presentation:new({ projectName = projectName })
end

function Presentation:getMedia(subIdx, itemIdx)
    return self.submissions[subIdx].items[itemIdx]
end

function Presentation:numberOfSubmissions()
    return #self.submissions
end

function Presentation:numberOfItems(subIdx)
    return #self.submissions[subIdx].items
end

function Presentation:findSubBySender(sender)
    return self.sendMap[sender]
end

function Presentation:findSubByRecipient(recv)
    return self.recvMap[recv]
end

return Presentation
