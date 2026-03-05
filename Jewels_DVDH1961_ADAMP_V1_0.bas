'****************************************************************************
' CVBASIC "JEWELS" FOR COLECOVISION / ADAM 
' GAME BY DVDH1961 ADAM+ 05 March 2026 VERSION 1.0 
' OPEN SOURCE PROJECT
'****************************************************************************

    MODE 0
    CLS
    
    ' --- 16-BIT VARIABLE DEFINITIONS (# PREFIX) ---
    DIM board(90)      
    DIM #score, #lvl, #levelCounter
    DIM #choice, #jewA, #jewB, #jewC, #nxtA, #nxtB, #nxtC
    DIM #curX, #curY, #oldX, #oldY
    DIM #fallTimer, #fallSpeed, #addr, #i, #x, #y, #z, #idx, #v, #temp, #pos, #totalGemsRemoved, #lineLen, #t
    DIM #animTimer, #animFrame, #isNewHS

    ' Highscores
    DIM #h1, #h2, #h3, #h4, #h5
    DIM #l1, #l2, #l3, #l4, #l5
    DIM #u1, #u2, #u3, #u4, #u5
  
    #h1 = 30000: #l1 = 15: #u1 = 0
    #h2 = 20000: #l2 = 10: #u2 = 0
    #h3 = 10000: #l3 = 5:  #u3 = 0
    #h4 = 5000:  #l4 = 4:  #u4 = 0
    #h5 = 2500:  #l5 = 2:  #u5 = 0
    

'****************************************************************************
' GRAPHICS DEFINITIONS (REPLACING LETTERS WITH GEMS)
'****************************************************************************

    ' 128 = Diamond 1, 129 = Diamond 2, 130 = Diamond 3, 131 = Diamond 4, 132 = Diamond 5, 
    ' 133 = Clear 1, 134 = Clear 2
    ' 135,136,137 & 138  = Border
    DEFINE CHAR  128, 11, gem_patterns
    DEFINE COLOR 128, 11, gem_colors
    
    ' Game Title    
    DEFINE CHAR  140, 6, title_patterns
    DEFINE COLOR 140, 6, title_colors
    

'****************************************************************************
' MAIN MENU
'****************************************************************************
INTROSCREEN:

    CLS
    SOUND 0,0,0 : SOUND 1,0,0 : SOUND 2,0,0 : SOUND 3,0,0    
    

    GOSUB INITJ
    
    #choice = 1
    
    
    GOSUB TITLE_LOGO
 
    #addr = 7 * 32 + 10:  PRINT AT #addr, "START GAME"
    #addr = 9 * 32 + 10:  PRINT AT #addr, "INSTRUCTIONS"
    #addr = 11 * 32 + 10: PRINT AT #addr, "HIGH SCORES"
    #addr = 20 * 32 + 2:  PRINT AT #addr, "CODING:DVDH1961   ADAM+ 2026"
    #addr = 21 * 32 + 2:  PRINT AT #addr, "MUSIC :OSCAR TOLEDO G."
    
    #mTimer = 0

    PLAY SIMPLE
    PLAY tune_1

WAIT_MENU:
WAIT
    
    ' Handmatige timer in plaats van MUSIC.PLAYING
    #mTimer = #mTimer + 1
    IF #mTimer > 2000 THEN 
        PLAY tune_1
        #mTimer = 0
    END IF
    
    
    ' --- ANIMATIE LOGICA (Bestaand uit JEWELS_CV.txt [cite: 74-76]) ---
    GOSUB ANIMATEJ

    ' --- MENU NAVIGATIE (Bestaand uit JEWELS_CV.txt [cite: 76-78]) ---
    IF cont1.up AND #choice > 1 THEN 
        #choice = #choice - 1: DO:WAIT:LOOP WHILE cont1.up
    END IF
    IF cont1.down AND #choice < 3 THEN 
        #choice = #choice + 1: DO:WAIT:LOOP WHILE cont1.down
    END IF
    
    ' Cursor tekenen en menu-knoppen afhandelen
    PRINT AT 232, " " : PRINT AT 296, " " : PRINT AT 360, " "
    IF #choice = 1 THEN PRINT AT 232, ">"
    IF #choice = 2 THEN PRINT AT 296, ">"
    IF #choice = 3 THEN PRINT AT 360, ">"

    ' --- SELECTIE AFHANDELEN ---
    IF cont1.button THEN
        DO:WAIT:LOOP WHILE cont1.button
        ' CRUCIAAL: Zet de menu-muziek uit voordat je naar de game gaat
        PLAY OFF 
        IF #choice = 1 THEN GOTO SETUP_GAME
        IF #choice = 2 THEN GOTO INSTRUCTIONS
        IF #choice = 3 THEN GOTO HIGHSCORES
    END IF
    
    
    GOTO WAIT_MENU
            
        
            
