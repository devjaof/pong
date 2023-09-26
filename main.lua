Class = require 'class'
require 'Ball'
require 'Paddle'

local push = require 'push'

WINDOW_WIDTH, WINDOW_HEIGHT = 1280, 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

local function displayScore()
  love.graphics.setFont(scoreFont)
  love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
    VIRTUAL_HEIGHT / 3)
  love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
    VIRTUAL_HEIGHT / 3)
end

local function displayFPS()
  love.graphics.setFont(smallFont)
  love.graphics.setColor(0, 255, 0, 255)
  love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest')

  love.window.setTitle('Pong Doidera')

  math.randomseed(os.time())

  smallestFont = love.graphics.newFont('font.ttf', 8)
  smallFont = love.graphics.newFont('font.ttf', 10)
  scoreFont = love.graphics.newFont('font.ttf', 30)
  largeFont = love.graphics.newFont('font.ttf', 34)

  love.graphics.setFont(smallFont)

  sounds = {
    ['paddleHit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
    ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
    ['wallHit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
  }

  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = true,
    vsync = false
  })

  player1Score = 0
  player2Score = 0

  servingPlayer = 1

  player1 = Paddle(10, 30, 5, 20)
  player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

  ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

  gameState = 'start'
end

function love.resize(w, h)
  push:resize(w, h)
end

function love.update(dt)
  -- gerenciamento de estados no jogo
  if gameState == 'serve' then
    ball.dy = math.random(-50, 50)
    if servingPlayer == 1 then
      ball.dx = math.random(140, 200)
    else
      ball.dx = -math.random(140, 200)
    end
  end

  if gameState == 'play' then
    if ball:collides(player1) then
      sounds['paddleHit']:play()

      ball.dx = -ball.dx * 1.2
      ball.x = player1.x + 5

      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end
    end

    if ball:collides(player2) then
      sounds['paddleHit']:play()
      ball.dx = -ball.dx * 1.2
      ball.x = player2.x - 4

      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end
    end

    -- garante que a bola vai colidir com o teto e o chão
    if ball.y <= 0 then
      sounds['wallHit']:play()
      ball.y = 0
      ball.dy = -ball.dy
    end

    -- 4 é o tamanho da bola
    if ball.y >= VIRTUAL_HEIGHT - 4 then
      sounds['wallHit']:play()
      ball.y = VIRTUAL_HEIGHT - 4
      ball.dy = -ball.dy
    end

    -- scores
    if ball.x < 0 then
      sounds['score']:play()

      servingPlayer = 1
      player2Score = player2Score + 1

      if player2Score == 10 then
        winningPlayer = 2
        gameState = 'done'
      else
        gameState = 'serve'
        ball:reset()
      end
    end


    if ball.x > VIRTUAL_WIDTH then
      sounds['score']:play()
      servingPlayer = 2
      player1Score = player1Score + 1

      if player1Score == 10 then
        winningPlayer = 1
        gameState = 'done'
      else
        gameState = 'serve'
        ball:reset()
      end
    end
  end

  -- movimentação do player 1
  if love.keyboard.isDown('w') then
    player1.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('s') then
    player1.dy = PADDLE_SPEED
  else
    player1.dy = 0
  end

  -- movimentação do player 2
  if love.keyboard.isDown('up') then
    player2.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('down') then
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
    end

    if gameState == 'serve' then
      gameState = 'play'
    end

    if gameState == 'done' then
      gameState = 'serve'

      ball:reset()

      player1Score = 0
      player2Score = 0

      if winningPlayer == 1 then
        servingPlayer = 2
      else
        servingPlayer = 1
      end
    end
  end
end

function love.draw()
  push:apply('start')

  love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)

  if gameState == 'start' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('Bem vindo ao Pongzinho', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Aperte enter para iniciar, mas soh se quiser.', 0, 20, VIRTUAL_WIDTH, 'center')
  end

  if gameState == 'serve' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('O saque eh do jogador  ' .. tostring(servingPlayer),
      0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Aperte enter para sacar.', 0, 20, VIRTUAL_WIDTH, 'center')
  end

  if gameState == 'done' then
    love.graphics.setFont(largeFont)
    love.graphics.printf('O jogador ' .. tostring(winningPlayer) .. ' venceu!! ',
      0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(smallestFont)
    love.graphics.printf('Mas Nao fez mais que sua obrigacao...', 0, 45, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(smallFont)
    love.graphics.printf('Aperte enter para reiniciar.', 0, 65, VIRTUAL_WIDTH, 'center')
  end

  displayScore()

  player1:render()
  player2:render()

  ball:render()

  displayFPS()

  push:apply('end')
end
