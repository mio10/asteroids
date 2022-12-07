final int WIDTH = 1300;
final int HEIGHT = 700;

final float PLR_MAXACCEL = 0.1;
final float PLR_LASERSPEED = 20;

final float AST_RADIUS_PER_SPLIT = 20;
final float AST_MIN_SPEED = 0.1;
final float AST_MAX_SPEED = 0.8;
final float AST_DISPERSION = 5;
final int   AST_HP = 10;
final int   AST_SPAWNINTERVAL = 1000;

class Point {
    private float x;
    private float y;

    Point(float x, float y) {
        this.x = x;
        this.y = y;
    }

    Point rot(float angle) {
        return new Point(
            (float) Math.cos(angle) * x - (float) Math.sin(angle) * y,
            (float) Math.sin(angle) * x + (float) Math.cos(angle) * y
        );
    }

    Point add(Point p) {
        return new Point(
            x + p.x,
            y + p.y
        );
    }

    float dist(Point p) {
        return (float) Math.sqrt(Math.pow(x - p.x, 2) + Math.pow(y - p.y, 2));
    }

    float len() {
        return (float) Math.sqrt(x*x + y*y);
    }
}

class Laser {
    Point pos;
    float heading;
    Point speed;

    Point[] shape;

    Laser(Point pos, float heading) {
        this.pos = pos;
        this.heading = heading;
        speed = new Point(0, -PLR_LASERSPEED);

        shape = new Point[] {
            new Point(0, 0),
            new Point(0, 15)
        };
    }

    boolean outBorders() {
        if (pos.x > WIDTH || pos.x < 0 || pos.y > HEIGHT || pos.y < 0) return true;
        return false;
    }

    void move() {
        pos = pos.add(speed.rot(heading));
    }

    void display() {
        stroke(255);
        drawPoly(shape, heading, pos);
    }
}

class Asteroid {
    Point pos;
    float heading;
    Point speed;
    float radius;
    int splitsLeft;
    int hp;

    Point[] shape;

    Asteroid(int splitsLeft) {
        float roll = random(1);
        if (roll < 0.25) {
            pos = new Point(random(WIDTH), -50);
        } else if (roll < 0.5) {
            pos = new Point(WIDTH + 50, random(HEIGHT));
        } else if (roll < 0.75) {
            pos = new Point(random(WIDTH), HEIGHT + 50);
        } else {
            pos = new Point(-50, random(HEIGHT));
        }

        this.splitsLeft = splitsLeft;
        heading = random(3);
        speed = new Point(random(AST_MIN_SPEED, AST_MAX_SPEED),
                          random(AST_MIN_SPEED, AST_MAX_SPEED));
        radius = (splitsLeft + 1) * AST_RADIUS_PER_SPLIT;
        hp = AST_HP * splitsLeft + 1;

        shape = new Point[(int) (radius / 3)];
        float twoPiDivided = 2 * (float) Math.PI / shape.length;
        for (int i = 0; i < shape.length; i++) {
            float x = radius * (float) Math.cos(twoPiDivided * i) + random(-AST_DISPERSION, AST_DISPERSION);
            float y = radius * (float) Math.sin(twoPiDivided * i) + random(-AST_DISPERSION, AST_DISPERSION);
            shape[i] = new Point(x, y);
        }
    }

    Asteroid(int splitsLeft, Point pos) {
        this.pos = pos;
        heading = random(3);
        speed = new Point(random(AST_MIN_SPEED, AST_MAX_SPEED),
                          random(AST_MIN_SPEED, AST_MAX_SPEED));
        radius = (splitsLeft + 1) * AST_RADIUS_PER_SPLIT;
        hp = AST_HP * splitsLeft + 1;

        this.splitsLeft = splitsLeft;
        shape = new Point[(int) (radius / 3)];
        float twoPiDivided = 2 * (float) Math.PI / shape.length;
        for (int i = 0; i < shape.length; i++) {
            float x = radius * (float) Math.cos(twoPiDivided * i) + random(-AST_DISPERSION, AST_DISPERSION);
            float y = radius * (float) Math.sin(twoPiDivided * i) + random(-AST_DISPERSION, AST_DISPERSION);
            shape[i] = new Point(x, y);
        }
    }

    boolean inHitbox(Point pt) {
        if (pos.dist(pt) < radius) return true;
        return false;
    }

    void move() {
        pos = pos.add(speed);
        if (pos.x > WIDTH) pos.x = 0;
        if (pos.x < 0) pos.x = WIDTH;
        if (pos.y > HEIGHT) pos.y = 0;
        if (pos.y < 0) pos.y = HEIGHT;
    }

    ArrayList<Asteroid> die() {
        ArrayList<Asteroid> ret = new ArrayList<Asteroid>();
        if (splitsLeft > 0) {
            ret.add(new Asteroid(splitsLeft - 1, pos.add(new Point(random(30), random(30)))));
            ret.add(new Asteroid(splitsLeft - 1, pos.add(new Point(random(30), random(30)))));
        }
        return ret;
    }