'****************************************************************************
' SETUP & GAMEPLAY
'****************************************************************************
SETUP_GAME:

    CLS
 
    
    #score = 0: #lvl = 1: #levelCounter = 0: #fallSpeed = 45 
    FOR #i = 0 TO 89: board(#i) = 0: NEXT #i 
    
    PRINT AT 34, "SCORE: 0"
    PRINT AT 66, "LEVEL: 1"
    PRINT AT 87, "NEXT"
    GOSUB REFRESH_WHOLE_GRID 
    
    
    ' --- GET READY & TUNE ---
    PRINT AT 11 * 32 + 11, "GET READY!"
    PLAY SIMPLE
    PLAY start_game_tune

WAIT_START_TUNE:
    WAIT
    IF MUSIC.PLAYING THEN GOTO WAIT_START_TUNE
    PLAY OFF
    
    ' Korte pauze en wis de tekst door het veld te verversen
    FOR #i = 1 TO 30: WAIT: NEXT #i
    PRINT AT 11 * 32 + 11, "          "
    GOSUB REFRESH_WHOLE_GRID
    ' -------------------------------    
    

    ' De edelstenen gebruiken nu de nieuwe karakter-indices (128, 129, 130)
    #nxtA = 128: #nxtB = 129: #nxtC = 130

