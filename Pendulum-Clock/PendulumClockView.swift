//MIT License
//
//Copyright (c) 2025 Cong Le
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  PendulumClockView.swift
//  MyApp
//
//  Created by Cong Le on 6/27/25.
//

import SwiftUI
import Combine

//
//  PendulumClockView.swift
//
//  This SwiftUI view provides an interactive simulation of a pendulum, a classic example of Simple Harmonic Motion (SHM).
//  It's designed to be both an educational tool and a demonstration of physics-based animation in SwiftUI.
//
//  Key Concepts Demonstrated:
//  - Simple Harmonic Motion (SHM): The pendulum's swing approximates SHM for small angles.
//  - Physics Equations: The simulation uses the angular acceleration formula `α ≈ -(g/L)θ` to drive the motion.
//  - Damped Harmonic Motion: A damping factor is included to simulate energy loss due to friction, making the simulation more realistic.
//  - Period of a Pendulum: The view dynamically calculates and displays the theoretical period `T ≈ 2π√(L/g)`.
//  - Interactive Controls: Users can adjust key physical parameters (length, gravity, damping) to observe their effects in real-time.
//  - SwiftUI Best Practices: The view uses a publisher-based `Timer` for the simulation loop, `@State` for managing the simulation's state,
//    and computed properties for clarity.
//

struct PendulumClockView: View {
    // MARK: - State Properties for Physics Simulation
    
    /// The current angle of the pendulum in radians. The core state variable for the pendulum's position.
    @State private var angle: Double = .pi / 4 // Start at a 45-degree angle
    
    /// The current angular velocity (ω) in radians per second. Determines how fast the pendulum is swinging.
    @State private var angularVelocity: Double = 0
    
    /// The current angular acceleration (α) in radians per second squared. Determines the rate of change of angular velocity.
    @State private var angularAcceleration: Double = 0
    
    /// A running total of the elapsed time for the simulation, used for display.
    @State private var elapsedTime: Double = 0.0

    // MARK: - User-Configurable Physical Constants
    
    /// The length of the pendulum rod (L) in meters. Directly affects the period.
    @State private var pendulumLength: Double = 100.0
    
    /// The acceleration due to gravity (g) in m/s². The driving force of the oscillation.
    /// Default is Earth's gravity. Try 1.62 for the Moon or 24.79 for Jupiter! 🪐
    @State private var gravity: Double = 9.81
    
    /// The damping factor, which simulates energy loss from friction and air resistance.
    /// A value of 0.0 represents an ideal, frictionless pendulum. Higher values cause it to stop faster.
    @State private var damping: Double = 0.1
    
    // MARK: - Simulation Timer
    
    /// The time step (dt) for our simulation loop. A smaller value increases accuracy but uses more CPU.
    /// A value of 1/60 corresponds to a 60 FPS update rate, ideal for smooth animation.
    private let timeStep = 1.0 / 60.0
    
    /// A publisher that fires every `timeStep` seconds to drive the physics simulation.
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    // MARK: - Computed Properties
    
    /// Calculates the theoretical period (T) of the pendulum based on its current length and gravity.
    /// The formula `T ≈ 2π√(L/g)` is accurate for small-angle oscillations.
    private var period: Double {
        // Avoid division by zero if gravity is set to 0.
        guard gravity > 0 else { return .infinity }
        return 2 * .pi * sqrt(pendulumLength / gravity)
    }
    
    /// Provides a formatted string for the current angle in degrees for display.
    private var angleInDegrees: String {
        String(format: "%.1f°", angle * 180 / .pi)
    }

    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Information Header
            Text("Pendulum Clock Simulation 🕰️")
                .font(.largeTitle).bold()
                .padding(.top)

            HStack(spacing: 20) {
                InfoView(label: "Elapsed Time", value: String(format: "%.2fs", elapsedTime))
                InfoView(label: "Current Angle", value: angleInDegrees)
                InfoView(label: "Period (T)", value: String(format: "%.2fs", period))
            }
            .padding(.horizontal)

            Spacer()
            
            // MARK: - Pendulum Visual
            ZStack(alignment: .top) {
                // The pendulum's rod and bob
                VStack(spacing: 0) {
                    Capsule() // Rod
                        .frame(width: 5, height: pendulumLength)
                        .foregroundColor(.gray)
                    Circle() // Bob
                        .frame(width: 40, height: 40)
                        //.foregroundColor(.blue.gradient)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                // The pivot point
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.black)
                    .offset(y: -7.5) // Center the pivot
            }
            .rotationEffect(.radians(angle), anchor: .top) // The magic! Rotates the view based on the angle state.
            .animation(.linear(duration: timeStep), value: angle) // Use linear animation for physics-driven updates.
            
            Spacer()

            // MARK: - Control Panel
            VStack(alignment: .leading, spacing: 15) {
                ControlSlider(label: "Length (L)", value: $pendulumLength, range: 20...200, unit: "m")
                ControlSlider(label: "Gravity (g)", value: $gravity, range: 1...25, unit: "m/s²")
                ControlSlider(label: "Damping", value: $damping, range: 0...1)
                
                Button(action: resetSimulation) {
                    Text("Reset Simulation")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onReceive(timer) { _ in
            updatePendulumState()
        }
    }
    
    // MARK: - Simulation Logic
    
    /// This function is the core of the physics engine. It's called for every tick of the timer.
    private func updatePendulumState() {
        // 1. Calculate Angular Acceleration (α)
        // This is the physics! The restoring force is proportional to sin(angle).
        // For small angles, sin(θ) ≈ θ, which gives us true SHM. Here we use the full sin(θ) for accuracy.
        // We also add the damping force, which is proportional to the angular velocity and opposes the motion.
        angularAcceleration = (-gravity / pendulumLength) * sin(angle) - damping * angularVelocity
        
        // 2. Update Angular Velocity (ω)
        // Integrate acceleration over the time step to get the new velocity.
        angularVelocity += angularAcceleration * timeStep
        
        // 3. Update Angle (θ)
        // Integrate velocity over the time step to get the new angle.
        angle += angularVelocity * timeStep
        
        // 4. Update Elapsed Time
        elapsedTime += timeStep
    }
    
    /// Resets all state variables to their initial values.
    private func resetSimulation() {
        angle = .pi / 4
        angularVelocity = 0
        angularAcceleration = 0
        elapsedTime = 0
    }
}

// MARK: - Helper Subviews

/// A reusable view for displaying a label and its value.
private struct InfoView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.title3, design: .monospaced).bold())
        }
        .frame(minWidth: 100)
    }
}

/// A reusable slider with a label and value display.
private struct ControlSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var unit: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value, specifier: "%.2f") \(unit)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

// MARK: - Preview Provider
struct PendulumClockView_Previews: PreviewProvider {
    static var previews: some View {
        PendulumClockView()
    }
}