    void display() {
        stroke(255);
        fill(0);
        drawPoly(shape, 0, pos);
    }
}

class Spaceship {
    Point pos;
    float heading;
    float rotSpeed;
    float rotDir;
    float accel;
    Point speed;
    boolean shooting;

    Point[] shape;
    Point[] thrust1;
    Point[] thrust2;

    Spaceship() {
        pos = new Point(WIDTH / 2, HEIGHT / 2);
        speed = new Point(0, 0);
        rotDir = 0;
        heading = 0;
        rotSpeed = 0.05;
        accel = 0;
        shooting = false;

        shape = new Point[] {
            new Point(0, -20),
            new Point(-10, 10),
            new Point(10, 10)
        };
        thrust1 = new Point[] {
            new Point(-9, 10),
            new Point(-3, 20),
            new Point(0, 10),
            new Point(3, 20),
            new Point(9, 10)
        };
        thrust2 = new Point[] {
            new Point(-5, 10),
            new Point(0, 30),
            new Point(5, 10)
        };
    }

    Point accelVect() {
        return (new Point(0, -accel)).rot(heading);
    }

    void rot() {
        heading += rotDir * rotSpeed;
    }

    void move() {
        speed = speed.add(accelVect());
        pos = pos.add(speed);
        if (pos.x > WIDTH) pos.x = 0;
        if (pos.x < 0) pos.x = WIDTH;
        if (pos.y > HEIGHT) pos.y = 0;
        if (pos.y < 0) pos.y = HEIGHT;
    }

    void shoot() {
        if (shooting) {
            lasers.add(new Laser(shape[0].rot(heading).add(pos), heading));
        }
    }

    void display() {
        stroke(255);
        drawPoly(shape, heading, pos);
        if (accel > 0) {
            if (random(1) < 0.5) {
                drawPoly(thrust1, heading, pos);
            } else {
                drawPoly(thrust2, heading, pos);
            }
        }
    }
}

void drawPoly(Point[] poly, float rotAngle, Point center) {
    Point[] copy = new Point[poly.length];
    for (int i = 0; i < copy.length; i++) {
        copy[i] = poly[i].rot(rotAngle);
    }
    for (int i = 1; i < copy.length; i++) {
        line(copy[i - 1].x + center.x,
             copy[i - 1].y + center.y,
             copy[i].x + center.x,
             copy[i].y + center.y);
        if (i == copy.length - 1) {
            line(copy[i].x + center.x,
                 copy[i].y + center.y,
                 copy[0].x + center.x,
                 copy[0].y + center.y);
        }
    }
}

Spaceship plr;

ArrayList<Asteroid> asteroids;
int lastSpawn;

ArrayList<Laser> lasers;
int survived;
int intervalspawn;

void setup() {
    size(1300, 700);

    plr = new Spaceship();
    asteroids = new ArrayList<Asteroid>();
    lasers = new ArrayList<Laser>();
    survived = millis();
    intervalspawn = AST_SPAWNINTERVAL;
}

void draw() {
    background(0);

    int now = millis();
    if (now - lastSpawn > intervalspawn) {
        asteroids.add(new Asteroid((int) random(3)));
        lastSpawn = now;
        intervalspawn *= 0.999;
    }

    // Proccess and draw asteroids
    int i = 0;
    while (i < asteroids.size()) {
        Asteroid ast = asteroids.get(i);
        if (ast.hp <= 0) {
            ArrayList<Asteroid> children = ast.die();
            asteroids.remove(i);
            asteroids.addAll(children);
            continue;
        }
        if (ast.inHitbox(plr.pos)) {
            int score = millis() - survived;
            int minutes = round(score/1000/60);
            javax.swing.JOptionPane.showMessageDialog(null, "You survived " + minutes + " minutes!");
            setup();
            return;
        }
        ast.move();
        ast.display();
        i++;
    }

    // Process and draw lasers
    i = 0;
    outer: while (i < lasers.size()) {
        Laser las = lasers.get(i);
        las.move();
        las.display();
        if (las.outBorders()) {
            lasers.remove(i);
            continue;
        }
        int j = 0;
        while (j < asteroids.size()) {
            if (asteroids.get(j).inHitbox(las.pos)) {
                lasers.remove(i);
                asteroids.get(j).hp--;
                continue outer;
            }
            j++;
        }
        i++;
    }

    // Process and draw player
    plr.shoot();
    plr.rot();
    plr.move();
    plr.display();
}

void keyPressed() {
    if (key == 'a') {
        plr.rotDir = -1;
    }
    if (key == 'd') {
        plr.rotDir = 1;
    }
    if (key == 'w' && plr.accel < PLR_MAXACCEL) {
        plr.accel += 0.05;
    }
    if (key == 'x') {
        plr.shooting = true;
    }
}

void keyReleased() {
    if (key == 'a' || key == 'd') {
        plr.rotDir = 0;
    }
    if (key == 'w') {
        plr.accel = 0;
    }
    if (key == 'x') {
        plr.shooting = false;
    }
}