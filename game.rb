require 'colorize'
require 'net/ssh'

class Cell
    attr_accessor :left
    attr_accessor :right
    attr_accessor :up
    attr_accessor :down
    attr_accessor :inside

    def initialize
        @left = false
        @right = false
        @up = false
        @down = false
        @inside = 0
    end

    def swap # swaps up with down and left with right
        a = @up
        @up = @down
        @down = a 

        a = @left
        @left = @right
        @right = a
    end
end

class Wall          
    attr_accessor :row
    attr_accessor :col
    attr_accessor :alignment
    attr_accessor :centerR
    attr_accessor :centerC
    def initialize(a, er, ec)
        @row = er
        @col = ec
        @alignment = a 
        
        if a == true
            @centerR = er 
            @centerC = ec + 1
        else
            @centerR = er + 1
            @centerC = ec 
            
        end
    end

    def swap
        @centerR = 9 - @centerR
        @centerC = 9 - @centerC

        if @alignment == true
            @row = @centerR 
            @col = @centerC - 1
        else
            @row = @centerR - 1
            @col = @centerC 
            
        end
    end


end

class GameBoard
    attr_accessor :cells
    attr_accessor :turn
    attr_accessor :wallList
    attr_accessor :p1Walls
    attr_accessor :p2Walls

    def initialize
        @cells = Array.new(9) { Array.new(9) { Cell.new } }
        @cells[0][4].inside = 2
        @cells[8][4].inside = 1
        @turn = true # true: p1, false: p2
        @wallList = []
        @p1Walls = 10
        @p2Walls = 10
        
        for i in 0..8
            for j in 0..8
                if i == 0
                    @cells[i][j].up = true
                elsif i == 8
                    @cells[i][j].down = true
                end
                if j == 0
                    @cells[i][j].left = true
                elsif j == 8
                    @cells[i][j].right = true
                end
            end
        end
    end

    def toString
        str ="╔".white
        for i in 0..8
            if @cells[0][i].up == false
                str += "═══".black
            else
                str += "═══".white
            end

            str += "╦".white if i != 8
                
        end
        str += "╗".white
        str += "\n"
        a = 0
        for i in @cells do
            if i[0].left == false
                str += "║".black
            else
                str += "║".white
            end

            for j in i do
                str += " "
                if j.inside == 0
                    str += " "
                    #str += j.up.to_s[0]
                elsif j.inside == 1
                    str += j.inside.to_s.red
                else
                    str += j.inside.to_s.yellow
                end
                str += " "
                if j.right == false
                    str += "║".black
                else
                    str += "║".white
                end
            end
            cnt = 0
            str += "\n"
            if a != 8
                str += "╠".white
                
            else
                str += "╚".white
            end
            for j in i do
                if j.down == false
                    str += "═══".black
                else
                    str += "═══".white
                end
                
                if a == 8 and cnt != 8
                    str += "╩".white
                    

                elsif cnt != 8
                    if hasCenter(a+1,cnt+1)
                        str += "╬".white
                    else
                        str += "╬".black
                    end
                end

                if cnt == 8 
                    if a != 8
                        str += "╣".white
                    else
                       str += "╝".white
                    end
                end
                cnt += 1
            end
            str += "\n"
            a += 1
        end
        return str
    end

    def toStringReverse # returns board from player2's view
        
        backup = Marshal.load(Marshal.dump(@cells))
        backupWalls = Marshal.load(Marshal.dump(@wallList))
        
        a = []
        for i in @cells
            a.unshift(i.reverse())
        end

        for i in a
            for j in i
                j.swap
            end
        end
        
        for k in @wallList
            k.swap
        end

        @cells = a
        toreturn = toString()
        @cells = backup
        @wallList = backupWalls
        return toreturn
    end

    def findPlayer(player)
        a = 0
        b = 0
        for i in @cells do
            b=0
            for j in i do
                if j.inside == player 
                    arr = []
                    arr.append(a)
                    arr.append(b)
                    return arr
                end
                b += 1  
            end
            a += 1
        end
    end

    # 5 1 6
    # 3 x 4
    # 7 2 8
    def movePlayer(playerToMove, direction) # 1 up, 2 down, 3 left, 4 right
        row = findPlayer(playerToMove)[0]
        column = findPlayer(playerToMove)[1]
        if direction == 1 # go up
            if row == 0 
                return false
            elsif @cells[row][column].up == true
                return false
            end

            if @cells[row-1][column].inside == 0
                @cells[row][column].inside = 0
                @cells[row-1][column].inside = playerToMove
            else
                if @cells[row-1][column].up == false
                    @cells[row][column].inside = 0
                    @cells[row-2][column].inside = playerToMove
                else
                    return false
                end
            end
        
        elsif direction == 2 # go down
            if row == 8
                return false
            end
            if @cells[row][column].down == true
                return false
            end

            if @cells[row+1][column].inside == 0
                @cells[row][column].inside = 0
                @cells[row+1][column].inside = playerToMove
            else
                if @cells[row+1][column].down == false
                    @cells[row][column].inside = 0
                    @cells[row+2][column].inside = playerToMove
                else
                    return false
                end
            end
        
        elsif direction == 3 # go left
            return false if column == 0
                
            return false if @cells[row][column].left == true
                
            if @cells[row][column-1].inside == 0
                @cells[row][column].inside = 0
                @cells[row][column-1].inside = playerToMove
            else
                if @cells[row][column-1].left == false
                    @cells[row][column].inside = 0
                    @cells[row][column-2].inside = playerToMove
                else
                    return false
                end
            end
        elsif direction == 4 # go right
            return false if column == 8
            return false if @cells[row][column].right == true
                
            if @cells[row][column+1].inside == 0
                @cells[row][column].inside = 0
                @cells[row][column+1].inside = playerToMove
            else
                if @cells[row][column+1].right == false
                    @cells[row][column].inside = 0
                    @cells[row][column+2].inside = playerToMove
                else
                    return false
                end
            end
        elsif direction == 5 # top left
            if row == 0 || column == 0
                return false
            elsif @cells[row-1][column].inside != 0 && @cells[row-1][column].up == true && @cells[row-1][column].left == false
                @cells[row][column].inside = 0
                @cells[row-1][column-1].inside = playerToMove
            elsif @cells[row][column-1].inside != 0 && @cells[row][column-1].left == true && @cells[row][column-1].up == false
                @cells[row][column].inside = 0
                @cells[row-1][column-1].inside = playerToMove
            else
                return false
            end

        elsif direction == 6 # top right
            if row == 0 || column == 8
                return false
            elsif @cells[row-1][column].inside != 0 && @cells[row-1][column].up == true && @cells[row-1][column].right == false
                @cells[row][column].inside = 0
                @cells[row-1][column+1].inside = playerToMove
            elsif @cells[row][column+1].inside != 0 && @cells[row][column+1].right == true && @cells[row][column+1].up == false
                @cells[row][column].inside = 0
                @cells[row-1][column+1].inside = playerToMove
            else
                return false
            end
        elsif direction == 7 # bottom left
            if row == 8 || column == 0
                return false
            elsif @cells[row][column-1].inside != 0 && @cells[row][column-1].left == true && @cells[row][column-1].down == false
                @cells[row][column].inside = 0
                @cells[row+1][column-1].inside = playerToMove
            elsif @cells[row+1][column].inside != 0 && @cells[row+1][column].down == true && @cells[row+1][column].left == false
                @cells[row][column].inside = 0
                @cells[row+1][column-1].inside = playerToMove
            else
                return false
            end
        elsif direction == 8 # bottom right
            if row == 8|| column == 8
                return false
            elsif @cells[row][column+1].inside != 0 && @cells[row][column+1].right == true && @cells[row][column+1].down == false
                @cells[row][column].inside = 0
                @cells[row+1][column+1].inside = playerToMove
            elsif @cells[row+1][column].inside != 0 && @cells[row+1][column].down == true && @cells[row+1][column].right == false
                @cells[row][column].inside = 0
                @cells[row+1][column+1].inside = playerToMove
            else
                return false
            end
        else
            return false
        end
        return true
    end

    def move(direction) # moves with current player
        if @turn == true
            pl = 1
        else
            pl = 2
        end
        a = movePlayer(pl, direction)
        if a == true
            @turn = !turn
            return true
        end
        return false
    end

    def addWall(alignment, row, col) # alignment: true horizontal, false vertical
        if row < 0 || col < 0
            return false
        elsif row > 9 || col > 9
            return false
        elsif alignment == false && row > 7
            return false
        elsif alignment == true && col > 7
            return false
        elsif alignment == false && hasCenter(row+1,col)
            return false
        elsif alignment == true && hasCenter(row, col+1)
            return false
        elsif turn == true && @p1Walls == 0 || turn == false && @p2Walls == 0
            return false
        end

        backup = Marshal.load(Marshal.dump(@cells))

        if alignment == true
            if row != 0
                return false if @cells[row-1][col].down == true
                return false if @cells[row-1][col+1].down == true

                @cells[row-1][col].down = true
                @cells[row-1][col+1].down = true
            end
            if row != 9
                return false if @cells[row][col].up == true
                return false if @cells[row][col+1].up == true

                @cells[row][col].up = true
                @cells[row][col+1].up = true
            end

        elsif alignment == false
            if col != 0
                return false if @cells[row][col-1].right == true
                return false if @cells[row+1][col-1].right == true

                @cells[row][col-1].right = true
                @cells[row+1][col-1].right = true
            end
            if col != 9
                return false if @cells[row][col].left == true
                return false if @cells[row+1][col].left == true

                @cells[row][col].left = true
                @cells[row+1][col].left = true
            end
        end

        if hasExit(1) == false || hasExit(2) == false
            @cells = backup
            return false
        end

        addToWallList(Wall.new(alignment, row, col))
        if turn == true
            @p1Walls -= 1
        else
            @p2Walls -= 1
        end

        @turn = !@turn
        return true
    end

    def hasExit(player)
        matrix = Array.new(9) { Array.new(9) { false } }

        if player == 1
            for i in 0..8
                matrix[0][i] = true
            end
        else
            for i in 0..8
                matrix[8][i] = true
            end
        end

        
        prevMatrix = Array.new(9) { Array.new(9) { false } }

        if player == 1
            while true
                for i in 0..8
                    for j in 0..8
                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                    end

                    j = 8
                    while j >= 0
                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                        j -= 1
                    end
                end

                i = 8
                while i >= 0
                    for j in 0..8
                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                    end

                    j = 8
                    while j >= 0

                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                        j -= 1
                    end
                    i -= 1
                end

                break if prevMatrix == matrix
                
                prevMatrix = Marshal.load(Marshal.dump(matrix))
            end
            
            
            

            pLoc = findPlayer(1)
            return true if matrix[pLoc[0]][pLoc[1]] == true
            return false
        
        else
            while true 
                i = 8
                while i >= 0
                    for j in 0..8
                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                    end

                    j = 8
                    while j >= 0

                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                        j -= 1
                    end
                    i -= 1
                end

                for i in 0..8
                    for j in 0..8
                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false 
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                    end

                    j = 8
                    while j >= 0
                        if matrix[i][j] == false
                            if i != 0
                                matrix[i][j] = true if matrix[i-1][j] == true && @cells[i][j].up == false
                            end
                            if i != 8
                                matrix[i][j] = true if matrix[i+1][j] == true && @cells[i][j].down == false
                            end
                            if j != 0
                                matrix[i][j] = true if matrix[i][j-1] == true && @cells[i][j].left == false
                            end
                            if j != 8
                                matrix[i][j] = true if matrix[i][j+1] == true && @cells[i][j].right == false
                            end
                        end
                        j -= 1
                    end
                end

                break if prevMatrix == matrix
                    
                prevMatrix = Marshal.load(Marshal.dump(matrix))
            end 
            
            pLoc = findPlayer(2)
            return true if matrix[pLoc[0]][pLoc[1]] == true
            return false
            
        end
    end

    def addToWallList(w)
        @wallList.append(w)
    end

    def hasCenter(r, c)
        for i in @wallList
            return true if i.centerR == r && i.centerC == c
        end
        return false
    end

    def isGameOver
        if findPlayer(1)[0] == 0
            return 1
        elsif findPlayer(2)[0] == 8
            return 2
        end
        return 0
    end
