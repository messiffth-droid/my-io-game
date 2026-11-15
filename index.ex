<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Custom Map .io Game - Vietnam Pro</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #0d1117;
            color: #fff;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        #game-container {
            position: relative;
            box-shadow: 0 0 40px rgba(0,0,0,0.9);
            border: 3px solid #30363d;
            border-radius: 10px;
            overflow: hidden;
        }
        canvas {
            display: block;
            background: #5a8f42;
        }
        #ui {
            position: absolute;
            top: 12px;
            left: 12px;
            background: rgba(13, 17, 23, 0.85);
            padding: 12px 18px;
            border-radius: 8px;
            font-size: 14px;
            border: 1px solid #30363d;
            pointer-events: none;
        }
        #leaderboard {
            position: absolute;
            top: 12px;
            right: 12px;
            background: rgba(13, 17, 23, 0.85);
            padding: 12px 18px;
            border-radius: 8px;
            width: 210px;
            border: 1px solid #30363d;
            pointer-events: none;
        }
        #leaderboard h3 {
            font-size: 13px;
            border-bottom: 1px solid #30363d;
            padding-bottom: 6px;
            margin-bottom: 8px;
            color: #f1e05a;
            text-align: center;
        }
        .lb-item {
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            margin-bottom: 5px;
        }
        #controls-hint {
            position: absolute;
            bottom: 12px;
            left: 12px;
            background: rgba(13, 17, 23, 0.85);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 12px;
            color: #8b949e;
            border: 1px solid #30363d;
            pointer-events: none;
        }
    </style>
</head>
<body>

<div id="game-container">
    <canvas id="gameCanvas" width="950" height="620"></canvas>
    
    <div id="ui">
        <div><strong>Score:</strong> <span id="scoreVal">0</span></div>
        <div><strong>Level:</strong> <span id="levelVal">1</span> (Tiến hóa)</div>
        <div><strong>HP:</strong> <span id="hpVal">100</span>/100</div>
    </div>

    <div id="leaderboard">
        <h3>BẢNG XẾP HẠNG VIETNAM .IO</h3>
        <div class="lb-item"><span>1. Đình Dũng (VN)</span><span id="lbScore">0</span></div>
        <div class="lb-item"><span>2. ZumiGaming Bot</span><span>420</span></div>
        <div class="lb-item"><span>3. Pro Player .io</span><span>280</span></div>
    </div>

    <div id="controls-hint">
        Dùng phím <strong>W, A, S, D</strong> để di chuyển. Giữ <strong>Chuột trái</strong> để tấn công & farm tài nguyên!
    </div>
</div>

