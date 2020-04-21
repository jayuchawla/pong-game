Class = require 'class'
push = require 'push';
require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

function love.load()
    love.window.setTitle('Pong')
    love.graphics.setDefaultFilter('nearest','nearest')
    math.randomseed(os.time())
    smallfont = love.graphics.newFont('font.ttf', 8)
    scorefont = love.graphics.newFont('font.ttf', 32)
    largefont = love.graphics.newFont('font.ttf', 36)
    love.graphics.setFont(smallfont)

    ---static => laoded at start until execution if stream => loaded as needed(needed for large audios)
    -- audio is a table just index the table and call play method
    audio = {
        ['paddle_hit'] = love.audio.newSource('audio/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('audio/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('audio/wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH,VIRTUAL_HEIGHT,WINDOW_WIDTH,WINDOW_HEIGHT,{
        fullscreen = false,
        resizable = true,
        vsync = true
    })   
    
    player1Score = 0
    player2Score = 0
    
    servePlayer = 1
    winPlayer = -1

    player1 = Paddle(10,30,5,20)
    player2 = Paddle(VIRTUAL_WIDTH-10,VIRTUAL_HEIGHT - 30,5,20)

    ball = Ball(VIRTUAL_WIDTH/2-2,VIRTUAL_HEIGHT/2-2,4,4)
    --use to transition between different parts of game running pause etc 
    gameState = 'start'
end

function love.resize(w, h)
 push:resize(w,h)
end

function love.update(dt)
    if gameState == 'serve' then

        ball.dy = math.random(-50,50)
        
        if servePlayer == 1 then
            ball.dx = math.random(140,200)
        else
            ball.dx = -math.random(140,200)
        end   
    
    elseif gameState == 'play' then
        if ball:collide(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + player1.width

            --randomize y velocity in but same direction
            if ball.dy < 0 then 
                ball.dy = -math.random(10,150)
            else
                ball.dy = math.random(10,150)
            end
            audio['paddle_hit']:play()
        end

        if ball:collide(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            --randomize y velocity but same direction
            if ball.dy < 0 then 
                ball.dy = -math.random(10,150)
            else
                ball.dy = math.random(10,150)
            end
            audio['paddle_hit']:play()
        end

        --ball vertically goes off boundary
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy 
            audio['wall_hit']:play()
        end
        
        if ball.y + ball.height >= VIRTUAL_HEIGHT then
            ball.y = VIRTUAL_HEIGHT - ball.height
            ball.dy = -ball.dy
            audio['wall_hit']:play()
        end

        --ball horizontally goes off boundary
        if ball.x < 0 then
            player2Score = player2Score + 1
            servePlayer = 1
            audio['score']:play()

            if player2Score == 5 then
                winPlayer = 2
                gameState = 'complete'
            else
                gameState = 'serve'
                ball:reset()
                gameState = 'serve'
            end
        end

        if (ball.x + ball.width > VIRTUAL_WIDTH) then 
            player1Score = player1Score + 1
            servePlayer = 2
            audio['score']:play()
            
            if player1Score == 5 then
                winPlayer = 1
                gameState = 'complete'
            else
                gameState = 'serve'
                ball:reset()
                gameState = 'serve'
            end
        end
    end --complete

    if love.keyboard.isDown('w') then
        --to avoid going offscreen
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    if love.keyboard.isDown('w') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)

end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'play' then
            gameState = 'serve'
            ---start state resets game
            ball:reset()
        elseif gameState == 'complete' then
            gameState = 'serve' --restart
            ball:reset()
            player1Score = 0
            player2Score = 0

            if winPlayer == 1 then
                servePlayer = 2
            else
                servePlayer = 1
            end
        end
    end
end

function love.draw()
    push:apply('start')
    love.graphics.clear(180,0,180)
    
    -- set font as score Font:getAscent()
    printScore()

    if gameState == 'start' then
        love.graphics.setFont(smallfont)
        love.graphics.printf('Hello Player', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallfont)
        love.graphics.printf('Player ' .. tostring(servePlayer) .. '\'s serve!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
    elseif gameState == 'complete' then
        love.graphics.setFont(largefont)
        love.graphics.printf('Player ' .. tostring(winPlayer) .. ' Wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallfont)
        love.graphics.printf('Press Enter to restart!', 0, 50, VIRTUAL_WIDTH, 'center')        
    end

    player1:render() --player1
    player2:render() --player2
    ball:render() --ball

    printFPS()

    push:apply('end') 
end

function printFPS()
    love.graphics.setFont(smallfont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()),10,10)
end


function printScore()
    love.graphics.setFont(scorefont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH/2-50,VIRTUAL_HEIGHT/3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH/2+30,VIRTUAL_HEIGHT/3)
end