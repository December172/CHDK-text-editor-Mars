--[[
@title Mars - Text Editor
@chdk_version 1.4.1

@subtitle Initial Settings
@param w Width
@default w 45
@range w 30 45
@param h Height
@default h 14
@range h 10 14
@param a Write a new file?
@default a 0
@values a No Yes
@param f Browse file in CHDK/?
@default n 0
@values n No Yes
@param f Browse file in what CHDK/ subdirectory?
@default f 0
@values f <root> SCRIPTS LOGS BOOKS HELP DATA

@subtitle Settings
@param b Do backups?
@default b 0
@values b No Yes
@param s Newline Style?
@default s 0
@values s Unix(\n) Windows(\r\n)
@param g Which character do you want to use on 'tab'?
@default g 0
@values g (space) Windows
@param t How many spaces press the 'tab' hotkey?
@default t 4
@range t 0 8

@subtitle Key Mapping
@param j Have DISP key?
@default j 1
@values j No Yes
@param k Have PLAYBACK?
@default k 0
@values k No Yes
@param l Have VIDEO key?
@default l 0
@values l No Yes

@subtitle HotKey
@param e Use what key for 'tab'?
@default e 1 
@values e DISP PLAYBACK VIDEO

@subtitle Debug
@param c Logging?
@default c 0
@values c No Yes
@param m Experimental Features?(Bugs warning!)
@default m 0
@values m No YES
--]]
-- em,many options...

--[[
    Name:        Mars Text Editor
    Version:     1.2
    Author:      December172
    Licence:     GPL v3+ as well as LGPL 3+;see: http://www.gnu.org/licenses/gpl-3.0.html
                 in order to use with GPL<3: You can also use it with GPL<3 software.    
    Inspired and based on EDI 2 project,see https://chdk.setepontos.com/index.php?topic=6465.0
    Original author of EDI 2: Pawel Tokarz aka outslider
    
    *** This version is still very experimental,so if you found bugs,please REPORT it! ***
    
    If you're experienced with lua coding,please help me to finish these TODOs!
    
    TODO:
        v1.2 - v1.3:
            - Optimize mem use(logic,gc method) and speed(using setfenv() and local requires)
            - Supporting clipboard;
            - Solve screen flashing problem
            - Better 'tab' Hotkey in 'windows' mode(Insert a \9 for 8 spaces,and use spaces when blank not fitting 8 spaces,for write normal text)
            - Extra search feature supporting;
            - Fix bugs in multi-file functions
        v1.3 - v1.4:
            - Module system implementing.(like make a auto-completion module,but will use more mem,can be disabled)
            - Fix bugs in clipboard functions.
      
    Notes: I've only tested this script on my camera (ELPH 180 / IXUS 175),Mars runs OK on it.
            However,not all of cameras have the same things that on my camera,such as a video button or a ~3 MB RAM.
            Also,I haven't a DISP key,nor a DIGIC 5 chip.So maybe this script will look bad on your camera.
            Don't worry,I'm going to try to fit other platforms by options(such as key mapping,width & height changing).
            But wait: multi-file feature is still a little unstable;most of time it runs ok,but sometimes like creating new file it'll crash(not all of the times,just a bug)
            So report your bug that founds in Mars to my publishing post.
]]--

-- Configure Global Variables--
-- Some variables is in local,but not all can do this:I've found some variables will lose if it's a local variable.
-- This seems impossible,but I don't know why.
-- TODO: optimize mem and speed
CR = "\r"
if s == 0 then
    CR = " "
end
tabCharacter = " "
if g == 1 then
    tabCharacter = "\9" -- A windows-style 'tab' character
    t = 1 -- When use windows-style 'tab' it'll be one (because it's length-changeable)
end
HEIGHT = h or 14
WIDTH = w or 45
local EXIT = false
CurrentMode = "Write"
WriteSubMode = 1
JUMPS = {1,5,10,20,30}
JUMP = 1
PosX = 0
PosY = 1
ShiftY = 1
ShiftX = 0
LETTER_NR = 1
WriteKey = 0
local VERSION = "1.2" 
-- Hotkeys,use as least as we can to save more keys for future using
Hotkeys = {
           MenuKey          = "menu",       -- Should fit on all camera
           TabKey           = "playback",   -- Have a option to fit other cameras,see init()
           ChangeSubModeKey = "shoot_full"  -- Same as MenuKey
          }
-- Compressed in on line,'cause it's too big :)
LetterMap = {{{"a","b","c","d","e","f"},{"g","h","i","j","k","l"},{"m","n","o","p","q","r","s"},{"t","u","v","w","x","y","z"}},{{"A","B","C","D","E","F"},{"G","H","I","J","K","L"},{"M","N","O","P","Q","R","S"},{"T","U","V","W","X","Y","Z"}},{{"1","2","3"},{"4","5","6"},{"7","8","9"},{"0","+","-","*","/","="}}}
SpecialCharMap = {{"newline"},{"(",")","[","]","{","}"},{"<",">",",","'",":",";"},{"_","+","-","/","\\","="},{"@","!","?","#","\"","."},{"~","&","*","|","^","`","%"},{"ASCII code"}}
-- This should not in one line because we can see it's struct clearly
-- Easier to add new item.
MenuTabs = {        -- Remember: every sub-menu should have a callback(if menu is "Example menu",the callback is MenuFunctions.Example)! 
            Main = {
                    {"File menu"},
                    {"Edit menu"},
                    {"Settings..."},
                    {"Exit (no save!)"},
                    {"About Mars"}
                   },
            File = {
                    {"New file"},
                    {"Load file..."},
                    {"Save current file"},
                    {"Save and exit"},
                    {"Save as..."},
                    {"Clear whole file"},
                    {"Close current file"},
                    {"Change current file..."}
                   },
            Edit = {
                    {"Search..."}, -- TODO: add more search menu item
                    {"Change current code language..."},
                    {"Merge files..."}
                   },
            Settings = {
                        {"Enable/Disable backup (next save)"},
                        {"Change 'tab' hotkey's spaces"}
                   }
           }
