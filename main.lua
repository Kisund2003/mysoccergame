local gameState = "home"
local level = 1

function love.load()
    fieldWidth = 800
    fieldHeight = 400
    goalWidth = 10
    goalHeight = 100
    goalY = (fieldHeight - goalHeight) / 2
    love.window.setMode(fieldWidth, fieldHeight)

    -- Load player images
    playerImage = love.graphics.newImage("images/man.png")
    opponentImage = love.graphics.newImage("images/man1.png")
    background = love.graphics.newImage("images/ft2.png")

    -- Load your own ball image
    ballImage = love.graphics.newImage("images/ball.png")

    -- Player properties
    player1 = {
        x = 50,
        y = fieldHeight / 2 - 20,
        w = 63,
        h = 53,
        color = {0, 0, 1},
        speed = 250,l
        score = 0,
        image = playerImage
    }
    player2 = {
        x = fieldWidth - 70,
        y = fieldHeight / 2 - 20,
        w = 60,
        h = 50,
        color = {1, 0, 0},
        speed = 150,
        score = 0,
        image = opponentImage
    }

    -- Ball properties 
    ball = {
        x = fieldWidth / 2,
        y = fieldHeight / 2,
        radius = math.max(ballImage:getWidth(), ballImage:getHeight()) / 2,
        color = {1, 1, 0},
        speedX = 200,
        speedY = 150
    }
    ball.radius = ball.radius / 7

    gameOver = false
    winner = ""

    player1.flipped = false
    player2.flipped = false
end

function resetBall()
    ball.x = fieldWidth / 2
    ball.y = fieldHeight / 2
    -- Increase ball speed with level
    local baseSpeed = 200 + (level - 1) * 80
    ball.speedX = (math.random(0, 1) == 0 and 1 or -1) * baseSpeed
    ball.speedY = (math.random(0, 1) == 0 and 1 or -1) * (150 + (level - 1) * 60)
end

function resetPlayers()
    player1.x = 50
    player1.y = fieldHeight / 2 - 20
    player2.x = fieldWidth - 70
    player2.y = fieldHeight / 2 - 20
end

function love.update(dt)
    if gameState ~= "play" then return end
    if gameOver then return end

    -- Player 1 controls (Arrow keys)
    if love.keyboard.isDown("up") then
        player1.y = math.max(0, player1.y - player1.speed * dt)
    end
    if love.keyboard.isDown("down") then
        player1.y = math.min(fieldHeight - player1.h, player1.y + player1.speed * dt)
    end
    if love.keyboard.isDown("left") then
        player1.x = math.max(0, player1.x - player1.speed * dt)
    end
    if love.keyboard.isDown("right") then
        player1.x = math.min(fieldWidth - player1.w, player1.x + player1.speed * dt)
    end
    -- Flip image if moving left or right
    if love.keyboard.isDown("left") then
        player1.flipped = true
    elseif love.keyboard.isDown("right") then
        player1.flipped = false
    end

    -- Player 2 AI (Red bot) -- difficulty increases with level
    local botReaction = 0.4 + (level - 1) * 0.15 -- Made bot slower: Level 1: 0.4, Level 2: 0.55, Level 3: 0.7
    player2.speed = 180 + (level - 1) * 40        -- Made bot slower: Level 1: 180, Level 2: 220, Level 3: 260

    -- Move vertically towards the ball
    if ball.y + ball.radius < player2.y then
        player2.y = math.max(0, player2.y - player2.speed * dt * botReaction)
    elseif ball.y - ball.radius > player2.y + player2.h then
        player2.y = math.min(fieldHeight - player2.h, player2.y + player2.speed * dt * botReaction)
    end
    -- Move horizontally towards the ball
    if ball.x < player2.x then
        player2.x = math.max(fieldWidth / 2, player2.x - player2.speed * dt * botReaction)
        player2.flipped = true
    elseif ball.x > player2.x + player2.w then
        player2.x = math.min(fieldWidth - player2.w, player2.x + player2.speed * dt * botReaction)
        player2.flipped = false
    end

    -- Move ball
    ball.x = ball.x + ball.speedX * dt
    ball.y = ball.y + ball.speedY * dt

    -- Ball collision with left/right (back) walls
    if ball.x - ball.radius < 0 then
        ball.x = ball.radius
        ball.speedX = -ball.speedX
    elseif ball.x + ball.radius > fieldWidth then
        ball.x = fieldWidth - ball.radius
        ball.speedX = -ball.speedX
    end

    -- Ball collision with top/bottom
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.speedY = -ball.speedY
    elseif ball.y + ball.radius > fieldHeight then
        ball.y = fieldHeight - ball.radius
        ball.speedY = -ball.speedY
    end

    -- Now check for goals (inside the field, not past the boundary)
    if ball.x - ball.radius < goalWidth and ball.y > goalY and ball.y < goalY + goalHeight then
        player2.score = player2.score + 1
        resetBall()
        resetPlayers()
    elseif ball.x + ball.radius > fieldWidth - goalWidth and ball.y > goalY and ball.y < goalY + goalHeight then
        player1.score = player1.score + 1
        resetBall()
        resetPlayers()
    end

    -- Check for winner
    if player1.score >= 3 then
        if level < 3 then
            level = level + 1
            player1.score = 0
            player2.score = 0
            resetBall()
            resetPlayers()
            gameState = "levelup"
        else
            gameOver = true
            winner = "Blue"
        end
    elseif player2.score >= 3 then
        -- If bot wins, just end the game (no level up)
        gameOver = true
        winner = "Red"
    end

    -- Ball collision with players (bounce off front/back)
    if checkCollision(ball, player1) then
        ball.speedX = math.abs(ball.speedX)
        local hitPos = ((ball.y - player1.y) / player1.h) - 0.5
        ball.speedY = hitPos * 400
    elseif checkCollision(ball, player2) then
        ball.speedX = -math.abs(ball.speedX)
        local hitPos = ((ball.y - player2.y) / player2.h) - 0.5
        ball.speedY = hitPos * 400
    end