end

board = GameBoard.new

while(board.isGameOver == 0)
    print "P" 
    if board.turn == true
        print "1"
    else
        print "2"
    end 
    puts "'s Turn"

    print "P1 Walls: "
    puts board.p1Walls
    
    print "P2 Walls: "
    puts board.p2Walls

    if board.turn == true
        puts board.toString
    else
        puts board.toStringReverse
    end

    puts "--------------------------------------------------------"
    puts "Command: "
    command = gets.chomp
    puts command
    if command == "w"
        if board.turn == true
            board.move(1)
        else
            board.move(2)
        end
    
    elsif command == "s"
        if board.turn == true
            board.move(2)
        else
            board.move(1)
        end
    
    elsif command == "a"
        if board.turn == true
            board.move(3)
        else
            board.move(4)
        end
    
    elsif command == "d"
        if board.turn == true
            board.move(4)
        else
            board.move(3)
        end
    
    # 5 1 6
    # 3 x 4
    # 7 2 8
    elsif command == "q"
        if board.turn == true
            board.move(5)
        else
            board.move(8)
        end
    
    elsif command == "e"
        if board.turn == true
            board.move(6)
        else
            board.move(7)
        end
    
    elsif command == "z"
        if board.turn == true
            board.move(7)
        else
            board.move(6)
        end

    elsif command == "x"
        if board.turn == true
            board.move(8)
        else
            board.move(5)
        end
    
    elsif command == "h" || command == "v"
        puts "Enter row: "
        row = gets.chomp.to_i
        puts "Enter column: "
        col = gets.chomp.to_i
        if command == "h"
            board.addWall(true, row, col )
        else 
            board.addWall(false, row, col )
        end
    end  
end

a = board.isGameOver
puts board.toString
print "P"
print a
puts " won!"