TopBar = ""
StatusBar = ""
Files = {} -- To contain all opening files
CurrentLanguage = "Lua"
-- default Function map,see Functions.map for more information about Function Map
FunctionMaps = {
            Lua = {       -- contains Lua language's pages
                    [1] = {  -- page one's functions
                            {"print()","return","if"},  -- row 1 of page 1
                            {"then","cls()","end"},
                            {"sleep()","wait_click","function"},
                            {"--[[","--]]","else"},
                            {"until","require()","local"},
                            {"repeat","@param","@default"}
                        }
                    -- To add more pages,do like below:
                    -- [2] = { {...},{...}} 
                    -- Here,[2] is the page number,and {...} is the row of a page,3 items in one line.
                },
            -- To add more languages,do <LanguageName> = {[1] = {{...},{...}}, [2] = {{...},{...}}}
            -- As above,<LanguageName> is your language name which will be displayed in change current language menu
            -- [1],[2] are pages,and {...} are rows in pages
            uBasic = {
                    [1] = {
                            {"rem","print","sleep"},
                            {"shoot","wait_click","if"},
                            {"while","is_key","gosub"},
                            {"click","endif","until"},
                            {"set_sv96","set_av96","set_aflock"},
                            {"release","get_mode","goto"}
                          },
                    [2] = {
                            {"@param","@default","@title"},
                            {"@chdk_version"}, -- Note: this string is too long that if we concreate this with other assign it'll deispay wrong,so we should make it in one line
                            {"@subtitle","@values","@ranges"}
                          }
                 }
                }
CurrentFileID = 0
ModeFunctions = {}
MenuFunctions = {}
-- not contains all keys,other keys will be inserted in init()'s key mapping
local KeysTable = {"left","up","right","down","set","shoot_half","shoot_full","menu","zoom_in","zoom_out","erase","shoot_full"} 
local RepeatableKeysTable = {"left","up","right","down","zoom_out","zoom_in"}
local defaultFileDir = "A"
-- Not finished
if m == 1 then
    isClip = false
    Clipboard = {}
    Cilp = ""
end
-- End Configure Global Variables--

-- helpers
function string.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Functions
-- A little thought: most function only use in one place,so maybe we can make them 'inline' (maybe a bit faster),but the code is not easy to understand

-- Except ordinary logs,don't print too much log in a loop - otherwize your log file will be very big and hard to understand.
-- TODO: Changeable log format
function Log(level,text)
    if c == 1 then
        os.mkdir("A/CHDK/LOGS/Mars")
        local logFile,errMsg = io.open("A/CHDK/LOGS/Mars/Mars-"..os.date("%Y-%m-%d")..".log","a")
        if not logFile then
            print_screen(1)
            print("Error opening log file,use print_screen() from now on.")
            print("Error message:"..tostring(errMsg))
            sleep(500)
        end
        logFile:write("["..os.date("%Y/%m/%d %X").."]".."[main-"..string.upper(level).."] "..text.."\n") -- fixed log format
        logFile:flush()
        logFile:close()
    end
end

-- FIXME: If a non-exist key in KeysTable,sometimes it'll crash and throw a 'No key' error,even didn't press any key
function GetInput()
    if PressedTime == nil then PressedTime = get_tick_count() end
    PressedKey = nil
    if (wait_time == nil or wait_time < 0) then wait_time = 0 end
    for key_nr = 1, table.getn(RepeatableKeysTable) do
        if is_pressed(RepeatableKeysTable[key_nr]) then
           PressedKey = RepeatableKeysTable[key_nr] or nil
        end
    end
    if PressedKey ~= nil then
        repeat
            if get_tick_count() - PressedTime > 370 then
               sleep(75)
               return PressedKey
            end
        until not is_pressed(PressedKey)
    end
    wait_click(wait_time)
    PressedTime = get_tick_count()
    for key_nr = 1, table.getn(KeysTable) do
        if is_key(KeysTable[key_nr]) then
          PressedKey = KeysTable[key_nr]
          return KeysTable[key_nr]
        end
    end
    return nil
end

function NewFile()
    PosX = 1
    PosY = 1
    CurrentFileID = CurrentFileID + 1
    Files[CurrentFileID] = { Path = nil,        -- Placeholder,replaced by Save() and SaveAs()
                             Name = "Untitled.txt",
                             isSaved = "S",
                             Content = {""},
                             LineSN = 1,
                             File = newproxy(), -- create a placeholder(FILE * is a userdata,too),for future use
                             Cursor = { x = 1,  -- Important: Saves cursor position in file 
                                        y = 1
                                      }
                           }
    Log("Info","Created a new file.")
end

-- TODO: Add more choices (or controlable choices)
function SelectFileName()
    local saveDirs = {{"A"},{"A/CHDK"},{"A/CHDK/LUALIB"},{"Cancel"}}
    local dirName = Menu(saveDirs,WIDTH,HEIGHT,"Select a directory",20,2)
    if (dirName == "Cancel" or dirName == nil) then return -1 end
    local fileName = textbox("File name", "Enter file name", "Untitled.txt", 24)
    if (type(fileName) == "nil" or file_name == "") then fileName = "Untitled.txt" end
    local outDir = dirName.."/"..fileName
    Files[CurrentFileID].Name = fileName
    Log("Info","Selected current file name to "..fileName)
    return outDir