end

function love.keypressed(key)
    if gameState == "home" and (key == "return" or key == "space") then
        gameState = "play"
        level = 1
        player1.score = 0
        player2.score = 0
        gameOver = false
        winner = ""
        resetBall()
        resetPlayers()
    elseif gameState == "levelup" and (key == "return" or key == "space") then
        gameState = "play" 
        resetBall()
        resetPlayers()
    elseif gameOver and key == "r" then
        player1.score = 0
        player2.score = 0
        gameOver = false
        winner = ""
        level = 1
        resetBall()
        resetPlayers()
    end
end

function checkCollision(ball, player)
    return ball.x + ball.radius > player.x and
           ball.x - ball.radius < player.x + player.w and
           ball.y + ball.radius > player.y and
           ball.y - ball.radius < player.y + player.h
end

function love.draw()
    if gameState == "home" then
        love.graphics.setColor(0.1, 0.5, 0.1)
        love.graphics.rectangle("fill", 0, 0, fieldWidth, fieldHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf("MY SOCCER GAME", 0, fieldHeight/2 - 80, fieldWidth, "center")
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("Press ENTER or SPACE to Start", 0, fieldHeight/2, fieldWidth, "center")
        love.graphics.printf("First to 3 wins!", 0, fieldHeight/2 + 40, fieldWidth, "center")
        love.graphics.printf("Level 1", 0, fieldHeight/2 + 80, fieldWidth, "center")
        return
    elseif gameState == "levelup" then
        love.graphics.setColor(0.1, 0.5, 0.1)
        love.graphics.rectangle("fill", 0, 0, fieldWidth, fieldHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf("LEVEL " .. level, 0, fieldHeight/2 - 40, fieldWidth, "center")
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("Press ENTER or SPACE to Continue", 0, fieldHeight/2 + 20, fieldWidth, "center")
        return
    end

    -- Draw background first
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        background,
        0, 0,
        0,
        fieldWidth / background:getWidth(),
        fieldHeight / background:getHeight()
    )

    -- Draw left goal post
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, goalY, goalWidth, goalHeight)

    -- Draw right goal post
    love.graphics.rectangle("fill", fieldWidth - goalWidth, goalY, goalWidth, goalHeight)

    -- Draw player 1 with image if available
    if player1.image then
        love.graphics.setColor(1, 1, 1)
        local scaleX = player1.flipped and -player1.w / player1.image:getWidth() or player1.w / player1.image:getWidth()
        local offsetX = player1.flipped and player1.x + player1.w or player1.x
        love.graphics.draw(player1.image, offsetX, player1.y, 0, scaleX, player1.h / player1.image:getHeight())
    else
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("fill", player1.x, player1.y, player1.w, player1.h)
    end

    -- Draw player 2 (opponent) with image if available
    if player2.image then
        love.graphics.setColor(1, 1, 1)
        local scaleX = not player2.flipped and -player2.w / player2.image:getWidth() or player2.w / player2.image:getWidth()
        local offsetX = not player2.flipped and player2.x + player2.w or player2.x
        love.graphics.draw(player2.image, offsetX, player2.y, 0, scaleX, player2.h / player2.image:getHeight())
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", player2.x, player2.y, player2.w, player2.h)
    end

    -- Draw ball as image, scaled to match ball.radius
    love.graphics.setColor(1, 1, 1)
    local scaleX = (ball.radius * 2) / ballImage:getWidth()
    local scaleY = (ball.radius * 2) / ballImage:getHeight()
    love.graphics.draw(
        ballImage,
        ball.x - ball.radius,
        ball.y - ball.radius,
        0,
        scaleX,
        scaleY
    )

    -- Draw scores and level
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Blue: " .. player1.score, 30, 20)
    love.graphics.print("Red: " .. player2.score, fieldWidth - 100, 20)
    love.graphics.print("Level " .. level, fieldWidth/2 - 30, 20)
    
    -- Draw game over message
    if gameOver then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(winner .. " wins! Press R to restart.", 0, fieldHeight/2 - 20, fieldWidth, "center")
    end
end