NEW_COLUMN:
    #curX = 2: #curY = 0
    #jewA = #nxtA: #jewB = #nxtB: #jewC = #nxtC
    
    #nxtA = RANDOM(5) + 128
    #nxtB = RANDOM(5) + 128
    #nxtC = RANDOM(5) + 128
    
    IF board(#curX + (#curY * 6)) > 0 THEN GOTO GAME_OVER
    GOSUB DRW_PLAYER 

GAME_LOOP:
    WAIT
    #fallTimer = #fallTimer + 1

    ' INPUT
    IF cont1.left AND #curX > 0 THEN
        IF board((#curX-1) + (#curY * 6)) = 0 THEN 
            GOSUB ERASE_PLAYER
            #curX = #curX - 1
            GOSUB DRW_PLAYER
            DO:WAIT:LOOP WHILE cont1.left
        END IF
    END IF
    IF cont1.right AND #curX < 5 THEN
        IF board((#curX+1) + (#curY * 6)) = 0 THEN 
            GOSUB ERASE_PLAYER 
            #curX = #curX + 1 
            GOSUB DRW_PLAYER
            DO:WAIT:LOOP WHILE cont1.right
        END IF
    END IF
    IF cont1.up THEN
        #temp = #jewA: #jewA = #jewB: #jewB = #jewC: #jewC = #temp
        GOSUB DRW_PLAYER
        DO:WAIT:LOOP WHILE cont1.up
    END IF

    ' GRAVITY
    #v = #fallSpeed : IF cont1.down THEN #v = 2 
    IF #fallTimer >= #v THEN
        #fallTimer = 0
        IF #curY < 14 THEN
            IF board(#curX + ((#curY + 1) * 6)) = 0 THEN
                GOSUB ERASE_PLAYER
                #curY = #curY + 1
                GOSUB DRW_PLAYER
            ELSE
                GOTO LOCK_COLUMN
            END IF
        ELSE
            GOTO LOCK_COLUMN
        END IF
    END IF
    GOTO GAME_LOOP

'****************************************************************************
' SCANNEN (H, V, DIAG)
'****************************************************************************
LOCK_COLUMN:
    board(#curX + (#curY * 6)) = #jewA
    IF #curY > 0 THEN board(#curX + ((#curY - 1) * 6)) = #jewB
    IF #curY > 1 THEN board(#curX + ((#curY - 2) * 6)) = #jewC
    GOSUB SCAN_LOGIC
    
    #levelCounter = #levelCounter + 1
    IF #levelCounter >= 25 THEN
        #lvl = #lvl + 1
        #levelCounter = 0
            IF #fallSpeed > 10 THEN #fallSpeed = #fallSpeed - 5
        
        ' --- NIEUW: Level Up Tune ---
        PLAY SIMPLE
        PLAY level_up_tune
    END IF
    GOTO NEW_COLUMN
    
SCAN_LOGIC:
    #found = 0: #totalGemsRemoved = 0
    ' STAP 1: Markeer alle stenen die deel uitmaken van een RECHTE reeks van 3+
    FOR #y = 0 TO 14
     FOR #x = 0 TO 5
        #idx = #x + (#y * 6)
        #v = board(#idx) AND 191 
        
        IF #v >= 128 AND #v <= 132 THEN
            ' --- HORIZONTAAL ---
            IF #x <= 3 THEN
                IF (board(#idx+1) AND 191) = #v AND (board(#idx+2) AND 191) = #v THEN
                    #found = 1: #lineLen = 3
                    IF #x <= 2 THEN IF (board(#idx+3) AND 191) = #v THEN #lineLen = 4
                    IF #x <= 1 THEN IF (board(#idx+4) AND 191) = #v AND #lineLen = 4 THEN #lineLen = 5
                    IF #x = 0  THEN IF (board(#idx+5) AND 191) = #v AND #lineLen = 5 THEN #lineLen = 6
                    FOR #z = 0 TO #lineLen - 1: #t = #idx + #z
                        IF (board(#t) AND 64) = 0 THEN board(#t) = board(#t) OR 64: #totalGemsRemoved = #totalGemsRemoved + 1
                    NEXT #z
                END IF
            END IF
            ' --- VERTICAAL ---
            IF #y <= 12 THEN
                IF (board(#idx+6) AND 191) = #v AND (board(#idx+12) AND 191) = #v THEN
                    #found = 1: #lineLen = 3
                    FOR #z = 3 TO (14 - #y)
                        IF (board(#idx + (#z * 6)) AND 191) = #v THEN #lineLen = #lineLen + 1 ELSE #z = 15
                    NEXT #z
                    FOR #z = 0 TO #lineLen - 1: #t = #idx + (#z * 6)
                        IF (board(#t) AND 64) = 0 THEN board(#t) = board(#t) OR 64: #totalGemsRemoved = #totalGemsRemoved + 1
                    NEXT #z
                END IF
            END IF
            ' --- DIAGONAAL RECHTS-ONDER ---
            IF #x <= 3 AND #y <= 12 THEN
                IF (board(#idx+7) AND 191) = #v AND (board(#idx+14) AND 191) = #v THEN
                    #found = 1: #lineLen = 3
                    IF #x <= 2 AND #y <= 11 THEN IF (board(#idx+21) AND 191) = #v THEN #lineLen = 4
                    IF #x <= 1 AND #y <= 10 THEN IF (board(#idx+28) AND 191) = #v AND #lineLen = 4 THEN #lineLen = 5
                    IF #x = 0  AND #y <= 9  THEN IF (board(#idx+35) AND 191) = #v AND #lineLen = 5 THEN #lineLen = 6
                    FOR #z = 0 TO #lineLen - 1: #t = #idx + (#z * 7)
                        IF (board(#t) AND 64) = 0 THEN board(#t) = board(#t) OR 64: #totalGemsRemoved = #totalGemsRemoved + 1
                    NEXT #z
                END IF
            END IF
            ' --- DIAGONAAL LINKS-ONDER ---
            IF #x >= 2 AND #y <= 12 THEN
                IF (board(#idx+5) AND 191) = #v AND (board(#idx+10) AND 191) = #v THEN
                    #found = 1: #lineLen = 3
                    IF #x >= 3 AND #y <= 11 THEN IF (board(#idx+15) AND 191) = #v THEN #lineLen = 4
                    IF #x >= 4 AND #y <= 10 THEN IF (board(#idx+20) AND 191) = #v AND #lineLen = 4 THEN #lineLen = 5
                    IF #x >= 5 AND #y <= 9  THEN IF (board(#idx+25) AND 191) = #v AND #lineLen = 5 THEN #lineLen = 6
                    FOR #z = 0 TO #lineLen - 1: #t = #idx + (#z * 5)
                        IF (board(#t) AND 64) = 0 THEN board(#t) = board(#t) OR 64: #totalGemsRemoved = #totalGemsRemoved + 1
                    NEXT #z
                END IF
            END IF
        END IF
    NEXT #x
    NEXT #y

' STAP 2: Flash effect met Bom-geluid
IF #found = 1 THEN
    ' Forceer de muziek-engine UIT om handmatige SOUND commando's toe te staan
    PLAY SIMPLE
    PLAY explosion_tune
    
    FOR #z = 1 TO 4 
        #temp = 15 - (#z * 2)
        IF #temp < 0 THEN #temp = 0
        
        ' Toon karakter 133
        FOR #y = 0 TO 14
            FOR #x = 0 TO 5
                #idx = #x + (#y * 6)
                IF (board(#idx) AND 64) THEN
                    #addr = (#y + 4) * 32 + (#x + 13)
                    PRINT AT #addr, CHR$(133)
                END IF
            NEXT #x
        NEXT #y
            
        FOR #i = 1 TO 6: WAIT: NEXT #i 

        ' Toon karakter 134
        FOR #y = 0 TO 14
            FOR #x = 0 TO 5
                #idx = #x + (#y * 6)
                IF (board(#idx) AND 64) THEN
                    #addr = (#y + 4) * 32 + (#x + 13)
                    PRINT AT #addr, CHR$(134)
                END IF
            NEXT #x
        NEXT #y

    NEXT #z
    
    SOUND 3, 0, 0 ' Zet ruis volledig uit
            
        ' Rest van de logica (verwijderen uit array) [cite: 35]
        FOR #i = 0 TO 89
             IF (board(#i) AND 64) THEN board(#i) = 0
        NEXT #i
        
        #score = #score + (#totalGemsRemoved * 10 * #lvl)
        GOSUB APPLY_GRAVITY
        GOSUB REFRESH_WHOLE_GRID
        FOR #i = 1 TO 15: WAIT: NEXT #i 
        GOTO SCAN_LOGIC 
    END IF
            
APPLY_GRAVITY:
    FOR #i = 1 TO 14
        #changed = 0
        FOR #x = 0 TO 5: FOR #y = 14 TO 1 STEP -1
            #idx = #x + (#y * 6)
            IF board(#idx) = 0 AND board(#idx - 6) > 0 THEN
                board(#idx) = board(#idx - 6)
                board(#idx - 6) = 0
                #changed = 1
            END IF
        NEXT #y
        NEXT #x
        ' Als er niets meer verandert, springen we uit de loop naar het einde
        IF #changed = 0 THEN GOTO END_GRAVITY 
    NEXT #i
END_GRAVITY:
    RETURN
    
'****************************************************************************
' DRAWING & INTERFACE
'****************************************************************************
ERASE_PLAYER:
    FOR #i = 0 TO 2
        #ty = #curY - #i
        IF #ty >= 0 AND #ty <= 14 THEN
            #addr = (#ty + 4) * 32 + (#curX + 13)
            #char = board(#ty * 6 + #curX)
            IF #char = 0 THEN PRINT AT #addr, "." ELSE PRINT AT #addr, CHR$(#char)
        END IF
    NEXT #i
    RETURN

DRW_PLAYER:
    #addr = (#curY + 4) * 32 + (#curX + 13)
    IF #curY >= 0 THEN PRINT AT #addr, CHR$(#jewA)
    IF #curY > 0 THEN PRINT AT #addr - 32, CHR$(#jewB)
    IF #curY > 1 THEN PRINT AT #addr - 64, CHR$(#jewC)
    PRINT AT 41, #score: PRINT AT 73, #lvl
    PRINT AT 184, CHR$(#nxtA) : PRINT AT 216, CHR$(#nxtB) : PRINT AT 248, CHR$(#nxtC)
    RETURN

REFRESH_WHOLE_GRID:
    FOR #y = 0 TO 14
        ' Draw Left Border (Column 12) and Right Border (Column 19)
        PRINT AT (#y + 4) * 32 + 12, CHR$(135)
        PRINT AT (#y + 4) * 32 + 19, CHR$(135)        

        FOR #x = 0 TO 5
            #char = board(#y * 6 + #x)
            #addr = (#y + 4) * 32 + (#x + 13)
            IF #char = 0 THEN PRINT AT #addr, "." ELSE PRINT AT #addr, CHR$(#char)
        NEXT #x
    NEXT #y

    ' Draw Bottom Border (Row 19, from Column 12 to 19)
    FOR #x = 12 TO 19
        PRINT AT 19 * 32 + #x, CHR$(138)
    NEXT #x

    PRINT AT 19 * 32 + 12, CHR$(136)
    PRINT AT 19 * 32 + 19, CHR$(137)


    RETURN

'****************************************************************************
' DATA: GEM PATTERNS & COLORS
'****************************************************************************
gem_patterns:
    ' 128: Diamond 1
    BITMAP "        "
    BITMAP "  XXXX  "
    BITMAP " XX  XX "
    BITMAP " X    X "
    BITMAP " X    X "
    BITMAP " XX  XX "
    BITMAP "  XXXX  "
    BITMAP "        "
    ' 129: Diamond 2
    BITMAP "        "
    BITMAP " XXXXXX "
    BITMAP " X    X "
    BITMAP " X XX X "
    BITMAP " X XX X "
    BITMAP " X    X "
    BITMAP " XXXXXX "
    BITMAP "        "
    ' 130: Diamond 3
    BITMAP "        "
    BITMAP " X XX X "
    BITMAP "  XXXX  "
    BITMAP " XX  XX "
    BITMAP " XX  XX "
    BITMAP "  XXXX  "
    BITMAP " X XX X "
    BITMAP "        "
    ' 131: Diamond 4
    BITMAP "        "
    BITMAP " XXXXXX "
    BITMAP "  XXXX  "
    BITMAP "XXX  XXX"
    BITMAP "XXX  XXX"
    BITMAP "  XXXX  "
    BITMAP " XXXXXX "
    BITMAP "        "
    ' 132: Diamond 5
    BITMAP "        "
    BITMAP " XXXXXX "
    BITMAP "  XXXX  "
    BITMAP " X XX X "
    BITMAP " X XX X "
    BITMAP "  XXXX  "
    BITMAP " XXXXXX "
    BITMAP "        "
    ' 133: Clear 1
    BITMAP "        "
    BITMAP "  x  X  "
    BITMAP " X  X  X"
    BITMAP "  X  X  "
    BITMAP " X  X  X"
    BITMAP "  X  X  "
    BITMAP " X  X  x"
    BITMAP "        "
    ' 134: Clear 2
    BITMAP "        "
    BITMAP " x  X  X"
    BITMAP "X  X  X "
    BITMAP " X  X  X"
    BITMAP "X  X  X "
    BITMAP " X  X  X"
    BITMAP "X  X  x "
    BITMAP "        "

    ' 135: Border1
    BITMAP "  XXXX  "
    BITMAP "  xXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    ' 136: Border2
    BITMAP "  XXXX  "
    BITMAP "  xXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXXXX"
    BITMAP "  XXXXXX"
    BITMAP "  XXXXXX"
    BITMAP "   XxXXX"
    ' 137: Border3
    BITMAP "  XXXX  "
    BITMAP "  xXXX  "
    BITMAP "  XXXX  "
    BITMAP "  XXXX  "
    BITMAP "XXXXXX  "
    BITMAP "XXXXXX  "
    BITMAP "XXXXXX  "
    BITMAP "XXXXX   "
    ' 138: Border4
    BITMAP "        "
    BITMAP "        "
    BITMAP "        "
    BITMAP "        "
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

gem_colors:
    ' Kleuren: Voorgrond (1-15) op Achtergrond (1)
    DATA BYTE $91, $91, $91, $91, $91, $91, $91, $91 ' Diamond 1
    DATA BYTE $A1, $A1, $A1, $A1, $A1, $A1, $A1, $A1 ' Diamond 2
    DATA BYTE $71, $71, $71, $71, $71, $71, $71, $71 ' Diamond 3
    DATA BYTE $C1, $C1, $C1, $C1, $C1, $C1, $C1, $C1 ' Diamond 4
    DATA BYTE $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1 ' Diamond 5
    
    DATA BYTE $F1, $F1, $F1, $F1, $F1, $F1, $F1, $F1 ' Clear 1
    DATA BYTE $F1, $F1, $F1, $F1, $F1, $F1, $F1, $F1 ' Clear 2

    DATA BYTE $41, $71, $41, $71, $41, $71, $41, $71 ' Border1 colors
    DATA BYTE $41, $71, $41, $71, $41, $71, $41, $71 ' Border2 colors
    DATA BYTE $41, $71, $41, $71, $41, $71, $41, $71 ' Border3 colors
    DATA BYTE $41, $71, $41, $71, $41, $71, $41, $71 ' Border4 colors
    
title_patterns:   
    ' 140: C
    BITMAP "        "
    BITMAP "  XXXX  "
    BITMAP " XXXXXX "
    BITMAP "     XX "
    BITMAP "     xx "
    BITMAP " XX  XX "
    BITMAP "  XXXX  "
    BITMAP "        "
    ' 141: O
    BITMAP "        "
    BITMAP "  XXXX  "
    BITMAP " XX  XX "
    BITMAP " XXXXXX "
    BITMAP " XX     " 
    BITMAP " XX  XX "
    BITMAP "  XXXX  "
    BITMAP "        "
    ' 142: L
    BITMAP "        "
    BITMAP " XXX   X"
    BITMAP " XX    X"
    BITMAP " XX    X"
    BITMAP " XX XX X"
    BITMAP " XX XX X"
    BITMAP "  XXXXXX"
    BITMAP "        "
    ' 143: U
    BITMAP "        "
    BITMAP "  XXXX  "
    BITMAP " XX  XX "
    BITMAP " XXXXXX "
    BITMAP " XX     "
    BITMAP " XX  XX "
    BITMAP "  XXXX  "
    BITMAP "        "
    ' 144: M
    BITMAP "        "
    BITMAP " XX     "
    BITMAP " XX     "
    BITMAP " XX     "
    BITMAP " XX  xX "
    BITMAP " XX  xX "
    BITMAP "  XxxX  "
    BITMAP "        "
    ' 145: N
    BITMAP "        "
    BITMAP "  Xxxx  "
    BITMAP " XX  XX "
    BITMAP "  XXX   "
    BITMAP "     XX "
    BITMAP " XX  XX "
    BITMAP "  Xxxx  "
    BITMAP "        "
 

title_colors:
    ' Kleuren: Voorgrond (1-15) op Achtergrond (1)
    DATA BYTE $91, $91, $91, $91, $91, $91, $91, $91 ' J
    DATA BYTE $B1, $B1, $B1, $B1, $B1, $B1, $B1, $B1 ' E
    DATA BYTE $71, $71, $71, $71, $71, $71, $71, $71 ' W
    DATA BYTE $61, $61, $61, $61, $61, $61, $61, $61 ' E
    DATA BYTE $51, $51, $51, $51, $51, $51, $51, $51 ' L
    DATA BYTE $A1, $A1, $A1, $A1, $A1, $A1, $A1, $A1 ' S
    

'****************************************************************************
' MUSIC DATA
'****************************************************************************
start_game_tune:
    DATA BYTE 5  ' Snelheid
    MUSIC C4, -
    MUSIC E4, -
    MUSIC G4, -
    MUSIC C5, -
    MUSIC STOP
    
game_over_tune:
    DATA BYTE 6  ' Snelheid van de muziek
    MUSIC G4, -
    MUSIC E4, -
    MUSIC C4, -
    MUSIC C3, -  ' Een lage eindnoot voor het "sad" effect
    MUSIC STOP    
    
level_up_tune:
    DATA BYTE 4  ' Iets sneller dan de game over tune
    MUSIC C5, -
    MUSIC E5, -
    MUSIC G5, -
    MUSIC C6, -  ' Een vrolijke, stijgende reeks noten
    MUSIC STOP

explosion_tune:
    DATA BYTE 3  ' Zeer hoge snelheid
    MUSIC C5, -
    MUSIC G5, -
    MUSIC C6, -
    MUSIC STOP
        
tune_1:	DATA BYTE 7
	MUSIC F4,-
	MUSIC S,-
	MUSIC A4,-
	MUSIC S,-
	MUSIC F4,-
	MUSIC S,-
	MUSIC C5,-
	MUSIC S,-
	MUSIC F4,-
	MUSIC S,-

	MUSIC F5,-
	MUSIC S,-
	MUSIC E5,F3
	MUSIC D5,S
	MUSIC C5,A3
	MUSIC D5,S
	MUSIC C5,F3
	MUSIC A4#,S
	MUSIC A4,C4
	MUSIC A4#,S
	MUSIC A4,F3
	MUSIC G4,S

	MUSIC F4,F4
	MUSIC S,S
	MUSIC A4,E4
	MUSIC S,D4
	MUSIC C5,C4
	MUSIC S,D4
	MUSIC A4,C4
	MUSIC S,A3#
	MUSIC F5,A3
	MUSIC S,A3#
	MUSIC C5,A3
	MUSIC S,G3

	MUSIC A5,F3
	MUSIC C6,S
	MUSIC A5#,A3
	MUSIC C6,S
	MUSIC A5,C4
	MUSIC C6,S
	MUSIC A5#,A3
	MUSIC C6,S
	MUSIC A5,F4
	MUSIC C6,S
	MUSIC A5#,C4
	MUSIC C6,S

	MUSIC F5,A3
	MUSIC A5,C4
	MUSIC G5,A3#
	MUSIC A5,C4
	MUSIC F5,A3
	MUSIC A5,C4
	MUSIC G5,A3#
	MUSIC A5,C4
	MUSIC F5,A3
	MUSIC A5,C4
	MUSIC G5,A3#
	MUSIC A5,C4

	MUSIC D5,F3
	MUSIC F5,A3
	MUSIC E5,G3
	MUSIC F5,A3
	MUSIC D5,F3
	MUSIC F5,A3
	MUSIC E5,G3
	MUSIC F5,A3
	MUSIC D5,F3
	MUSIC F5,A3
	MUSIC E5,G3
	MUSIC F5,A3

	MUSIC B4,D3
	MUSIC S,F3
	MUSIC G4,E3
	MUSIC S,F3
	MUSIC D5,D3
	MUSIC S,F3
	MUSIC B4,E3
	MUSIC S,F3
	MUSIC F5,D3
	MUSIC S,F3
	MUSIC D5,E3
	MUSIC S,F3

	MUSIC G5,B3
	MUSIC A5,S
	MUSIC G5,G3
	MUSIC F5,S
	MUSIC E5,C4
	MUSIC F5,S
	MUSIC E5,G3
	MUSIC D5,S
	MUSIC C5,E4
	MUSIC D5,S
	MUSIC C5,C4
	MUSIC A4#,S

	MUSIC A4,F4
	MUSIC S,G4
	MUSIC D5,F4
	MUSIC C5,E4
	MUSIC B4,D4
	MUSIC C5,E4
	MUSIC B4,D4
	MUSIC A4,C4
	MUSIC G4,B3
	MUSIC A4,C4
	MUSIC G4,B3
	MUSIC F4,A3

	MUSIC E4,G3
	MUSIC F4,S
	MUSIC E4,C4
	MUSIC D4,B3
	MUSIC C4,A3
	MUSIC S,B3
	MUSIC C5,A3
	MUSIC B4,G3
	MUSIC C5,F3
	MUSIC S,G3
	MUSIC E4,F3
	MUSIC S,E3

	MUSIC F4,D3
	MUSIC S,E3
	MUSIC C5,D3
	MUSIC S,C3
	MUSIC E4,G3
	MUSIC S,F3
	MUSIC C5,E3
	MUSIC S,F3
	MUSIC D4,G3
	MUSIC S,S
	MUSIC B4,G2
	MUSIC S,S

	MUSIC C5,C4
	MUSIC S,S
	MUSIC S,S
	MUSIC S,S
	MUSIC STOP


TITLE_LOGO:
    #Y=3
    #LETTER=140
    FOR #X = 0 TO 5
        #addr = #Y * 32 + #X + 13:  PRINT AT #addr, CHR$(#LETTER)    
        #LETTER = #LETTER + 1
    NEXT #X    
    RETURN


'****************************************************************************
' MENUS
'****************************************************************************
INSTRUCTIONS:
    CLS
    GOSUB INITJ
    GOSUB TITLE_LOGO
    #addr = 6 * 32 + 10: PRINT AT #addr, "INSTRUCTIONS"
    PRINT AT 8 * 32 + 5,  " Jewels fall from sky. "
    PRINT AT 9 * 32 + 5,  " Match colors in line  "
    PRINT AT 10 * 32 + 5, "Three shine,  then fade"
    PRINT AT 11 * 32 + 5, "  Chain combos appear  "
    PRINT AT 12 * 32 + 5, "Think fast, stack smart"
    PRINT AT 13 * 32 + 5, " More gems keep coming "
    PRINT AT 14 * 32 + 5, "  Don't fill the well! "
    PRINT AT 15 * 32 + 5, "   Retro arcade fun.   "

    PRINT AT 17 * 32 + 5, "CURSOR LF/RH =MOVE    "
    PRINT AT 18 * 32 + 5, "CURSOR UP    =SHUFFLE "
    PRINT AT 19 * 32 + 5, "CURSOR DOWN  =FAST DWN"

LOOP_INSTR:
    WAIT
    GOSUB ANIMATEJ  ' Update de scrollende randen elke frame
    IF cont1.button = 0 THEN GOTO LOOP_INSTR ' Blijf animeren tot knopdruk
    
    ' Wacht tot knop wordt losgelaten voor we teruggaan
    DO:WAIT:LOOP WHILE cont1.button <> 0
    GOTO INTROSCREEN
     
HIGHSCORES:
    CLS
    GOSUB INITJ
    GOSUB TITLE_LOGO

    PRINT AT 6 * 32 + 8, "! HALL OF FAME !"

    ' Positie 1
    #addr = 10 * 32 + 5: IF #u1 = 1 THEN PRINT AT #addr, "1. PLAYER......" ELSE PRINT AT #addr, "1. JEWELS......"
    PRINT AT 10 * 32 + 20, #h1: PRINT AT 10 * 32 + 27, #l1

    ' Positie 2
    #addr = 11 * 32 + 5: IF #u2 = 1 THEN PRINT AT #addr, "2. PLAYER......" ELSE PRINT AT #addr, "2. JEWELS......"
    PRINT AT 11 * 32 + 20, #h2: PRINT AT 11 * 32 + 27, #l2

    ' Positie 3
    #addr = 12 * 32 + 5: IF #u3 = 1 THEN PRINT AT #addr, "3. PLAYER......" ELSE PRINT AT #addr, "3. JEWELS......"
    PRINT AT 12 * 32 + 20, #h3: PRINT AT 12 * 32 + 27, #l3

    ' Positie 4
    #addr = 13 * 32 + 5: IF #u4 = 1 THEN PRINT AT #addr, "4. PLAYER......" ELSE PRINT AT #addr, "4. JEWELS......"
    PRINT AT 13 * 32 + 20, #h4: PRINT AT 13 * 32 + 27, #l4

    ' Positie 5
    #addr = 14 * 32 + 5: IF #u5 = 1 THEN PRINT AT #addr, "5. PLAYER......" ELSE PRINT AT #addr, "5. JEWELS......"
    PRINT AT 14 * 32 + 20, #h5: PRINT AT 14 * 32 + 27, #l5

LOOP_HIGH:
    WAIT: GOSUB ANIMATEJ
    IF cont1.button = 0 THEN GOTO LOOP_HIGH
    DO:WAIT:LOOP WHILE cont1.button <> 0
    GOTO INTROSCREEN
         
CHECKSCORE:
    #isNewHS = 0  ' Reset de vlag aan het begin 
    IF #score > #h1 THEN
        #h5=#h4: #l5=#l4: #u5=#u4: #h4=#h3: #l4=#l3: #u4=#u3
        #h3=#h2: #l3=#l2: #u3=#u2: #h2=#h1: #l2=#l1: #u2=#u1
        #h1=#score: #l1=#lvl: #u1=1
        #isNewHS = 1  ' <--- Markeer als nieuwe highscore
        RETURN
    END IF
    IF #score > #h2 THEN
        #h5=#h4: #l5=#l4: #u5=#u4: #h4=#h3: #l4=#l3: #u4=#u3
        #h3=#h2: #l3=#l2: #u3=#u2
        #h2=#score: #l2=#lvl: #u2=1
        #isNewHS = 1  ' <--- Markeer als nieuwe highscore
        RETURN
    END IF
    IF #score > #h3 THEN
        #h5=#h4: #l5=#l4: #u5=#u4: #h4=#h3: #l4=#l3: #u4=#u3
        #h3=#score: #l3=#lvl: #u3=1
        #isNewHS = 1  ' <--- Markeer als nieuwe highscore
        RETURN
    END IF
    IF #score > #h4 THEN
        #h5=#h4: #l5=#l4: #u5=#u4
        #h4=#score: #l4=#lvl: #u4=1
        #isNewHS = 1  ' <--- Markeer als nieuwe highscore
        RETURN
    END IF
    IF #score > #h5 THEN
        #h5=#score: #l5=#lvl: #u5=1
        #isNewHS = 1  ' <--- Markeer als nieuwe highscore
        RETURN
    END IF
    RETURN
      
GAME_OVER:
    #addr = 10 * 32 + 11: PRINT AT #addr, "GAME OVER!"
    
    GOSUB CHECKSCORE

    ' Start de korte tune
    PLAY SIMPLE
    PLAY game_over_tune

WAIT_FOR_TUNE:
    WAIT
    ' Blijf wachten zolang de muziek nog speelt
    IF MUSIC.PLAYING THEN GOTO WAIT_FOR_TUNE
    
    ' Korte extra pauze na de muziek
    FOR #i = 1 TO 100: WAIT: NEXT #i
    
    ' Beslis naar welk scherm we gaan
    IF #isNewHS = 1 THEN GOTO HIGHSCORES
     
    GOTO INTROSCREEN
    
'****************************************************************************
' INIT JEWELS
'****************************************************************************
INITJ:    
    PRINT AT 0
    #Y=0
    #JEWEL=128
    FOR #X = 0 TO 31 
       #pos =  ((#Y * 32) + #X)
       PRINT AT #pos ,CHR$(#JEWEL)
       #JEWEL=#JEWEL+1
       IF #JEWEL=132 THEN #JEWEL=128
    NEXT #X
    #Y=23
    #JEWEL=128
    FOR #X = 0 TO 31 
       #pos =  ((#Y * 32) + #X)
       PRINT AT #pos ,CHR$(#JEWEL)
       #JEWEL=#JEWEL+1
       IF #JEWEL=132 THEN #JEWEL=128
    NEXT #X
    RETURN

'****************************************************************************
' ANIMATE JEWELS
'****************************************************************************
ANIMATEJ:
    #animTimer = #animTimer + 1
    IF #animTimer >= 8 THEN
    

        #animTimer = 0: #animFrame = #animFrame + 1
        ' Lijn 0: Van links naar rechts scrollen
        FOR #X = 0 TO 31
            #jewel = ((#X - #animFrame) AND 3) + 128
            PRINT AT #X, CHR$(#jewel)
        NEXT #X
        ' Lijn 23: Van rechts naar links scrollen
        FOR #X = 0 TO 31
            #jewel = ((#X + #animFrame) AND 3) + 128
            PRINT AT 736 + #X, CHR$(#jewel)
        NEXT #X
    END IF
    RETURN        
    
    '[CVBasicIDE Editor]