end

function MakeStringBar(text,width)
    return string.sub(string.sub("-------------------------",26-(width-#(text))/2,25)..text..string.sub("-------------------------",1,(width-#(text))/2),1,width-1)
end

function LoadFile(fileDir)
    local Path = fileDir or defaultFileDir
    local filePath = file_browser(Path)
    if filePath == nil then
        if #Files == 0 then
            print("No file selected!")
            print("Opening a new file.")
            NewFile()
            Log("Warn","No file selected!")
            sleep(300)
        end
    else
        NewFile() -- to create a empty file 
        Files[CurrentFileID].Name = ""
        for li = 0,#(filePath) do
            local char = string.sub(filePath,#(filePath) - li,#(filePath) - li)
            if char ~= "/" then
                Files[CurrentFileID].Name = char..Files[CurrentFileID].Name
                else break
            end
        end
        local rawFile = io.open(filePath,"rb")
        Files[CurrentFileID].Path = filePath
        Log("Info","Loading "..filePath)
        print("Loading, wait...")
        Files[CurrentFileID].File = rawFile:_getfptr() -- gets the real FILE * pointer,replaces the empty placeholder 
        local lineIndex = 1
        repeat
            Files[CurrentFileID].Content[lineIndex] = rawFile:read("*line")
            Files[CurrentFileID].LineSN = lineIndex - 1
            lineIndex = lineIndex + 1
        until Files[CurrentFileID].Content[lineIndex - 1] == nil
        rawFile:close()
        if Files[CurrentFileID].Content[1] == nil then Files[CurrentFileID].Content = {""} end
        if Files[CurrentFileID].LineSN == 0 then Files[CurrentFileID].LineSN = 1 end
        Log("Info","Loaded "..filePath.." Successfully.")
    end
end

-- thinking: maybe make it a interface to support multi-file search and / or Search and Replace?
function SearchInCurrentFile(patternToFind)
    local finds = {}
    -- k is line number,v is the line's string
    for k,v in pairs(Files[CurrentFileID].Content) do
        if string.find(v, patternToFind) then
            table.insert(finds, k..": "..string.trim(v))
        end
    end
    return finds
end

-- TODO: Merge file without opening another one (from Caefix's idea)
-- This function can only merge files in opening file list
function MergeFiles()
    local fileList = {{}}
    for i,j in pairs(Files) do
        if i ~= CurrentFileID then
            table.remove(fileList,1)
            table.insert(fileList,{j.Name})
        end
    end
    local fromFile = Menu(fileList,WIDTH,HEIGHT,"Choose a file to merge",nil,2)
    if fromFile == nil then
        return -1
    end
    local fromFileID = 0
    for k,v in pairs(Files) do
        if v.Name == fromFile and k ~= CurrentFileID then
            fromFileID = k
        end
    end
    local lineIndex = 1
    repeat
        Files[CurrentFileID].Content[Files[CurrentFileID].LineSN + 1] = Files[fromFileID].Content[lineIndex]
        Files[CurrentFileID].LineSN = Files[CurrentFileID].LineSN + 1
        lineIndex = lineIndex + 1
    until Files[fromFileID].Content[lineIndex] == nil
    Files[CurrentFileID].isSaved = "!"
end

-- FIXME: Cursor sometimes is at a wrong place after change file  
function ChangeCurrentFile()
    local fileList = {}
    for _,v in pairs(Files) do
        table.insert(fileList,{v.Name})
    end
    local fileName = Menu(fileList,WIDTH,HEIGHT,"Choose a file",nil,2)
    for j = 1,#Files do
        if Files[j].Name == fileName then -- Found
            Files[CurrentFileID].Cursor.x = PosX
            Files[CurrentFileID].Cursor.y = PosY
            CurrentFileID = j
            PosX = Files[CurrentFileID].Cursor.x
            PosY = Files[CurrentFileID].Cursor.y
         end
    end
end

-- Note here:
-- tail call only uses on a function that it doesn't need to return to menu
-- If a normal (need to return to menu) function use a tail call,it'll be not converient.
-- Tail call saves mem and stack size,so use tail call as we can
function MenuFunctions.Main()
    local item = Menu(MenuTabs.Main,WIDTH,HEIGHT,"Main Menu",nil,3)
    if item ~= nil and string.find(item," menu") then
        -- a bit complex,see details below:
        -- first,the MenuFunctions table contains the Menu callback functions indexed by their name without ' menu' suffix.
        -- e.g,"File menu"'s callback is MenuFunctions["File"],don't have ' menu'
        -- so,the '(string.gsub(item," menu","",1))' is to replace the first ' menu' to ''(empty)
        -- and then,use MenuFunctions[...] to index it,which we'll get a callback function
        -- finally,call it.('MenuFunctions[...]()')
        -- Interface-like call
        -- maybe here can be tail call? Not checked.
        MenuFunctions[(string.gsub(item," menu","",1))]() 
    elseif item == "Settings..." then
        -- Same here,but we only have one item: 'Settings',so no need for slice the string.
        MenuFunctions["Settings"]()
    elseif item == "Exit (no save!)" then
        return restore()
    elseif item == "About Mars" then 
        return About()
    end
end

-- Sub-menu Callbacks
function MenuFunctions.File()
    local item = Menu(MenuTabs.File,WIDTH,HEIGHT,"File Menu",nil,1)
    if item == "New file" then
        Files[CurrentFileID].Cursor.x = PosX
        Files[CurrentFileID].Cursor.y = PosY
        NewFile()
    elseif item == "Load file..." then
        Files[CurrentFileID].Cursor.x = PosX
        Files[CurrentFileID].Cursor.y = PosY
        return LoadFile()
    elseif item == "Save current file" then
        SaveCurrentFile()
    elseif item == "Save and exit" then
        SaveCurrentFile()
        return restore()
    elseif item == "Save as..." then
        SaveAs()
    elseif item == "Clear whole file" then
        Clear()
    elseif item == "Close current file" then
        if Files[CurrentFileID].isSaved == "!" then
            local canSave = Menu({{"Yes","No","Cancel"}},WIDTH,HEIGHT,"Do you want to save current file?",nil,3)
            if canSave == "Yes" then
                SaveCurrentFile()
            end
        end
        for i = CurrentFileID,#Files do
            if Files[i + 1] ~= nil then
                Files[i] = Files[i + 1]
            else
                Files[i] = nil
            end
        end
        CurrentFileID = CurrentFileID - 1
        if CurrentFileID == 0 then
            return NewFile() -- tail call,save mem & lua stack
        else
            PosX = Files[CurrentFileID].Cursor.x
            PosY = Files[CurrentFileID].Cursor.y
        end
    elseif item == "Change current file..." then
        return ChangeCurrentFile()
    end
end

function MenuFunctions.Edit()
    local item = Menu(MenuTabs.Edit,WIDTH,HEIGHT,"Edit Menu",nil,2)
    if item == "Search..." then
        local patternToFind = textbox("Enter a lua pattern to find in current file","Less than 20 characters!","",20)
        if patternToFind == nil or type(patternToFind) ~= "string" or patternToFind:len() == 0 then
            print("Input wrong!")
            sleep(900)
            return -1
        else
            local findings = SearchInCurrentFile(patternToFind)
            NewFile()
            Files[CurrentFileID].Name = "Search Result"
            Files[CurrentFileID].Content = findings
            Files[CurrentFileID].LineSN = #findings
        end
    elseif item == "Change current code language..." then
        local supportedLanguage = {}
        for k,v in pairs(FunctionMaps) do
            table.insert(supportedLanguage,{k})
        end
        local toChange = Menu(supportedLanguage,WIDTH,HEIGHT,"Change current language",nil,2)
        if FunctionMaps[toChange] then
            CurrentLanguage = toChange
        end
    elseif item == "Merge files..." then
        MergeFiles()
    end
end

function MenuFunctions.Settings()
    if g == 1 then -- tab key is length-changeable,so there needn't a change space func
        for i = 1,#(MenuTabs.Settings) do
            if MenuTabs.Settings[i][1] == "Change 'tab' hotkey's spaces" then
                table.remove(MenuTabs.Settings,i)
            end
        end
    end
    local item = Menu(MenuTabs.Settings,WIDTH,HEIGHT,"Settings",nil,1)
    if item == "Enable/Disable backup (next save)" then
        if b == 0 then
            b = 1
            print("Change backup mode to enable done.")
        else
            b = 0
            print("Change backup mode to disable done.")
        end
        
    elseif item == "Change 'tab' hotkey's spaces" and g ~= 1 then
        local temp = tonumber(textbox("Enter new number of spaces","Leave it blank if you don't want to change","",2))
        if temp ~= nil and type(temp) == 'number' and temp <= 10 and temp >= 0 then
            t = temp
            print("Change 'tab' hotkey's spaces to "..t.." spaces done.")
        end
    end
    sleep(500)    
end
-- End Sub-menu Callbacks

-- only use in post-init state(not in main loop),should be defined as local.
function LoadFunctionMaps()
    local mapPath = "A/CHDK/DATA/Mars/Functions.map"
    if os.stat(mapPath) == nil then 
        return -1
    end
    -- maybe there's security troubles... :(
    -- just like,a hacker changes the Functions.map and inserts some encrypt code in it...
    -- Can't fix it,unless we have a full-file parser without exec it 
    local map = dofile(mapPath)
    -- just a simple check,still have some deep trouble above
    -- like code in function.map: 'function badGuy() ... end badGuy() return {}' should work...
    -- hope there's no hackers try to change the original Function.map ...
    if type(map) == "table" then
       FunctionMaps = map
    end
end

-- FIXME: Move or Write mode sometimes screen flash
-- This function does not work like a render() or a Redraw(),'cause call it does NOT redraw at once(redraws after some event,e.g,press a key)
-- DO NOT USE console_redraw() HERE (will flash for a high frequence)
function Draw()
    set_console_autoredraw(1)
    if PosY > HEIGHT - 4 + ShiftY then ShiftY = PosY - HEIGHT + 4 end
    if PosY <= ShiftY then ShiftY = PosY - 1 end
    if PosX > WIDTH - 4 + ShiftX then ShiftX = PosX - WIDTH + 4 end
    if PosX <= ShiftX then ShiftX = PosX end
    if ShiftX < 0 then ShiftX = 0 end
    if ShiftY < 0 then ShiftY = 0 end
    print(MakeStringBar(TopBar,WIDTH))
    local drawLine = ""
    for line_nr = 1, HEIGHT - 2 do
        if Files[CurrentFileID].Content[line_nr + ShiftY] == nil then
            drawLine = ""
        elseif line_nr + ShiftY ~= PosY then
            drawLine = Files[CurrentFileID].Content[line_nr + ShiftY]
        elseif line_nr + ShiftY == PosY then
            drawLine = string.sub(Files[CurrentFileID].Content[line_nr + ShiftY],1,PosX).."\17"..string.sub(Files[CurrentFileID].Content[line_nr + ShiftY],PosX + 1,#(Files[CurrentFileID].Content[line_nr + ShiftY]))
        end
        drawLine = string.sub(drawLine,ShiftX,#(drawLine))
        if #(drawLine) > WIDTH - 2 then
            drawLine = string.sub(drawLine,1,WIDTH - 2).."\26"
        end
        print(drawLine)
    end
    print(MakeStringBar(StatusBar,WIDTH))
    set_console_autoredraw(0)
end

-- 'Major' Mode Callbacks
-- Same as 'ModeFuctions["Move"] = function()',but easier to understand
function ModeFunctions.Move()
    StatusBar = "["..CurrentMode.."]["..JUMPS[JUMP].."\18]["..PosX..","..PosY.."/"..Files[CurrentFileID].LineSN.."]"
    TopBar = "- Mars \6 "..Files[CurrentFileID].Name.." ["..Files[CurrentFileID].isSaved.."] -"
    input = GetInput()
    if input == "set" then 
        CurrentMode = "Write"
    -- Here,optimized EDI's logic
    elseif input == "up" then
        PosY = PosY - JUMPS[JUMP]
        if PosY < 1 then PosY = table.getn(Files[CurrentFileID].Content) end
        if PosX > #(Files[CurrentFileID].Content[PosY]) then PosX = #(Files[CurrentFileID].Content[PosY]) end
    elseif input == "down" then
        PosY = PosY + JUMPS[JUMP]
        if PosY > Files[CurrentFileID].LineSN then
            PosY = 1
        end
        if PosX > #(Files[CurrentFileID].Content[PosY]) then
            PosX = #(Files[CurrentFileID].Content[PosY])
        end
    elseif input == "left" then
        PosX = PosX - 1
        if PosX < 0 and PosY > 1 then
            PosY = PosY-1
            PosX = #(Files[CurrentFileID].Content[PosY])
        elseif PosX < 0 and PosY == 1 then
            PosY = Files[CurrentFileID].LineSN
            PosX = #(Files[CurrentFileID].Content[PosY])
        end
    end
    if input == "right" then
        PosX = PosX + 1
        if PosX > #(Files[CurrentFileID].Content[PosY]) and PosY < Files[CurrentFileID].LineSN then
            PosY = PosY + 1
            PosX = 0
        elseif PosX > #(Files[CurrentFileID].Content[PosY]) and PosY >= Files[CurrentFileID].LineSN then
            PosY = 1
            PosX = 0
        end
    end
    if input == "zoom_in" then
        PosX = PosX + 5
        if PosX > #(Files[CurrentFileID].Content[PosY]) and PosY < Files[CurrentFileID].LineSN then
            PosY = PosY + 1
            PosX = 0
        elseif PosX > #(Files[CurrentFileID].Content[PosY]) and PosY >= Files[CurrentFileID].LineSN then
            PosY = 1
            PosX = 0
        end
    end
    if input == "zoom_out" then
        PosX = PosX - 5
        if PosX < 0 and PosY > 1 then
            PosY = PosY - 1
            PosX = #(Files[CurrentFileID].Content[PosY])
        elseif PosX < 0 and PosY == 1 then
            PosY = Files[CurrentFileID].LineSN
            PosX = #(Files[CurrentFileID].Content[PosY])
        end
    end
    if input == "shoot_full" and m == 1 then
        CurrentMode = "Select"
    end
    if input == Hotkeys.ChangeSubModeKey then
        JUMP = JUMP + 1 
        Draw()
    end
    if JUMP > table.getn(JUMPS) then JUMP = 1 end
    if input == Hotkeys.MenuKey then
        return MenuFunctions["Main"]()
    end
    return Draw()
end

-- EXPERIMENTAL FEATURE
-- TODO: Clipboard support
function ModeFunctions.Select()
if m == 1 then
    ModeFunctions["Move"]()
    if input == "shoot_full" then
        isClip = true
    end
    if isClip then
        input = GetInput()
        if input == "set" or input == "shoot_full" then
            if isClip then
                table.insert(Clipboard,Cilp)
            end
            CurrentMode = "Write"
        elseif input == "left" then
                
        end
    end
end
end

function ModeFunctions.Write()
    local delete = 0
    local writeModeDescript = ""
    for li = 1,table.getn(LetterMap[WriteSubMode]) do
        writeModeDescript = writeModeDescript.."\6"
        for xi = 1,table.getn(LetterMap[WriteSubMode][li]) do
            writeModeDescript = writeModeDescript..LetterMap[WriteSubMode][li][xi]
        end
    end
    writeModeDescript = writeModeDescript.."\6"
    StatusBar = writeModeDescript
    TopBar ="- Mars \6 "..Files[CurrentFileID].Name.." ["..Files[CurrentFileID].isSaved.."] -"
    insertion = ""
    Draw()
    local input = GetInput()
    if input == Hotkeys.ChangeSubModeKey then
        WriteSubMode = WriteSubMode + 1
        WriteKey = 0
        if WriteSubMode > table.getn(LetterMap) then 
            WriteSubMode = 1
        end 
        Draw()
    end
    if input == "left" then 
        if WriteKey == 1 then
            LETTER_NR = LETTER_NR + 1
            delete = 1
        else
            LETTER_NR = 1
            WriteKey = 1
        end
        Files[CurrentFileID].isSaved = "!"
    end
    if input == "up" then 
        if WriteKey == 2 then
            LETTER_NR = LETTER_NR + 1
            delete = 1
        else
            LETTER_NR = 1
            WriteKey = 2
        end
        Files[CurrentFileID].isSaved = "!"
    end
    if input == "right" then 
        if WriteKey == 3 then
            LETTER_NR = LETTER_NR + 1
            delete = 1
        else
            LETTER_NR = 1
            WriteKey = 3
        end
        Files[CurrentFileID].isSaved = "!"
    end
    if input == "down" then 
        if WriteKey == 4 then
            LETTER_NR = LETTER_NR + 1
            delete = 1
        else
            LETTER_NR = 1
            WriteKey = 4
        end
        Files[CurrentFileID].isSaved = "!"
    end
    if input == "zoom_in" then
        WriteKey = 0
        insertion=" "
        Files[CurrentFileID].isSaved = "!"
    end
    if input == "zoom_out" then
        Files[CurrentFileID].isSaved = "!"
        if PosX > 0 then
            WriteKey = 0
            delete = 1
        elseif PosX == 0 and PosY > 1 then
            PosX = #(Files[CurrentFileID].Content[PosY - 1])
            Files[CurrentFileID].Content[PosY - 1] = Files[CurrentFileID].Content[PosY - 1]..Files[CurrentFileID].Content[PosY]
            PosY = PosY - 1
            for line = PosY + 1,table.getn(Files[CurrentFileID].Content) - 1 do
                Files[CurrentFileID].Content[line] = Files[CurrentFileID].Content[line + 1]
            end
            Files[CurrentFileID].Content[Files[CurrentFileID].LineSN] = nil
            Files[CurrentFileID].LineSN = Files[CurrentFileID].LineSN - 1
         end
    end
    if WriteKey ~= 0 and LETTER_NR ~= 0 then
        if LETTER_NR > table.getn(LetterMap[WriteSubMode][WriteKey]) then 
            LETTER_NR = 1
        end
        insertion = LetterMap[WriteSubMode][WriteKey][LETTER_NR]
        Files[CurrentFileID].isSaved = "!"
     end
    if input == Hotkeys.tabKey then
       Files[CurrentFileID].isSaved = "!"
       insertion = string.rep(tabCharacter,t)
       WriteKey = 0
    end
    if input == "set" then
        if WriteKey == 0 then CurrentMode = "Move"
        else
            WriteKey = 0
            insertion = ""
        end 
        Draw()
    end
    if input == Hotkeys.MenuKey then
        WriteKey = 0
        insertion = ""
        Files[CurrentFileID].isSaved = "!"
        insertion = Menu(SpecialCharMap,WIDTH,HEIGHT,"Insert a special char",nil,2)
        if insertion == nil then
            for i = 1, #FunctionMaps[CurrentLanguage] do
                if insertion == nil then insertion = Menu(FunctionMaps[CurrentLanguage][i],WIDTH,HEIGHT,"Insert a function",12,0)
                else break
                end
            end
        end
        if insertion == nil then
            insertion = ""
            Files[CurrentFileID].isSaved = "S"
        end
        if insertion == "newline" then
            insertion = ""
            delete = 0
            Files[CurrentFileID].isSaved = "!"
            for unline = 0, Files[CurrentFileID].LineSN - PosY + 1 do
                Files[CurrentFileID].Content[Files[CurrentFileID].LineSN + 1 - unline] = Files[CurrentFileID].Content[Files[CurrentFileID].LineSN - unline]
            end
            Files[CurrentFileID].Content[PosY] = string.sub(Files[CurrentFileID].Content[PosY + 1],1,PosX)..CR
            Files[CurrentFileID].Content[PosY + 1] = string.sub(Files[CurrentFileID].Content[PosY + 1],PosX + 1,#(Files[CurrentFileID].Content[PosY+1]))
            PosX = 0
            PosY = PosY + 1
            Files[CurrentFileID].LineSN = Files[CurrentFileID].LineSN + 1
        end
        if insertion == "ASCII code" then
            insertion = InsertAscii()
        end
    end
    -- TODO: Menu can't be open in Write mode,because it uses menu key,and it'll conflict with the Insert menu.
    -- maybe back to old-style Insert Menu key (DISP,or VIDEO)and main menu key(MENU) can solve this problem
    -- but we will have a new hotkey mapping parameter...User will be confused,too.
    if input == nil then
        WriteKey = 0
        insertion = ""
    end
    Files[CurrentFileID].Content[PosY] = string.sub(Files[CurrentFileID].Content[PosY],1,PosX - delete)..insertion..string.sub(Files[CurrentFileID].Content[PosY],PosX + 1,#(Files[CurrentFileID].Content[PosY]))
    PosX = PosX + #(insertion) - delete 
    return Draw()
end

function InsertAscii()
    local exitLoop = false
    local code = {0,0,0}
    local pos = 1
    local mass = "-"
    repeat
        print()
        print()
        print(MakeStringBar("Insert char by ASCII",WIDTH))
        print()
        print()
        local codeString = ""
        if pos == 1 then
            codeString = "\4"..code[1].." "..code[2].." "..code[3]
        elseif pos == 2 then
            codeString = " "..code[1].."\4"..code[2].." "..code[3]
        elseif pos == 3 then
            codeString = " "..code[1].." "..code[2].."\4"..code[3]
        end
        print("       Set ASCII code: "..codeString)
        print()
        print()
        print(MakeStringBar(mass,WIDTH))
        for li = 11,HEIGHT do
            print()
        end
        input = GetInput()
        if input == "right" then pos = pos + 1 end
        if input == "left" then pos = pos - 1 end
        if pos > 3 then pos = 1 end
        if pos < 1 then pos = 3 end
        if input == "up" then code[pos] = code[pos] + 1 end
        if input == "down" then code[pos] = code[pos] - 1 end
        if code[pos] > 9 then code[pos] = 0 end
        if code[pos] < 0 then code[pos] = 9 end
        local ascii = code[1] * 100 + code[2] * 10 + code[3]
        if ascii < 256 and ascii > 0 then mass = "character: "..string.char(ascii)
        else mass = "bad value"
        end
        if input == "set" then
            if ascii > 255 or ascii < 1 then
                print( "ASCII code must be in range 1-255!")
                sleep(500)
                return ""
            else
                return string.char(ascii)
            end
        end
    until exitLoop == true
end

-- Main Menu display routine,if some necessary parameters not given,it'll raise a error and exit(not like displaying a message in before)
function Menu(tab,width,height,header,itemWidth,topLines)
    local menuPosY = 1
    local menuPosX = 1
    local menuShift = 0
    local exitMenu = false
    if header == nil then header="Select an Item"
    elseif topLines == nil then topLines = 0
    end
    repeat
        if menuPosX < 1 and menuPosY > 1 then
            menuPosY = menuPosY - 1
            menuPosX = table.getn(tab[menuPosY])
        end
        if menuPosX < 1 and menuPosY <= 1 then
            menuPosY = table.getn(tab)
            menuPosX = table.getn(tab[menuPosY])
        end
        if menuPosY < 1 then menuPosY = table.getn(tab) end
        if menuPosY > table.getn(tab) then menuPosY = 1 end
        if menuPosX > table.getn(tab[menuPosY]) and menuPosY < table.getn(tab) then
            menuPosY = menuPosY + 1
            menuPosX = 1
        end
        if menuPosX > table.getn(tab[menuPosY]) and menuPosY >= table.getn(tab) then
            menuPosY = 1
            menuPosX = 1
        end
        if menuPosY > height - 4 + menuShift then menuShift = menuPosY - height + 4 end
        if menuPosY <= menuShift then menuShift = menuPosY - 1 end
        for line = 0, topLines do
            print("")
        end
        print(MakeStringBar(header,width))
        for line = 1, table.getn(tab) do
            if tab[line + menuShift] == nil then
                drawLine = ""
            elseif line + menuShift == menuPosY then
                drawLine = ""
                for place = 1, table.getn(tab[line + menuShift]) do
                    local item = tab[line + menuShift][place]
                    if itemWidth ~= nil then item = item..string.sub("                         ",1,itemWidth - #(item)) end
                    if menuPosX ~= place then drawLine = drawLine.." "..item.." "
                    elseif menuPosX == place then drawLine = drawLine.."\16"..item.."\17"
                    end
                end
            elseif line + menuShift ~= menuPosY then
                drawLine = ""
                for place = 1, table.getn(tab[line + menuShift]) do
                    item = tab[line + menuShift][place]
                    if itemWidth ~= nil then item = item..string.sub("                         ",1,itemWidth - #(item)) end
                    drawLine = drawLine.." "..item.." "
               end
            end
            print(drawLine)
        end
        print(MakeStringBar("Select-["..menuPosX..","..menuPosY.."]",width))
        for line = 0, height - 4 - topLines - table.getn(tab) do
            print("")
        end
        input = GetInput()
        if input == "up" then menuPosY = menuPosY - 1
        elseif input == "down" then menuPosY = menuPosY + 1
        elseif input == "left" then menuPosX = menuPosX - 1
        elseif input == "right" then menuPosX = menuPosX + 1
        elseif input == "set" then
            exitMenu = true
            return tab[menuPosY][menuPosX]
        elseif input == Hotkeys.MenuKey then
            exitMenu = true
            return nil
        end
    until exitMenu == true
end

function SaveCurrentFile()
    cls()
    print(MakeStringBar("Saving procedure...",WIDTH))
    if (b ~= 0 and Files[CurrentFileID].Path ~= nil) then
        print("--Make a backup...")
        local backupPath = Files[CurrentFileID].Path..".BAK"
        print("  *Backup:",backupPath)
        print("--Open files")
        local saveFile = io.open(Files[CurrentFileID].Path,"r")
        local backupFile = io.open(backupPath,"w")
        if (not saveFile or not backupFile) then
            print("Error opening files")
            print("Press any key to return")
            Log("Error","Opening files error.")
            wait_click(500)
            return -1 -- use -1 for default error code,though no caller use it
        end
        for fileLine in saveFile:lines() do
            backupFile:write(fileLine)
            backupFile:write("\n")
        end
        saveFile:close()
        backupFile:close()
        Log("Info","Backup to "..backupPath.." done.")
        print("--Backup done")
        print()
    end
    if Files[CurrentFileID].Path == nil then Files[CurrentFileID].Path = SelectFileName() end
    if Files[CurrentFileID].Path == -1 then return 1 end
    print("--Saving file")
    local saveFile = io.open(Files[CurrentFileID].Path,"wb")
    if (not saveFile) then
        print("Error opening file")
        print("Press any key")
        wait_click(500)
        return -1
    end
    for _,fileLine in ipairs(Files[CurrentFileID].Content) do
        saveFile:write(fileLine)
        saveFile:write("\n")
    end
    saveFile:close()
    Files[CurrentFileID].isSaved = "S"
    print("The file has been saved.")
    Log("Info","Saved "..Files[CurrentFileID].Name.." to "..Files[CurrentFileID].Path)
    sleep(300)
end

function SaveAs()
    local filePath = Files[CurrentFileID].Path
    Files[CurrentFileID].Path = nil
    SaveCurrentFile()
    Files[CurrentFileID].Path = filePath
end

-- this function cannot be local - if so,we'll can't run it when script ends
function restore()
    set_console_layout(0,0,25,14)
    cls()
    print("Mars has been exit.")
    Log("Info","Mars editor exited.")
    EXIT = true
end

-- TODO: a recover feature(like Ctrl + Z on computer)
function Clear()
    if Menu({{"No","Yes"}},WIDTH,HEIGHT,"Are you sure?",7,2) == "Yes" then 
       Files[CurrentFileID].Content = {""}
       Files[CurrentFileID].LineSN = 1
       PosX = 1
       PosY = 1
       Files[CurrentFileID].isSaved = "!"
    end
end

-- You can display anything you like to display here for debug
function DebuggingMessage()
    cls()
    local exitDebugging = false 
    print(MakeStringBar("Debug Message",WIDTH))
    print("   ticks: ",get_tick_count())
    print("   Mem usage: ",collectgarbage("count"))
    print("   Lua version: ",_VERSION)
    print(MakeStringBar("Press Menu to Return",WIDTH))
    print("   ")
    print("   ")
    repeat
        local input = GetInput()
        if input == Hotkeys.MenuKey then exitDebugging = true end
    until(exitDebugging == true)
end

function About()
    cls()
    print(MakeStringBar("About Mars Editor",WIDTH))
    print("   ")
    print("  Mars - a text & code editor for CHDK")
    print("   ")
    print("  Version:",VERSION)
    print("  Inspired by outslider's EDI project")
    print("  Author:  December172")
    print("  Thanks:  outslider, Caefix & others")
    print("  License: GNU GPL v3+")
    print("  See README.TXT to get more info")
    print(MakeStringBar("Press Menu to Return",WIDTH))
    print("   ")
    print("   ")
    local exitAbout = false
    repeat
        local input = GetInput()
        if input == Hotkeys.MenuKey then exitAbout=true 
        -- TODO: Change to a hotkey here
        elseif input == "video" then -- Easter egg,huh? 
            local input = GetInput()
            if input == "video" then DebuggingMessage() end
        end
    until(exitAbout == true)
end

-- Note: use local function because these function only runs once - they don't need to be stay in mem all the time
-- If a function runs for many times (like getInput()) DON'T USE LOCAL FUNCTION OR FUNCTION WILL BE UNREACHABLE AFTER SEVERAL GC
local function init()
    cls()
    if get_mode() then set_record(false) end
    set_console_layout(0,0,WIDTH,HEIGHT)
    set_console_autoredraw(0)
    set_exit_key("no_key") -- for using shoot_full hotkey in future
    Log("Info","Mars editor started.")
    -- To load bigger file(and faster),we should cut some initialize function calls before load file
    if a == 1 then
        NewFile()
    else
        if n == 1 then-- Browser file in CHDK/
            -- Thx Caefix's EDI 2.7.3's idea
            local pathTable = {"","SCRIPTS","LOGS","BOOKS","HELP","DATA"}
            LoadFile("A/CHDK/"..pathTable[f + 1]) -- Lua's array starts from 1,and f is start from 0
           else
               LoadFile()
           end
    end
    
    -- Hotkey Mapping
    local tabMapping = {"display","playback","video"}
    table.insert(KeysTable,tabMapping[e + 1]) -- In here,if you defined tabKey as a non-exist key,the Mars will assume you have this key(may cause bugs) 
    Hotkeys.tabKey = tabMapping[e + 1]
    
    -- Key Mapping
    -- thinking: if a user both have disp and video key,will he only choose disp and don't use video key?
    local usedKeys = {}
    for _,v in ipairs(KeysTable) do
        usedKeys[v] = true -- mark all used keys
    end
    -- TODO: zoom_in and zoom_out
    if j == 1 then       -- User marked 'having DISP key'
        if not usedKeys["display"] then 
            -- not used
            table.insert(KeysTable,"display")
        end
    elseif k == 1 then  -- User marked 'having PLAYBACK key'
        if not usedKeys["playback"] then
            -- not used 
            table.insert(KeysTable,"playback")
        end
    elseif l == 1 then  -- User marked 'having VIDEO key'
        if not usedKeys["video"] then
            -- not used 
            table.insert(KeysTable,"video")
        end
    end
    -- Check if there're duplicated keys
    for k,v in ipairs(KeysTable) do
        for i = 1,#KeysTable do
            if KeysTable[i] == v and i ~= k then
                table.remove(KeysTable,i)
             end
        end
    end
end 

-- real main loop
local function main()
    LoadFunctionMaps() -- init here to less mem use in load file func to be able to load bigger file
    insertion = ""
    -- Here,use the least Draw() as we can,to agninst the flash of screen  
    repeat
        ModeFunctions[CurrentMode]()    -- Compact syntax,huh?
        collectgarbage("collect")       -- force it gc at once,to save mem
    until EXIT == true
end

-- main program
init()
if EXIT ~= true then main() end
-- Whoa, 1143 lines! (though only 900 - 1000 lines really work)
