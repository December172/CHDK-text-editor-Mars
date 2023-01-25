Brief: This is readme for Mars - Text editor written in Lua for CHDK. It's designed to give your camera possibility to edit text files (especially scripts) directly on camera.

Index:
***************************************
    0. - About the Mars editor

    1. - Installation

    2. - Usage

    3. - Parameters / Options

    4. - Author, License

    5. - Changelog
***************************************

*** If you're reading it using CHDK's text reader,please open 'Word Wrap' for better reading ***
0. About the Mars editor
    (Detailed changelog in part 5)
    0.1 Overview & Idea
        Last year,when I use the EDI for first time,I've found a bad thing - I cannot insert some special characters.This is because my camera doesn't have a DISP key so that I can't open the 'insert menu'.To fight with this problem,I even learned Lua and changed a lot of things on the original EDI.(I named it emacs ;) but it's a past and low editor).After month's changing,my own editor came out at the end.I called 'Mars',and it's a new and powerful editor to replace the EDI.

    0.2 Attentions
        1. Mars uses textbox() function which is currently available in CHDK version 1.4(or 1.3). So Mars requires CHDK's version higher than 1.4.1.If not,please update your CHDK!
        2. About maximum openable file size:On my camera I can open a 1.16 MB file without errors(collectgarbage shows 1660),open 1.2 MB file failed.
           So if you have 300 - KB of RAM,a 20 - 100 KB file won't cause any problem.However,you can try the maximum file that you can open,but it'll be slow.So just open a 20- 400 KB files for usual using.Opening multiple file will cost more mem.

    0.3 Warning!
        Many of  users were able to use it on other CHDK-supported cameras. 
        Nevertheless THERE IS NO WARRANTY FOR THIS SOFTWARE, IT'S FREE AND MIGHT BE BUGGY. 
        It's rather not likely, but still possible that it could damage file you are editing or even filesystem on SD card. 
        This never happened, but who knows. USE THIS SCRIPT ON YOUR OWN RISK.
        In addition,ENABLE EXPERIMENTAL FEATURES MAY LET YOU LOST THE CONTROL OF CAMERA,THIS ISN'T A JOKE.(only press power button or pull out the batteries can help it out)
        SOME PARTS OF THIS DOCUMENTATION MIGHT BE OUTDATED OR CONTAIN BUGS.

1. Installation

    If you needn't a function map,just paste the file Mars.lua on your SD card. Mars is installed and ready to use!
    (Make sure you have a CHDK directory,of course :) )
    If not so,you also need to move the Functions.map in the zip to the CHDK/DATA/Mars directory.(the Mars directory is a new directory in DATA/ folder,just create a new folder like any other) To know what is Function map,see section 2.3.4.

