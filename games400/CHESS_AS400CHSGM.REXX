call initialize

say 'Type help if you need instructions'
say ''

call DisplayBoard
do while answer <> 'QUIT'
   say 'Enter a move for' ColorToMove':'
   parse upper pull answer
   tmpvar = word( answer, 1 )
   select
      when tmpvar = 'QUIT' then
         exit
      when tmpvar = 'HELP' then
         call usage
      when tmpvar = 'REFRESH' then
         call DisplayBoard
      when tmpvar = 'RESIGN' then
      do
         LastMove = 'RESIGN'
         call SavePosition
         say 'Your resignation is recorded and your opponent notified.'
         say 'Better luck next time...'
         exit
      end
      when tmpvar = 'SAVE' then
      do
         call SavePosition
         say 'Your board has been saved and your opponent notified.'
         say 'Thanks for playing...'
         MoveMsg = overlay( game_id, MoveMsg, 7, 10 )
         MoveMsg = overlay( user_id, MoveMsg, 29, 10 )
         'SNDPGMMSG',
         '  MSG(&MoveMsg)',
         '  TOUSR(&opponent)'
         exit
      end
      when tmpvar = 'UNDO' then
      do
         if UndoState = TRUE then
         do
            call UndoLastMove
            call DisplayBoard
         end
      end
      otherwise
      do
         if ValidMove( answer ) then
         do
            LastMove = answer
            call UpdateBoard
            call DisplayBoard
         end
         else
            say 'Invalid move or command, retry...'
      end
   end
end

exit

ToggleMove:

if ColorToMove = 'White' then
   ColorToMove = 'Black'
else
   ColorToMove = 'White'

return

UndoLastMove:

Piece = substr( Board.Line.ToRow, Col2, 1 )
Board.Line.ToRow = overlay( SavedPiece, Board.Line.ToRow, Col2 )
Board.Line.FromRow = overlay( Piece, Board.Line.FromRow, Col1 )
UndoState = FALSE
call ToggleMove
return

UpdateBoard:

Piece = substr( Board.Line.FromRow, Col1, 1 )
SavedPiece = substr( Board.Line.ToRow, Col2, 1 )
/* Determine if the row is odd/even and save the appropriate marker */
if verify( FromRow, '1357' ) = 0 then
   BoardMarker = substr( Board.StdLine.1, Col1, 1 )
else
   BoardMarker = substr( Board.StdLine.2, Col1, 1 )

Board.Line.ToRow   = overlay( Piece, Board.Line.ToRow, Col2 )
Board.Line.FromRow = overlay( BoardMarker, Board.Line.FromRow, Col1 )

call ToggleMove

UndoState = TRUE

return

ValidMove:

arg move

FromPos = word( move, 1 )
ToPos   = word( move, 2 )
FromCol = substr( FromPos, 1, 1 )
FromRow = substr( FromPos, 2, 1 )
ToCol   = substr( ToPos, 1, 1 )
ToRow   = substr( ToPos, 2, 1 )

if length( FromPos ) <> 2 | length( ToPos ) <> 2 then
   return FALSE
if FromPos = ToPos then
   return FALSE

if verify( FromCol||ToCol, 'ABCDEFGH' ) = 0 &,
   verify( FromRow||ToRow, '12345678' ) = 0 then
   do
      Col1 = ConvertColumn( FromCol )
      Col2 = ConvertColumn( ToCol )

      TempPiece = substr( Board.Line.FromRow, Col1, 1 )
      if (ColorToMove = 'White' & verify(TempPiece,'rnbqkp')<>0),
       | (ColorToMove = 'Black' & verify(TempPiece,'RNBQKP')<>0) then
         return FALSE
      if verify( translate( TempPiece ), 'RNBQKP' ) = 0 then
            return TRUE
   end

return FALSE

ConvertColumn:
arg Column
      if Column = 'A' then return 1
      if Column = 'B' then return 3
      if Column = 'C' then return 5
      if Column = 'D' then return 7
      if Column = 'E' then return 9
      if Column = 'F' then return 11
      if Column = 'G' then return 13
      if Column = 'H' then return 15

return FALSE

DisplayBoard:

say ''
do i = 8 to 1 by -1
   say i ' ' Board.Line.i
end
say ''
say '   ' Board.Line.0
say ''

return

initialize:

TRUE = 1
FALSE = 0
valid = FALSE
ColorToMove = 'White'
LastMove = ''
StrtMsg  = 'A chess game has been initiated by:           ',
           ' as game:           '
MoveMsg   = 'Game:           , opponent:             Your move|'

Board.Line.8  = 'R N B Q K B N R'
Board.Line.7  = 'P P P P P P P P'
Board.Line.6  = '- * - * - * - *'
Board.Line.5  = '* - * - * - * -'
Board.Line.4  = '- * - * - * - *'
Board.Line.3  = '* - * - * - * -'
Board.Line.2  = 'p p p p p p p p'
Board.Line.1  = 'r n b q k b n r'
Board.Line.0  = 'a b c d e f g h'

Board.StdLine.2  = '- * - * - * - *'
Board.StdLine.1  = '* - * - * - * -'