<script>
    const canvas = document.getElementById("gameCanvas");
    const ctx = canvas.getContext("2d");

    // Người chơi
    let player = {
        x: 600,
        y: 400,
        radius: 20,
        speed: 3.8,
        color: "#f1c40f",
        score: 0,
        level: 1,
        hp: 100,
        maxHp: 100,
        angle: 0,
        isAttacking: false,
        attackCooldown: 0
    };

    let keys = {};
    window.addEventListener("keydown", (e) => keys[e.key.toLowerCase()] = true);
    window.addEventListener("keyup", (e) => keys[e.key.toLowerCase()] = false);

    let mouse = { x: 0, y: 0, down: false };
    canvas.addEventListener("mousemove", (e) => {
        let rect = canvas.getBoundingClientRect();
        mouse.x = e.clientX - rect.left;
        mouse.y = e.clientY - rect.top;
    });
    canvas.addEventListener("mousedown", () => mouse.down = true);
    canvas.addEventListener("mouseup", () => mouse.down = false);

    // Bản đồ Map Custom .io (Tường và bẫy)
    let walls = [
        { x: 150, y: 150, w: 300, h: 40, color: "#21262d" },
        { x: 150, y: 190, w: 40, h: 250, color: "#21262d" },
        { x: 1200, y: 200, w: 350, h: 40, color: "#6e40c9" },
        { x: 1200, y: 240, w: 40, h: 250, color: "#6e40c9" },
        { x: 700, y: 900, w: 400, h: 45, color: "#bc4c00" }
    ];

    let lavas = [
        { x: 1100, y: 800, w: 250, h: 150 }
    ];

    // Cây cối / Cục năng lượng để farm
    let orbs = [];
    function spawnOrbs() {
        orbs = [];
        for (let i = 0; i < 35; i++) {
            orbs.push({
                x: Math.random() * 2200 + 100,
                y: Math.random() * 1600 + 100,
                radius: 12,
                value: 30
            });
        }
    }
    spawnOrbs();

    // Bot đối thủ di chuyển trên map
    let bots = [
        { x: 300, y: 300, radius: 22, speed: 2, color: "#e74c3c", name: "ZumiGaming Bot", score: 150, hp: 100, dirTimer: 0, dx: 1, dy: 1 },
        { x: 1400, y: 400, radius: 25, speed: 2.2, color: "#3498db", name: "Pro Player .io", score: 220, hp: 100, dirTimer: 0, dx: -1, dy: 1 }
    ];

    let camera = { x: 0, y: 0 };

    function update() {
        // Di chuyển player
        let dx = 0, dy = 0;
        if (keys['w'] || keys['arrowup']) dy -= 1;
        if (keys['s'] || keys['arrowdown']) dy += 1;
        if (keys['a'] || keys['arrowleft']) dx -= 1;
        if (keys['d'] || keys['arrowright']) dx += 1;

        if (dx !== 0 && dy !== 0) {
            dx *= 0.7071;
            dy *= 0.7071;
        }

        player.x += dx * player.speed;
        player.y += dy * player.speed;

        // Giới hạn bản đồ rộng 2400x1800
        player.x = Math.max(30, Math.min(2370, player.x));
        player.y = Math.max(30, Math.min(1770, player.y));

        // Hướng chuột
        player.angle = Math.atan2(mouse.y - (canvas.height / 2), mouse.x - (canvas.width / 2));

        // Tấn công / Farm
        player.isAttacking = mouse.down;
        if (player.attackCooldown > 0) player.attackCooldown--;

        if (player.isAttacking && player.attackCooldown === 0) {
            player.attackCooldown = 15; // Tốc độ chém
            // Kiểm tra chém trúng bot hoặc orb
            bots.forEach(bot => {
                let dist = Math.hypot(player.x - bot.x, player.y - bot.y);
                if (dist < player.radius + bot.radius + 30) {
                    bot.hp -= 25;
                    bot.x += Math.cos(player.angle) * 30; // Đẩy lùi bot
                    bot.y += Math.sin(player.angle) * 30;
                    if (bot.hp <= 0) {
                        player.score += 150;
                        bot.hp = 100;
                        bot.x = Math.random() * 2000 + 200;
                        bot.y = Math.random() * 1400 + 200;
                    }
                }
            });
        }

        // Ăn năng lượng (Orbs)
        orbs.forEach((orb, index) => {
            let dist = Math.hypot(player.x - orb.x, player.y - orb.y);
            if (dist < player.radius + orb.radius) {
                player.score += orb.value;
                player.level = Math.floor(player.score / 250) + 1;
                player.radius = 20 + (player.level - 1) * 2; // Tăng kích thước khi lên cấp
                orbs.splice(index, 1);
                // Sinh lại orb mới
                setTimeout(() => {
                    orbs.push({
                        x: Math.random() * 2200 + 100,
                        y: Math.random() * 1600 + 100,
                        radius: 12,
                        value: 30
                    });
                }, 4000);
            }
        });

        // Kiểm tra dẫm vào Lava
        lavas.forEach(l => {
            if (player.x > l.x && player.x < l.x + l.w && player.y > l.y && player.y < l.y + l.h) {
                player.hp -= 0.8;
                if (player.hp <= 0) {
                    player.score = 0;
                    player.level = 1;
                    player.radius = 20;
                    player.hp = player.maxHp;
                    player.x = 600; player.y = 400;
                }
            }
        });

        // Cập nhật Bot di chuyển thông minh trên map
        bots.forEach(bot => {
            bot.dirTimer++;
            if (bot.dirTimer > 100) {
                bot.dx = (Math.random() - 0.5) * 2;
                bot.dy = (Math.random() - 0.5) * 2;
                bot.dirTimer = 0;
            }
            bot.x += bot.dx * bot.speed;
            bot.y += bot.dy * bot.speed;
            bot.x = Math.max(40, Math.min(2360, bot.x));
            bot.y = Math.max(40, Math.min(1760, bot.y));
        });

        // Camera mượt theo nhân vật
        camera.x = player.x - canvas.width / 2;
        camera.y = player.y - canvas.height / 2;

        // Cập nhật UI
        document.getElementById("scoreVal").innerText = player.score;
        document.getElementById("levelVal").innerText = player.level;
        document.getElementById("hpVal").innerText = Math.max(0, Math.floor(player.hp));
        document.getElementById("lbScore").innerText = player.score;
    }

    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        ctx.save();
        ctx.translate(-camera.x, -camera.y);

        // 1. Nền cỏ bản đồ rộng
        ctx.fillStyle = "#5a8f42";
        ctx.fillRect(0, 0, 2400, 1800);

        // Lưới bản đồ
        ctx.strokeStyle = "rgba(0,0,0,0.06)";
        ctx.lineWidth = 1;
        for (let x = 0; x < 2400; x += 60) {
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, 1800); ctx.stroke();
        }
        for (let y = 0; y < 1800; y += 60) {
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(2400, y); ctx.stroke();
        }

        // 2. Dung nham
        lavas.forEach(l => {
            ctx.fillStyle = "#ff4500";
            ctx.fillRect(l.x, l.y, l.w, l.h);
            ctx.fillStyle = "#ffcc00";
            ctx.font = "bold 16px sans-serif";
            ctx.fillText("🔥 VÙNG NGUY HIỂM (LAVA) 🔥", l.x + 15, l.y + 45);
        });

        // 3. Tường Map Custom
        walls.forEach(w => {
            ctx.fillStyle = w.color;
            ctx.fillRect(w.x, w.y, w.w, w.h);
            ctx.strokeStyle = "#111";
            ctx.lineWidth = 4;
            ctx.strokeRect(w.x, w.y, w.w, w.h);
        });

        // Chữ trang trí bản đồ phong cách Custom Map Vietnam
        ctx.fillStyle = "rgba(255,255,255,0.15)";
        ctx.font = "bold 120px sans-serif";
        ctx.fillText("VIETNAM CUSTOM MAP .IO", 350, 400);

        // 4. Các điểm năng lượng (Orbs)
        orbs.forEach(orb => {
            ctx.fillStyle = "#2ecc71";
            ctx.beginPath();
            ctx.arc(orb.x, orb.y, orb.radius, 0, Math.PI * 2);
            ctx.fill();
            ctx.strokeStyle = "#27ae60";
            ctx.lineWidth = 3;
            ctx.stroke();
        });

        // 5. Vẽ Bot đối thủ
        bots.forEach(bot => {
            ctx.save();
            ctx.translate(bot.x, bot.y);
            ctx.fillStyle = bot.color;
            ctx.beginPath();
            ctx.arc(0, 0, bot.radius, 0, Math.PI * 2);
            ctx.fill();
            ctx.strokeStyle = "#000";
            ctx.lineWidth = 3;
            ctx.stroke();

            // Thanh HP của Bot
            ctx.fillStyle = "#222";
            ctx.fillRect(-20, -bot.radius - 12, 40, 6);
            ctx.fillStyle = "#e74c3c";
            ctx.fillRect(-20, -bot.radius - 12, (bot.hp / 100) * 40, 6);

            ctx.restore();

            ctx.fillStyle = "#fff";
            ctx.font = "bold 11px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText(bot.name, bot.x, bot.y - bot.radius - 16);
        });

        // 6. Vẽ Người chơi (Đình Dũng)
        ctx.save();
        ctx.translate(player.x, player.y);
        ctx.rotate(player.angle);

        // Hiệu ứng vũ khí chém khi click chuột
        if (player.isAttacking) {
            ctx.strokeStyle = "#00ffff";
            ctx.lineWidth = 10;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(0, 0, player.radius + 22, -Math.PI/2.5, Math.PI/2.5);
            ctx.stroke();
        }

        // Thân nhân vật
        ctx.fillStyle = player.color;
        ctx.beginPath();
        ctx.arc(0, 0, player.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = "#d4ac0d";
        ctx.lineWidth = 4;
        ctx.stroke();

        // Mắt nhân vật ngầu hơn
        ctx.fillStyle = "#000";
        ctx.beginPath();
        ctx.arc(8, -6, 4, 0, Math.PI * 2);
        ctx.arc(8, 6, 4, 0, Math.PI * 2);
        ctx.fill();

        ctx.restore();

        // Tên và cấp độ người chơi
        ctx.fillStyle = "#fff";
        ctx.font = "bold 13px sans-serif";
        ctx.textAlign = "center";
        ctx.fillText("⭐ Đình Dũng (VN) [Lv." + player.level + "]", player.x, player.y - player.radius - 10);

        ctx.restore();
    }

    function loop() {
        update();
        draw();
        requestAnimationFrame(loop);
    }

    loop();
</script>

</body>
</html>