2. Usage
    *** Most of basic usages are the same from the EDI's,just some addition features are new ***
    2.1 Run

        Run Mars as a normal script - to run with options,go to part 3. Read more about running scripts on CHDK wikia or forum.

    2.2 Select a file - file browser

        Once you run the script you'll see a file browser. You have to chose a file you want to edit. Just navigate using UP/DOWN and SET buttons as in normal CHDK file browser. If you selected a directory pressing SET will take you inside it. Special directory ".." Moves you into the parent directory. If you press SET button with file selected this file will be opened.If you select nothing(just press a menu to exit the file browser),editor will create a new file.

    2.3 Mars
        2.3.1 Overview
          When you have selected the file and pressed SET this file is opened. You can see a screen like this:

          ---------- Mars | FILENAME [S] ----------
          <Here you should
          see
          the content
          of a file
          ------------ [Move][1|][0,1] ------------

          First line is Top Bar - it contains editor name (Mars), opened file name (in example: FILENAME) and saved indicator - [S] if file has not been changed since last save and [!] if there are some unsaved changes.
          Last line is Status Bar - it contains mode description (in example: Move) and other information depending on Mode variable. This will be described below.
          Between these lines there is a part of content of the file. You can see, that first line below Top Bar begins with triangle (not really: "<" however, it's not possible to place triangle here,it's ASCII code is 17). This triangle is the cursor - as in normal text editor. It indicates, where new letter/sign will be inserted or which letter/sign will be deleted.

        2.3.2 Hotkeys
            In Mars,there's a thing named 'hotkeys',they can be defined by user.
            In default,there are 3 hotkeys:
            ChangeSubModeKey = 'shoot_half' key (I'll call 'ChangeSubMode',usually needn't to change,because any camera should have a shoot key)
            MenuKey          = 'menu' (same as 'ChangeSubMode' key,simply call it menu)
            TabKey           = 'playback' (working like a real keyboard 'tab' key,when it's pressed,it'll insert spaces or a certain character(see part 3,section Settings),useful for code format)

        2.3.3 Modes (in script called CurrentMode)

        - Move mode

            At the beginning you are in Move mode. That means you are able to Move cursor using up/down/left/right buttons on your camera. Normally one press moves cursor one place left/right or one line up/down.
            Meaning of the keys and the hotkeys in this mode:
            
            up/down/left/right  - Move the cursor, as described above.
            zoom_out/zoom_in    - Move the cursor 4 places left/right. Useful if you want to edit something inside a long line.
            set                 - end 'Move' mode and go into a 'Write' mode.
            shoot_full          - Nothing :) (Will be used as a hotkey in future - you can only exit from menu)
            menu                 - open Main Menu which is described below.
            shoot_half    - change number of lines you'll move by one UP/DOWN press. The number is shown in Status Bar (first number after Move word). You can switch between 1, 4, 10, 20 and 30 lines. It's Useful to move through long files.

        - Write mode

            When you press set being in Move mode you'll be taken to the Write mode. In this mode screen looks like this:

            ---------- Mars | FILENAME [S] ----------
            <Here you should
            see
            the content
            of a file
            ---- |abcdef|ghijkl|mnopqrs|tuvwxyz| ----

            Top Bar looks just like in the Move mode, however, Status Bar has been changed.
            Status Bar in Write mode describes, which letters/digits are available under which keys. Status Bar like above means, that you are able to write lowercase letters as follows:
            (Hotkeys also work in Write mode,see below)

            press left to get letters:  a, b, c, d, e, f
            press up to get letters:    g, h, i, j, k, l
            press right to get letters: m, n, o, p, q, r, s
            press down to get letters:  t, u, v, w, x, y, z
            When you press a key once you'll get first letter, twice - second and so on. If you need to write another letter just press different letter key. If you need a letter that is available under the same key as previous just press SET once and the key. This is just like writing SMS'es on mobile phone.
            You can change lowercase to uppercase by pressing SHOOT_HALF. Another SHOOT_HALF will change to digits and then back to the lowercase.

            Description of the keys meanings in the WRITE mode:

            left       - a,b,c,d,e,f     or   A,B,C,D,E,F      or   1,2,3
            up         - g,h,i,j,k,l     or   G,H,I,J,K,L      or   4,5,6
            down       - m,n,o,p,q,r,s   or   M,N,O,P,Q,R,S    or   7,8,9
            right      - t,u,v,w,x,y,z   or   T,U,V,W,X,Y,Z    or   0,+,-,*,/,=
            zoom_in    - spacebar
            zoom_out   - backspace
            set        - end Write mode and go into Move mode
            menu       - open INSERT Menu - described below
            shoot_half - change between lowercase/uppercase/digits

    2.3.4 Insertion Menus

        - Special character's menu

            This menu allows you to insert special characters or even words. This menu is available ONLY in Write mode by pressing MenuKey hotkey. Once MenuKey is pressed you'll see screen like this:

            ------- Insert special char ------
           >newline<
            (  )  [  ]  {  }
            <  >  ,  '  :  ;
            _  +  -  /  \  =
            @  !  ?  #  "  .
            ~  &  *  |  ^  `
            ASCII code
            --------- SELECT-[1,1] ----------

            You can select the character you need by pressing LEFT/UP/RIGHT/DOWN buttons. When you press SET you'll return to the editor and selected character will appear in cursor place. You can select:
            - newline          - breaks line in cursor place (just like ENTER on PC keyboard)
            - ( [ @ $... etc.    - insert selected character
            - ASCII code         - you can load a character by it's ASCII code. If this option is active you'll be taken to the ASCII selection menu.

            You can also press menu key again and go to the Function Map's Menu, which is described below.
            If you want to leave Special character's Menu,also see the description below.

        - Function Map's Menu

            - About Function Maps
                To really understand how the Function Map's Menu works,you should know what the Function Maps are.
                Function Maps are maps contain all common function(or something else,e.g some pattern,even a little piece of word if you like.I'll call them 'functions') in one language.It seems not good as the EDI's simple insert function menu,but it's best place is that it can contains many pages,not one.Also,it can contain many language's pages,not just one language's pages.(To know how to switch language,see description of menu item "Change current language" in section 2.3.5) It's easier to add functions than EDI.(In EDI,if you want to change the insert map,you need to change the code directly :( ) To learn how to add or modify pages in Function Maps,see comment inside the default Functions.map.
            - Function Map's Menu
                If you are in Special character's menu you can press menu again and go to the Function Map's Menu as described above. In this menu you'll see a screen like this:

                -------- Insert function --------
                >print()< return      if
                then      cls()       end
                sleep     wait_click  function
                --[[      --]]        else
                until     require()   local
                repeat    @param      @default
                --------- SELECT-[1,1] ----------

                You can select a word that will be inserted in cursor place just like character. It's useful especially for scripts, so the most common functions are present here. Remember - this only inserts a selected word, there is no checking if this make any sens.
                As we described above,you can have many pages - that's,if you have more than one function page,just press one menu cannot exit this menu.You'll see another screen like this to let you insert functions and/or words in next page in Function Maps. Note: the default Function Map inside the editor and the default Functions.map only contain one page in one language,so if you don't change the language,you can use it as in EDI. 
                If you like to leave Function Map's Menu without inserting anything just press menu for times until you see the main editor's panel(contains file's content,in Write mode,have Top Bar,Status Bar,etc).

    2.3.5 Main Menu (a.k.a FILE menu in EDI) -- The most complex section
    
        This menu is available only in Move mode by pressing menu. In this file you can select items:

        - File menu
            In this menu,there are several sub-items.You'll get this:
                ----------- File menu -----------
                >New file<
                Load file...
                Save current file
                Save and exit
                Save as...
                Clear whole file
                Close current file
                Change current file...
                --------- SELECT-[1,1] ----------
           
           - New file
                Create a new file and change current file to the new file.
           - Load file...
                Open a file browser,and you can choose existing file like starting.And change current file to selected file. Note: the more files you opened,the more mem the editor will eat!
           - Save current file
                Save current file and don't exit.
            - Save and exit
                Save current file and exit.Note: This won't save other unsaved file!
            - Save as...
                Save current file as another file in another place.
            - <TODO: Save all>
            - Clear whole file
                Removes whole content of current file. However, it will be done only in editor, not physical file until you save changes.
            - Close current file
                Close current file and change current file to the last file.If current file isn't saved,it'll ask you if you want to save it.If current file is the only one opened file,the editor will create a new file instead of exiting.
            - Change current file
                Lists all opened files,let you set one to change to current file. Example: you opened two files by "Load files...",you can use this to switch current file.Note: your cursor will be at your last visited place,too!

        - Edit menu
            - Search...
                <TODO: sub-menu of search>
                Simple search in file tool.Choose this,and you'll see a textbox for you to enter a lua pattern for search.If you don't know what is a "lua pattern",just use it as a simple string search tool.Enter string you want to search,editor will create a new file named "Search Result",and change current file to here.You can see the search result at here.
                Example: 
                    --------- Mars | FILENAME [S] ----------
                    <Here you should
                    see
                    the content
                    of a file
                    ------------ [Move][1|][0,1] ------------

                and you search string is 'content',you'll get

                    --------- Mars | Search Result [S] ----------
                    3: the content
                    -------------- [Move][1|][0,1] --------------
                    the 3: is the line number of your search string matched place in search file. 
                Simple,huh?
            - Change current language
                In 2.3.4,we learned that there can be many pages of function maps in one language,so this item is for change the current language pages.
                E.g,the default language is Lua,and there are 2 pages of it(Lua pages).Now you want to write some uBasic scripts.How to do that? Firstly,you need a Functions.map. To learn how to install a Functions.map,see part 1 (Installation).And then,your Functions.map must contain uBasic's pages(To learn how to add new language pages,see comments inside the Functions.map).Finally,use this to change your current language pages. Tips:the default Functions.map and editor's default map(inside the editor) both contains the uBasic and Lua pages,so you needn't to add them manually.
            - Merge Files...
                <TODO: merge files from external file>
                Opens the same dialog like 'Change Current File' opened to let you choose a opening file to merge to current file at the cursor's position.
        - Settings
            - Enable/Disable backup (next save)
                This can toggle do or don't do backup(like in the Parameters) in editor. Note: change this will work on next save.
            - Change 'tab' hotkey's spaces
                This can change how many spaces will be inserted when you press the 'tab' hotkey(also can set in parameter,see below). Note: If you selected "Which character do you want to use on 'tab' " to 'Windows'(use a ASCII code for 'tab'),there will not have this menu item.
        - Exit (no save!)  - exit without any saves!
        - About 
            Open 'About' dialog.
    
3. Parameters / options
    
    You can set various parameters like in other scripts for CHDK. Read more how to set parameters for scripts on CHDK wikia or forum.

    3.1 Initial Settings:
        - Height              -|
        - Width                |- as they named.
        - Write a new file?   -|
        - Browse file in CHDK/? 
            This parameter controls the starting directory(when start editor,where to browser file).If it's true,Mars will find file in CHDK/ directory.Disabled when "Write a new file?" is true. 
        - Browse file in what CHDK/ sub-directory?
            This parameter controls what sub-directory of CHDK/ will be the Mars's starting directory.e.g,if you choose a 'SCRIPTS',the starting directory will be 'A/CHDK/SCRIPTS'.Disabled when "Write a new file?" is true or "Browse file in CHDK/ ?" is false.

    3.2 Settings:(some can set in editor)
        - Do backups?        - as it named,can set in editor
        - Newline Style?
            set which style of newline coding should be used. Usually Unix uses one character (\n; "newline") to describe newline and Windows uses two characters (\r\n; "carriage return" and "newline",CR and LF). If you set 'Windows' Mars will paste both characters while "newline" is inserted. If you set 'Unix' it will use only "newline" character. Note: this doesn't change existing newline characters!
        - Which character do you want to use on 'tab'?
            Set which character will be inserted when press the 'tab' hotkey.When it's (space),press 'tab' hotkey will insert spaces(the space's number is depends on below option). If it's "Windows",press tab will insert a ASCII char:"\9". This char will be displayed like a length-changeable tab key on computer,so if set this,you'll can't change how many times the char will be inserted when press the 'tab' hotkey(the below option will be disabled).
        - How many spaces press the 'tab' hotkey?
           When use space for tab hotkey,this option sets how many spaces will be inserted when press the tab hotkey(default DISP). Disabled when use Windows-style for tab hotkey.(can set in editor)

    3.3 Key Mapping
        - Have DISP key?        -|
        - Have PLAYBACK?         |- as they named,if you have these key,set them to yes.
        - Have VIDEO key?       -|
    
    3.4 Hotkey
        - Use what key for 'tab'?
            Choose what key you want to use as 'tab' hotkey.Note: if you choose a non-exist key on your camera,Mars will assume you have this key!(even you don't set you have this key at Key Mapping section)
            
    3.5 Debug
        - Logging
            Enable / Disable debug logging.Useful for debug the editor.
        - Experimental Features?(Bugs warning!)
            Not like it's name,all things here is unfinished - that's,enable this is only for development.Don't enable this unless what you're doing!(useful for add new features)
    
4. Author, License
    
    Author:          December172<13326379029@163.com>
    Special thanks:  Pawel Tokarz aka Outslider, Caefix, waterwingz
    Really thanks reyalp for contributing CHDK for us
    License:         GPL v3+ as well as LGPL v3+
    Contact:         write all you want to write on CHDK forum post(https://chdk.setepontos.com/index.php?topic=14648.0),or on my email.
    
    NO WARRANTY! THIS SCRIPT CAN DO ANYTHING WITH YOUR CAMERA, MIGHT DELETE A FILE, MIGHT DAMAGE SD CARD AND MIGHT CAUSE YOUR CAMERA FLY AWAY AND EXPLODE AS WELL. This was never observed and it's unlikely, but still possible...
    USE ON YOUR OWN RISK!

5. Changelog
    v1.2:
       - First public version
       - Key Mapping & Hotkeys fully supporting.
       - Added simple search tool.
       - Fixed a write mode menu bug.
       - README.TXT added 
    v1.1:
       - Private test version
       - Added extensible menu support.(MenuTabs & MenuFunctions.*)
       - Added more language function menu support.(Java,uBasic,not only Lua,see FunctionMaps)
       - Multi-file opening support;see CurrentFileID & ChangeCurrentFile() and other file functions
       - In-editor settings.(Change options like 'do backups?' in editor)
       - More file functions (e.g,merge several file:see MergeFiles() function) on the way.
       - Early debug support: added debug menu & log function
       - Clipboard support preparing (select mode,not implemented yet)
       - Code-level optimized logics.
       - Hotkey 'tab',work like a real keyboard,generate 4 spaces or 0-8 spaces alternatively in future.(use the 'playback' key,you can select a key you like in future)
       - Code style changed to camel style.(Variables' names,functions' local variables,not all)
    v1.0 (from EDI 2.7): 
       - Initial code. 
       