'RTVJOBA',
'  USER(&user_id)'
'RTVUSRPRF',
'  TEXT(&user_text)'
user_id_text = strip( user_text )
user_id_text = word( user_text, 1 )
say 'Hello' user_id_text', welcome to CHESS on the AS/400'
say 'Enter game to continue or press <ENTER> for a new game...'
parse upper pull game_id

if game_id = '' then
do
   new_game = TRUE
   valid = FALSE
   do while valid = FALSE
      say 'Who will you be playing against?  Enter their AS/400 user ID'
      parse upper pull opponent
      if opponent = '' then
        exit
      say 'Checking ' opponent
      'CHKOBJ',
      '   OBJ(&opponent)',
      '   OBJTYPE(*USRPRF)'
      if rc = 0 then do
         valid = TRUE
         say 'OK.'
      end
   end
   color = ''
   do until color = 'W' | color = 'B'
      say 'Would you like to be White or Black? <W/B>'
      parse upper pull color
   end
   valid = FALSE
   do while valid = FALSE
      say 'What name would you like to save this game as?'
      parse upper pull game_id
      'CRTDTAARA',
      '   DTAARA(QGPL/&game_id)',
      '   TYPE(*CHAR)',
      '   LEN(158)'
      if rc = 'CPF1023' then
         say 'That game already exists!  Try a new name...'
      else
         valid = TRUE
   end

   game_data = ''
   game_data = overlay( game_id, game_data, 1, 10 )
   game_data = overlay( user_id, game_data, 11, 10 )
   game_data = overlay( opponent, game_data, 21, 10 )
   game_data = overlay( color, game_data, 31, 1 )
   game_data = overlay( '      ', game_data, 32, 6 )
   game_data = overlay( ' ', game_data, 38, 1 )

   do i = 1 to 8
      game_data = overlay( Board.line.i, game_data, 39+((i-1)*15), 15 )
   end
   'CHGDTAARA',
   '   DTAARA(&game_id)',
   '   VALUE(&game_data)'
   if rc <> 0 then
   do
      say 'An error occurred, contact Steve Allen @ 3094 for help.'
      say 'The error was: ' rc
      exit
   end

   if color = 'B' then
   do
      say 'The game has been setup and your opponent notified'
      say 'thanks for playing and good luck...               '
      StrtMsg = overlay( user_id, StrtMsg, 37, 10 )
      StrtMsg = overlay( game_id, StrtMsg, 58, 10 )
      'SNDPGMMSG',
      '  MSG(&StrtMsg)',
      '  TOUSR(&opponent)'
      exit
   end
   else
      say 'New game has begun, good luck'
end
else
   new_game = FALSE

if new_game = FALSE then
do
   valid = FALSE
   do while valid = FALSE
      'RTVDTAARA',
      '   DTAARA(&game_id)',
      '   RTNVAR(&game_data)'
      if rc = 'CPF1015' then
      do
         say 'That game does not exist, check spelling and retry...'
         say 'Enter game to retrieve or QUIT to quit...'
         parse upper pull game_id
         if game_id = 'QUIT' then
            exit
      end
      else
         valid = TRUE
   end
   data_area    = substr( game_data, 1, 10   )
   white_player = substr( game_data, 11, 10  )
   black_player = substr( game_data, 21, 10  )
   color        = substr( game_data, 31, 1   )
   if color = 'W' then
      ColorToMove = 'White'
   else
      ColorToMove = 'Black'
   if color = 'W' & white_player <> user_id  | ,
      color = 'B' & black_player <> user_id then
   do
      say 'Your opponent has not made a move yet, try later...'
      exit
   end
   if user_id = white_player then
      opponent = black_player
   else
      opponent = white_player
   LastMove     = substr( game_data, 32, 6   )
   if LastMove = 'RESIGN' then
   do
      say 'Congratulations, your opponent has resigned!'
      say ' Keep up the good work...'
      exit
   end
   SavedPiece   = substr( game_data, 38, 1   )

   do i = 1 to 8
      Board.Line.i = substr( game_data, 39+((i-1)*15), 15 )
   end
end

UndoState = FALSE

return

SavePosition:

game_data = overlay( ColorToMove, game_data, 31, 1 )
game_data = overlay( LastMove, game_data, 32, 6 )
game_data = overlay( SavedPiece, game_data, 38, 1 )

do i = 1 to 8
   game_data = overlay( Board.line.i, game_data, 39+((i-1)*15), 15 )
end

'CHGDTAARA',
'   DTAARA(&game_id)',
'   VALUE(&game_data)'
   if rc <> 0 then
   do
      say 'An error occurred, contact Steve Allen @ 3094 for help.'
      say 'The error was: ' rc
      exit
   end
return

usage:
say 'Enter move in algebraic notation.          '
say '  format is: from to'
say '  for example:  e2 e4 means move piece on e2 to e4 square'
say ''
say 'QUIT   = quit this program'
say 'HELP   = display this screen'
say 'REFRESH= Redisplay board'
say 'SAVE   = Save your position and notify your opponent'
say ''
return
