package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

NUM_BOIDS :: 100

WIDTH :: 2040
HEIGHT :: 1080

MAX_SPEED :: 5.0
SEP_WEIGHT :: 0.5
ALIGN_WEIGHT :: 1.0
COH_WEIGHT :: 0.2
PERCEPTION_RADIUS :: 25.0

Boid :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    acceleration: rl.Vector2,
}


main :: proc() {
    rl.InitWindow(WIDTH, HEIGHT, "Boids Simulation")
    rl.SetTargetFPS(60)
    
    flock := init_boids()
    
    for !rl.WindowShouldClose() {
        update_boids(flock)
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        draw_boids(flock)
        rl.EndDrawing()
    }
    
    rl.CloseWindow()
}

init_boids :: proc() -> []Boid {
    boids := new([NUM_BOIDS]Boid)
    
    for i in 0..<NUM_BOIDS {
        boids[i] = Boid{
            position = rl.Vector2{f32(rl.GetRandomValue(0, WIDTH)), f32(rl.GetRandomValue(0, HEIGHT))},
            velocity = rl.Vector2{f32(rl.GetRandomValue(-1, 1)), f32(rl.GetRandomValue(-1, 1))},
            acceleration = rl.Vector2{0, 0},
        }
    }
    
    return boids[:]
}

separation :: proc(boids: []Boid, boid: Boid) -> rl.Vector2 {
    perception_radius: f32 = 20.0

    steer := rl.Vector2{0, 0}
    total := 0
    
    for other in boids {
        if other != boid {
            distance := rl.Vector2Distance(boid.position, other.position)
            if distance < perception_radius && distance > 0 {
                diff := boid.position - other.position
                
                weight := (perception_radius - distance) / perception_radius
                weight *= weight
                
                diff = rl.Vector2Normalize(diff) * weight
                steer += diff
                total += 1
            }
        }
        
        if total > 0 {
            steer = steer * (1/f32(total))
            steer = rl.Vector2Normalize(steer)
            steer = steer * 0.8
        }
        
    }
    return steer
}

alignment :: proc(boids: []Boid, boid: Boid) -> rl.Vector2 {
    perception_radius: f32 = 50.0
    avg_velocity := rl.Vector2{0, 0}
    total := 0
    
    for other in boids {
        if other != boid {
            distance := rl.Vector2Distance(boid.position, other.position)
            if distance < perception_radius {
                avg_velocity = avg_velocity + other.velocity
                total += 1
            }
        }
    }
    
    if total > 0 {
        avg_velocity = avg_velocity * (1/f32(total))
        avg_velocity -= boid.velocity
        avg_velocity = rl.Vector2Normalize(avg_velocity) * 0.3
    }
    
    return avg_velocity
}

cohesion :: proc(boids: []Boid, boid: Boid) -> rl.Vector2 {
    perception_radius: f32 = 50.0
    center := rl.Vector2{0, 0}
    total := 0
    avg_distance: f32 = 0.0
    
    for other in boids {
        if other != boid {
            distance := rl.Vector2Distance(boid.position, other.position)
            if distance < perception_radius {
                center += other.position
                avg_distance += distance
                total += 1
            }
        }
    }
    
    if total > 0 {
        center = center * (1/f32(total))
        avg_distance = avg_distance / f32(total)
        steer := center - boid.position

        weight := 0.02 + (0.1 * (avg_distance / perception_radius))
        steer = rl.Vector2Normalize(steer) * weight
        
        return steer
    }
    
    return center 
}

draw_boids :: proc(boids: []Boid) {
    size: f32 = 8.0

    for boid, idx in boids {
        vel_normalized := rl.Vector2Normalize(boid.velocity)

        angle := math.atan2(vel_normalized.y, vel_normalized.x)

        front := rl.Vector2{
            boid.position.x + vel_normalized.x * size * 2, 
            boid.position.y + vel_normalized.y * size * 2
        }

        left := rl.Vector2{
            boid.position.x + math.cos(math.atan2(vel_normalized.y, vel_normalized.x) + 2.5) * size, 
            boid.position.y + math.sin(math.atan2(vel_normalized.y, vel_normalized.x) + 2.5) * size
        }

        right := rl.Vector2{
            boid.position.x + math.cos(math.atan2(vel_normalized.y, vel_normalized.x) - 2.5) * size, 
            boid.position.y + math.sin(math.atan2(vel_normalized.y, vel_normalized.x) - 2.5) * size
        }

        rl.DrawTriangleLines(front, left, right, rl.LIGHTGRAY)
    }
}

update_boids :: proc(boids: []Boid) {
    for i in 0..<NUM_BOIDS {
        boid := &boids[i]
        
        sep := separation(boids, boid^)
        align := alignment(boids, boid^)
        coh := cohesion(boids, boid^)
        
        boid.acceleration = (boid.acceleration * 0.7) + (sep * SEP_WEIGHT + align * ALIGN_WEIGHT + coh * COH_WEIGHT) * 0.3
        boid.velocity += boid.acceleration
        
        limit_speed(boid, MAX_SPEED)
        
        boid.position += boid.velocity
        
        if boid.position.x < -10 {
            boid.position.x = WIDTH + 10
        } else if boid.position.x > WIDTH + 10 {
            boid.position.x = -10
        }

        if boid.position.y < -10 {
            boid.position.y = HEIGHT + 10
        } else if boid.position.y > HEIGHT + 10 {
            boid.position.y = -10
        }

        boid.acceleration = boid.acceleration * 0.8
    }
}

limit_speed :: proc(boid: ^Boid, max_speed: f32) {
    speed := math.sqrt(boid.velocity.x * boid.velocity.x + boid.velocity.y * boid.velocity.y)
    
    if speed > max_speed {
        scale := max_speed / speed
        boid.velocity.x *= scale
        boid.velocity.y *= scale
    }
}
